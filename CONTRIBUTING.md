# Contributing

Bug reports, focused fixes, and documentation updates are welcome.

## Before opening an issue

- Check whether the issue has already been reported.
- Include the app version and macOS version.
- Describe the steps that reproduce the problem and what happened instead.
- Do not include private audio, logs containing personal information, or credentials.

## Pull requests

- Keep changes focused.
- Explain the user-visible effect and how you tested it.
- Run the build on macOS before submitting changes that affect Swift or the app bundle.
- Preserve the MacEQ copyright and MIT license notices in derived files.
- Do not add telemetry, audio recording, or upload behavior without a separate discussion and explicit user-facing consent.

## Development build

```bash
swift build -c debug
swift run maceq-tests
scripts/build-app.sh release
```

The app requires macOS 14.4 or later and cannot be fully built or tested on Linux.
