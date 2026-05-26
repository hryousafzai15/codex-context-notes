# Contributing

Thanks for considering a contribution to Codex Context Notes.

## Ground Rules

- Open an issue before large changes so the direction can be discussed.
- Keep pull requests focused and small enough to review.
- Include tests for behavior changes when practical.
- Do not commit build products, signed app bundles, screenshots, local logs, or
  private data.
- Do not add network services or telemetry without an explicit design discussion.

## Development Setup

```bash
swift test
./script/build_and_run.sh
```

The app requires macOS Accessibility permission for full Codex detection and
prompt insertion. Tests do not require Accessibility permission.

## Pull Request Checklist

- [ ] `swift test` passes.
- [ ] User-facing behavior is documented when it changes.
- [ ] The app version in `VERSION` is updated for meaningful product changes.
- [ ] No local build artifacts or private files are included.

## Branch Policy

The `main` branch is protected. Please use pull requests instead of direct
pushes to `main`.
