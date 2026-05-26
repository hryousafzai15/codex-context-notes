# Changelog

All notable changes to this project will be documented here.

## 0.4.5 - 2026-05-26

- Widened the notes panel and polished the footer controls so the note, todo, follow-up, and Insert into Codex actions stay readable.

## 0.4.4 - 2026-05-26

- Replaced the two-step Send to AI / Insert into Codex flow with one Insert into Codex action.

## 0.4.3 - 2026-05-26

- Removed artificial startup waits from panel launch paths.
- Reduced active Codex chat detection work when a matching Codex session is already available.

## 0.4.2 - 2026-05-26

- Moved Settings into the notes panel so it opens with the same glass design instead of a separate pop-up.

## 0.4.1 - 2026-05-26

- Changed the configured global shortcut to toggle the notes panel open and closed.

## 0.4.0 - 2026-05-26

- Added configurable global shortcut recording in Settings.
- Added a settings button to the notes panel header.
- Removed the hardcoded shortcut label from the panel.
- Added a loading state while Codex context detection refreshes.

## 0.3.0 - 2026-05-26

- Added compact command-palette notes panel.
- Added private notes, todos, and follow-ups per Codex context.
- Added per-item selection for todos and follow-ups before sending to Codex.
- Added review-before-send flow.
- Added stable local signing support for Accessibility trust during rebuilds.
- Added active Codex chat/project detection through Accessibility.
- Added local persistence in Application Support.
- Added build/run script for SwiftPM macOS app bundling.
