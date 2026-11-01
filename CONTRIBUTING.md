# Contributing to Velopaste

Build with `swift build`, run `swift test`, and package with `./scripts/build.sh` on a Mac with the Swift toolchain. Keep the app native and usable without network access or third-party runtime dependencies.

Describe the behavior being fixed and include relevant verification. For UI changes, inspect light and dark previews using the README's snapshot commands. Never put real clipboard content, Keychain secrets, or personal application data into a commit or issue. Use private NSPasteboard fixtures for tests.

Contributions are accepted under the project's MIT license.
