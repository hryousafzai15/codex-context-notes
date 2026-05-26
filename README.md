# Codex Context Notes

Codex Context Notes is a lightweight native macOS companion for keeping private
notes, todos, and follow-ups attached to the Codex chat or project you are
working in.

Notes stay local until you explicitly choose **Send to AI**. The app is designed
for people who want a memory layer beside Codex without automatically adding
private thoughts to every prompt.

> This project is independent and is not affiliated with OpenAI.

## Features

- Open a compact notes palette with a configurable global shortcut.
- Auto-detect the active Codex chat/project when Accessibility permission is
  enabled.
- Save private notes, todos, and follow-ups per Codex context.
- Choose exactly which todos and follow-ups are included before sending.
- Review what will be inserted before it goes into the Codex composer.
- Store all notes locally in Application Support.
- Keep a stable signed app identity during local development so macOS
  Accessibility trust is not reset on every rebuild.

## Requirements

- macOS 14 or newer
- Xcode command line tools with Swift 6 support
- Codex desktop app
- Accessibility permission for active-chat detection and composer insertion

## Quick Start

Clone the repository and run the app:

```bash
git clone https://github.com/hryousafzai15/codex-context-notes.git
cd codex-context-notes
./script/build_and_run.sh
```

Open the panel directly during development:

```bash
./script/build_and_run.sh panel
```

Run tests:

```bash
swift test
```

## Using the App

1. Start Codex Context Notes.
2. Open the Codex desktop app.
3. Press the configured shortcut. The default is `Control` + `Option` + `N`.
4. Add a note, todo, or follow-up.
5. Select the exact items you want to include.
6. Press **Send to AI** and review the handoff.

The app does not send anything automatically. It prepares text and inserts it
into the Codex composer only when you ask it to.

## Permissions

macOS requires Accessibility permission for two things:

- Reading the active Codex window so notes can be attached to the right context.
- Inserting selected notes into the Codex composer.

Enable it in:

```text
System Settings > Privacy & Security > Accessibility
```

If you build locally with the provided script and have a signing identity, the
bundle id and signing requirement remain stable across rebuilds.

## Privacy

Notes are stored locally at:

```text
~/Library/Application Support/CodexContextNotes
```

The app does not run a backend service and does not upload notes anywhere.

## Development

The main development entry point is:

```bash
./script/build_and_run.sh
```

Useful modes:

```bash
./script/build_and_run.sh panel
./script/build_and_run.sh shortcut-test
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
```

The app version is stored in `VERSION`. Each build also gets a timestamp
`CFBundleVersion`.

The global shortcut is configurable in Settings. Open Settings from the menu bar
app or the gear button in the panel.

### Signing

The run script signs the app after bundling:

- `CODEX_CONTEXT_NOTES_CODESIGN_IDENTITY` overrides the signing identity.
- `CODEX_CONTEXT_NOTES_BUNDLE_ID` overrides the bundle id.
- If no signing identity is found, the script falls back to ad-hoc signing.

For public releases, use a Developer ID certificate and Apple notarization.
The local development script is not a full release pipeline.

## Project Structure

```text
Sources/CodexContextNotes/App       App lifecycle and panel controller
Sources/CodexContextNotes/Views     SwiftUI panel and settings UI
Sources/CodexContextNotes/Services  Codex detection, hotkey, and prompt insert
Sources/CodexContextNotes/Stores    Local note persistence
Sources/CodexContextNotes/Support   Formatting, logging, and visual helpers
Tests/CodexContextNotesTests        Unit tests
script/build_and_run.sh             Build, sign, bundle, and launch helper
```

## Contributing

Issues and pull requests are welcome. Please read `CONTRIBUTING.md` first.

The `main` branch is protected. Changes should go through pull requests with
review and passing CI.

## License

MIT. See `LICENSE`.
