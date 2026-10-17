# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-17

### Added

- An Omarchy shell overlay that asks which Chromium profile opens each link and
  new browser window.
- The `browser-picker` command, with a desktop entry that registers it as a web
  browser for `http`, `https` and HTML files.
- Choices read from Chromium's `Local State`, or from
  `~/.config/browser-picker/profiles.json` with your own labels, keys, icons
  and incognito choices.
- Keyboard and mouse control, with the highlight starting on the last choice.
- A fallback that opens the link in Chromium when the shell can't show the
  picker.
- `browser-picker --open`, `--private`, `--list` and `--version`.
- `make install`, `make uninstall` and `make check`, with `PREFIX` and
  `DESTDIR` support.
- An Arch package for the command and desktop entry.

[0.1.0]: https://github.com/kierangraham/browser-profile-picker/releases/tag/v0.1.0
