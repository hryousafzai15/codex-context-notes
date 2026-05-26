import AppKit
import ApplicationServices
import Foundation

struct CodexActiveWindowHints: Equatable {
    var chatTitle: String
    var projectName: String?
}

final class CodexAccessibilityContextReader {
    private let messagingTimeout: Float = 0.08
    private let nodeBudget = 700
    private let maxDepth = 22

    func activeWindowHints(for pid: pid_t) -> CodexActiveWindowHints? {
        guard AXIsProcessTrusted() else {
            requestAccessibilityPermission()
            AppLogger.write("accessibility context unavailable: permission not trusted")
            return nil
        }

        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, messagingTimeout)
        guard let window = focusedWindow(in: appElement) else {
            AppLogger.write("accessibility context unavailable: no focused Codex window")
            return nil
        }
        AXUIElementSetMessagingTimeout(window, messagingTimeout)

        var textNodes: [AXTextNode] = []
        collectTextNodes(in: window, into: &textNodes, remaining: nodeBudget, depth: 0)

        guard let chatTitle = activeHeaderTitle(from: textNodes) else {
            AppLogger.write("accessibility context unavailable: no active header title")
            return nil
        }

        let projectName = projectName(containing: chatTitle, in: window)
        AppLogger.write("accessibility context active chat \(chatTitle)")
        return CodexActiveWindowHints(chatTitle: chatTitle, projectName: projectName)
    }

    func projectName(containing chatTitle: String, for pid: pid_t) -> String? {
        guard AXIsProcessTrusted() else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, messagingTimeout)
        guard let window = focusedWindow(in: appElement) else {
            return nil
        }
        AXUIElementSetMessagingTimeout(window, messagingTimeout)
        return projectName(containing: chatTitle, in: window)
    }

    func requestAccessibilityPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private func focusedWindow(in appElement: AXUIElement) -> AXUIElement? {
        var focused: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focused) == .success,
           let focused {
            return unsafeDowncast(focused, to: AXUIElement.self)
        }

        var windowsValue: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue) == .success,
           let windows = windowsValue as? [AXUIElement] {
            return windows.first
        }

        return nil
    }

    private func activeHeaderTitle(from nodes: [AXTextNode]) -> String? {
        nodes
            .filter { node in
                node.role == "AXStaticText" &&
                    node.frame.minX >= 300 &&
                    node.frame.minY <= 80 &&
                    node.frame.height >= 10 &&
                    !ignoredHeaderLabels.contains(node.label)
            }
            .sorted { lhs, rhs in
                if lhs.frame.minY == rhs.frame.minY {
                    return lhs.frame.minX < rhs.frame.minX
                }
                return lhs.frame.minY < rhs.frame.minY
            }
            .first?
            .label
    }

    private var ignoredHeaderLabels: Set<String> {
        ["Connected", "Working", "Thinking", "Paused goal"]
    }

    private func projectName(containing chatTitle: String, in root: AXUIElement) -> String? {
        var best: ProjectGroupMatch?
        findProjectGroup(containing: chatTitle, in: root, best: &best, remaining: nodeBudget, depth: 0)
        return best?.projectName
    }

    private func findProjectGroup(
        containing chatTitle: String,
        in element: AXUIElement,
        best: inout ProjectGroupMatch?,
        remaining: Int,
        depth: Int
    ) {
        guard remaining > 0, depth <= maxDepth else {
            return
        }

        let frame = frame(of: element)
        let label = accessibilityLabel(for: element)
        let role = stringAttribute(kAXRoleAttribute, for: element) ?? ""

        if role == "AXGroup",
           let frame,
           frame.minX < 305,
           frame.width >= 220,
           frame.height >= 30,
           let label,
           isProjectGroupLabel(label),
           subtreeContains(chatTitle, in: element, remaining: 90, depth: 0) {
            let match = ProjectGroupMatch(projectName: label, area: frame.width * frame.height)
            if best == nil || match.area < best!.area {
                best = match
            }
        }

        var childBudget = remaining - 1
        for child in children(of: element) {
            findProjectGroup(containing: chatTitle, in: child, best: &best, remaining: childBudget, depth: depth + 1)
            childBudget -= 1
            if childBudget <= 0 {
                break
            }
        }
    }

    private func subtreeContains(_ text: String, in element: AXUIElement, remaining: Int, depth: Int) -> Bool {
        guard remaining > 0, depth <= 12 else {
            return false
        }

        if accessibilityLabel(for: element) == text {
            return true
        }

        var childBudget = remaining - 1
        for child in children(of: element) {
            if subtreeContains(text, in: child, remaining: childBudget, depth: depth + 1) {
                return true
            }
            childBudget -= 1
            if childBudget <= 0 {
                break
            }
        }

        return false
    }

    private func isProjectGroupLabel(_ label: String) -> Bool {
        !label.isEmpty &&
            label != "Automation folders" &&
            label != "Projects" &&
            !label.hasPrefix("Pin chat") &&
            !label.hasPrefix("Project actions") &&
            !label.hasPrefix("Start new chat")
    }

    private func collectTextNodes(in element: AXUIElement, into nodes: inout [AXTextNode], remaining: Int, depth: Int) {
        guard remaining > 0, depth <= maxDepth else {
            return
        }

        let role = stringAttribute(kAXRoleAttribute, for: element) ?? ""
        if let label = accessibilityLabel(for: element),
           let frame = frame(of: element),
           frame.width > 0,
           frame.height > 0 {
            nodes.append(AXTextNode(label: label, role: role, frame: frame))
        }

        var childBudget = remaining - 1
        for child in children(of: element) {
            collectTextNodes(in: child, into: &nodes, remaining: childBudget, depth: depth + 1)
            childBudget -= 1
            if childBudget <= 0 {
                break
            }
        }
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        if let children = arrayAttribute(kAXChildrenAttribute, for: element), !children.isEmpty {
            return children
        }
        return arrayAttribute("AXVisibleChildren", for: element) ?? []
    }

    private func accessibilityLabel(for element: AXUIElement) -> String? {
        [
            stringAttribute(kAXTitleAttribute, for: element),
            stringAttribute(kAXValueAttribute, for: element),
            stringAttribute(kAXDescriptionAttribute, for: element)
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first { !$0.isEmpty }
    }

    private func stringAttribute(_ attribute: String, for element: AXUIElement) -> String? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value else {
            return nil
        }
        return String(describing: value)
    }

    private func arrayAttribute(_ attribute: String, for element: AXUIElement) -> [AXUIElement]? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value as? [AXUIElement]
    }

    private func frame(of element: AXUIElement) -> CGRect? {
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionValue,
              let sizeValue else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &position),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }
}

private struct AXTextNode {
    var label: String
    var role: String
    var frame: CGRect
}

private struct ProjectGroupMatch {
    var projectName: String
    var area: CGFloat
}
