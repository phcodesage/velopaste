# Validation

Validated on November 2, 2026 on an Apple Silicon Mac running macOS 27.0.1 with Xcode 27 / Swift 6.4 (Swift 5 language mode).

- `swift test`: 18 tests passed, zero failures.
- `./scripts/build.sh`: optimized native app built and ad-hoc signed.
- `codesign --verify --deep --strict`: packaged and installed apps valid.
- `plutil -lint Resources/Info.plist` and `bash -n scripts/build.sh scripts/install.sh`: passed.
- Live smoke test: captured two clipboard fixtures, opened the panel using global Option+V, navigated to the older entry with arrow keys carrying function/numeric-pad modifiers, and used Return to paste into a separate application's text view. The original system clipboard was restored afterward. The app session used no persistent history.
- Visually inspected generated light/dark panels, settings, emoji picker, and app icon. Preview screenshots use sample data.
- Installed to `~/Applications/Velopaste.app` and confirmed the process is running.

Declared minimum deployment target is macOS 13. Older macOS versions and Intel hardware have not been physically tested. The live paste test ran with Accessibility permission available; copy-only fallback is also covered by clipboard restoration tests. Login-item registration should be checked interactively on the destination Mac.
