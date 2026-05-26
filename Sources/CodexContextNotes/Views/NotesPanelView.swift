import AppKit
import SwiftUI

struct NotesPanelView: View {
    @ObservedObject var model: NotesPanelModel
    @State private var activeSection: PanelSection = .none

    var body: some View {
        ZStack {
            if model.isShowingSettings {
                PanelSettingsView {
                    model.hideSettings()
                }
            } else {
                commandPalette
            }
        }
        .frame(minWidth: 470, idealWidth: 470, maxWidth: .infinity, minHeight: 530, idealHeight: 530, maxHeight: .infinity)
        .background(GlassPanelBackground())
        .foregroundStyle(.white)
        .tint(.blue)
        .onChange(of: model.note.body) { _, _ in
            model.save()
        }
    }

    private var commandPalette: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 10) {
                    if model.isLoadingContext {
                        loadingState
                    } else if activeSection == .none && !model.hasExistingContent {
                        emptyStartRow
                    } else if activeSection == .note {
                        expandedNote
                    } else {
                        collapsedRow(
                            section: .note,
                            systemImage: "lock",
                            title: "Private note",
                            detail: noteDetail
                        )
                    }

                    if activeSection == .todos {
                        expandedTodos
                    } else {
                        collapsedRow(
                            section: .todos,
                            systemImage: "list.bullet",
                            title: "Todos",
                            count: model.openTodoCount
                        )
                    }

                    if activeSection == .followUps {
                        expandedFollowUps
                    } else {
                        collapsedRow(
                            section: .followUps,
                            systemImage: "calendar",
                            title: "Follow-ups",
                            count: model.note.reminders.count
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 14)
            }
            .scrollIndicators(.hidden)

            footer
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.72))

                        Text(model.isLoadingContext ? "Detecting Codex context" : "Auto-detected from \(model.note.context.sourceAppName)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.56))
                            .lineLimit(1)
                    }

                    Text(model.isLoadingContext ? "Loading current context" : model.note.context.displayTitle)
                        .font(.system(size: 23, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    Text(model.isLoadingContext ? "Preparing notes for the active Codex chat..." : model.note.context.displaySubtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 8)

                Button {
                    model.showSettings()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.08), in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 36)
        .padding(.bottom, 10)
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Finding the active Codex chat")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                    Text("Your notes will appear as soon as the context is ready.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.46))
                }

                Spacer()
            }
            .padding(14)
            .paletteSurface(cornerRadius: 12)

            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(Color.white.opacity(0.035))
                    .frame(height: 42)
                    .redacted(reason: .placeholder)
            }
        }
    }

    private var emptyStartRow: some View {
        Button {
            activeSection = .note
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.square")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .frame(width: 18, height: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text("No notes for this context yet.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))

                    Text("Start with a note, todo, or follow-up.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.46))
                }

                Spacer()
            }
            .padding(14)
            .paletteSurface(cornerRadius: 12)
        }
        .buttonStyle(.plain)
    }

    private var expandedNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                systemImage: "lock",
                title: "Private note",
                detail: "\(model.note.body.count) / 5000",
                section: .note,
                isExpanded: true
            )

            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.note.body)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(height: 116)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.20))
                    }

                if model.note.body.isEmpty {
                    Text("Write the private context you want attached to this Codex context.\nIt is not shared until you insert it.")
                        .font(.caption)
                        .lineSpacing(3)
                        .foregroundStyle(.white.opacity(0.38))
                        .padding(17)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.blue.opacity(0.80), lineWidth: 1.2)
            }
        }
        .padding(12)
        .paletteSurface(cornerRadius: 12)
    }

    private var expandedTodos: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(
                systemImage: "list.bullet",
                title: "Todos",
                detail: nil,
                count: model.openTodoCount,
                section: .todos,
                isExpanded: true
            )

            HStack(spacing: 0) {
                TextField("Add a todo", text: $model.newTodoText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .onSubmit { model.addTodo() }
                    .padding(.horizontal, 10)
                    .frame(height: 38)

                Button {
                    model.addTodo()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .help("Add todo")
            }
            .background(Color.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }

            VStack(spacing: 6) {
                ForEach(model.note.todos) { todo in
                    TodoRow(
                        todo: todo,
                        isSelectedForHandoff: model.selectedTodoIDs.contains(todo.id)
                    ) {
                        model.toggleTodo(todo)
                    } onToggleSelected: {
                        model.toggleTodoSelection(todo)
                    } onDelete: {
                        model.deleteTodo(todo)
                    }
                }

                if model.note.todos.isEmpty {
                    EmptyRow(systemImage: "circle", text: "No todos yet.")
                }
            }
        }
        .padding(12)
        .paletteSurface(cornerRadius: 12)
    }

    private var expandedFollowUps: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(
                systemImage: "calendar",
                title: "Follow-ups",
                detail: nil,
                count: model.note.reminders.count,
                section: .followUps,
                isExpanded: true
            )

            HStack(spacing: 6) {
                TextField("Add a follow-up", text: $model.newReminderText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .onSubmit { model.addReminder() }
                    .padding(.horizontal, 10)
                    .frame(height: 38)

                TextField("When", text: $model.newReminderDueText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .onSubmit { model.addReminder() }
                    .padding(.horizontal, 8)
                    .frame(width: 74, height: 38)

                Button {
                    model.addReminder()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .help("Add follow-up")
            }
            .background(Color.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }

            VStack(spacing: 6) {
                ForEach(model.note.reminders) { reminder in
                    FollowUpRow(
                        reminder: reminder,
                        isSelectedForHandoff: model.selectedReminderIDs.contains(reminder.id)
                    ) {
                        model.toggleReminderSelection(reminder)
                    } onDelete: {
                        model.deleteReminder(reminder)
                    }
                }

                if model.note.reminders.isEmpty {
                    EmptyRow(systemImage: "circle", text: "No follow-ups yet.")
                }
            }
        }
        .padding(12)
        .paletteSurface(cornerRadius: 12)
    }

    private func collapsedRow(
        section: PanelSection,
        systemImage: String,
        title: String,
        detail: String? = nil,
        count: Int? = nil
    ) -> some View {
        Button {
            activeSection = section
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(width: 16)

                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.90))

                Spacer()

                if let detail {
                    Text(detail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.44))
                        .lineLimit(1)
                }

                if let count {
                    Text("\(count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Color.white.opacity(0.10), in: Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .paletteSurface(cornerRadius: 11)
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(
        systemImage: String,
        title: String,
        detail: String?,
        count: Int? = nil,
        section: PanelSection,
        isExpanded: Bool
    ) -> some View {
        Button {
            activeSection = isExpanded ? .none : section
        } label: {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(width: 15)

                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                if let detail {
                    Text(detail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.48))
                }

                if let count {
                    Text("\(count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.76))
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Color.white.opacity(0.12), in: Capsule())
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.44))
            }
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack(spacing: 7) {
            FooterChip(title: "Note", systemImage: "note.text", width: 74, isOn: model.includeNote) {
                model.includeNote.toggle()
                activeSection = .note
            }

            FooterChip(title: "Todos", systemImage: "list.bullet", width: 84, isOn: model.includeTodos) {
                model.includeTodos.toggle()
                activeSection = .todos
            }

            FooterChip(title: "Follow-ups", systemImage: "calendar", width: 112, isOn: model.includeReminders) {
                model.includeReminders.toggle()
                activeSection = .followUps
            }

            Spacer(minLength: 4)

            InsertActionButton {
                model.insertIntoCodex()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    private var noteDetail: String {
        model.note.body.isEmpty ? "0 / 5000" : "\(model.note.body.count) / 5000"
    }
}

private enum PanelSection {
    case none
    case note
    case todos
    case followUps
}

private struct FooterChip: View {
    var title: String
    var systemImage: String
    var width: CGFloat
    var isOn: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: isOn ? "checkmark.circle.fill" : systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isOn ? .blue : .white.opacity(0.70))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(isOn ? 0.92 : 0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
            }
            .frame(width: width, height: 32)
            .background(isOn ? Color.white.opacity(0.15) : Color.white.opacity(0.07), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(isOn ? 0.17 : 0.09), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct InsertActionButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.white.opacity(0.16), in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                    }

                Text("Insert into Codex")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
            }
            .frame(width: 136, height: 32)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Color.blue.opacity(0.20))
                    .clipShape(Capsule())
            }
            .overlay {
                Capsule()
                    .strokeBorder(Color.blue.opacity(0.44), lineWidth: 1)
            }
            .shadow(color: .blue.opacity(0.22), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .help("Insert selected notes into Codex")
    }
}

private struct TodoRow: View {
    var todo: NoteTodo
    var isSelectedForHandoff: Bool
    var onToggle: () -> Void
    var onToggleSelected: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Button(action: onToggleSelected) {
                Image(systemName: isSelectedForHandoff ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelectedForHandoff ? .blue : .white.opacity(0.48))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(isSelectedForHandoff ? "Included in Insert into Codex" : "Include in Insert into Codex")

            Button(action: onToggle) {
                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(todo.isDone ? .green : .white.opacity(0.56))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(todo.isDone ? "Mark open" : "Mark done")

            Text(todo.text)
                .font(.caption)
                .lineSpacing(2)
                .foregroundStyle(todo.isDone ? .white.opacity(0.42) : .white.opacity(0.84))
                .strikethrough(todo.isDone)
                .lineLimit(2)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.42))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Delete todo")
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 3)
    }
}

private struct FollowUpRow: View {
    var reminder: NoteReminder
    var isSelectedForHandoff: Bool
    var onToggleSelected: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Button(action: onToggleSelected) {
                Image(systemName: isSelectedForHandoff ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelectedForHandoff ? .blue : .white.opacity(0.48))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(isSelectedForHandoff ? "Included in Insert into Codex" : "Include in Insert into Codex")

            Text(reminder.text)
                .font(.caption)
                .lineSpacing(2)
                .foregroundStyle(.white.opacity(0.84))
                .lineLimit(2)

            Spacer()

            Text(reminder.dueText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.blue)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .frame(height: 24)
                .background(Color.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.42))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Delete follow-up")
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 3)
    }
}

private struct EmptyRow: View {
    var systemImage: String
    var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(text)
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.36))
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private extension View {
    func paletteSurface(cornerRadius: CGFloat) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(Color.white.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.13), lineWidth: 1)
            }
    }
}
