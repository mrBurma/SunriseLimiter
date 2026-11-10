# Sunrise Limiter

Sunrise Limiter is a free, open-source, menu-bar utility for macOS. It limits sudden peaks in system audio, such as game effects and action scenes, while leaving audio below the selected ceiling unchanged.

## Download

Download the latest `Sunrise-Limiter-macOS-universal.zip` from [GitHub Releases](https://github.com/mrBurma/SunriseLimiter/releases/latest). Unzip it and move `Sunrise Limiter.app` to `/Applications`.

The first launch requires permission to capture system audio. Open **System Settings → Privacy & Security → Screen & System Audio Recording** (the exact label can vary by macOS version) and allow Sunrise Limiter.

Releases that are not signed and notarized with an Apple Developer ID may be blocked by Gatekeeper. For an unsigned build, Control-click the app in Finder, choose **Open**, then confirm. This bypass should only be used when the archive came from the project's GitHub Releases page and its checksum matches the published checksum.

## Features

- Runs in the menu bar without a Dock icon or main window.
- Applies a stereo-linked peak limiter to system audio.
- Provides an adjustable output ceiling in dBFS.
- Displays current and maximum gain reduction and input/output peak levels.
- Can launch at login.
- Processes audio locally. It does not record, save, or transmit audio.

## How the limiter works

The limiter uses instantaneous sample-peak detection with an immediate attack and a smoothed release. It operates on digital sample peaks (dBFS), not calibrated acoustic sound pressure. It is not a loudness normalizer. Audio below the selected ceiling is left unchanged.

This version does not use look-ahead buffering or true-peak oversampling. Inter-sample peaks may therefore exceed the selected sample-peak ceiling.

## Requirements

- macOS 14.4 or later.
- Apple Silicon or Intel Mac.
- System-audio capture permission.

## Build from source

Install Xcode or the Xcode Command Line Tools, then run:

```bash
scripts/build-app.sh release
open "build/Sunrise Limiter.app"
```

The build script creates a universal arm64/x86_64 application bundle. A local ad-hoc build may cause macOS to request audio-capture permission again after rebuilding. Public releases should be signed with a Developer ID and notarized before distribution.

## Updates and network access

On first launch, the app asks whether it may check for updates automatically. If enabled, it checks the project's public GitHub Releases endpoint about once every 24 hours. It does not download or install updates in the background. When a newer release is found, the app offers a link to the release page.

GitHub receives the normal connection metadata associated with an HTTPS request and the app version in the User-Agent header. No audio, device name, account identifier, or personal files are sent by the app.

You can also check manually from the app's menu. Disable automatic checks there to stop scheduled requests.

## Source and attribution

Sunrise Limiter is an independent derivative of [MacEQ](https://github.com/jatinindia/MacEQ) by Jatin Grewal. It reuses parts of MacEQ's Core Audio Process Tap engine, audio lifecycle handling, and supporting code. The equalizer interface and unrelated processing features are not part of Sunrise Limiter's user interface.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [LICENSE](LICENSE) for licensing details.

## Bug reports

Report reproducible bugs through [GitHub Issues](https://github.com/mrBurma/SunriseLimiter/issues). Include your macOS version, Mac model (Apple Silicon or Intel), app version, and steps to reproduce. Do not attach audio recordings unless they contain no private material and you intend to share them publicly.

## License

MIT. See [LICENSE](LICENSE).
