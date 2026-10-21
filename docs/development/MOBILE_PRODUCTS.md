# Mobile test products — 21 October 2026

The user authorized publishing the current iOS and Android products and removing project-specific local installations after verifying GitHub preservation. The repository stays public and active. The desktop campaign remains accepted at 24 levels; these packages add no physical-device or mobile-performance acceptance.

Download the [mobile test release](https://github.com/LemmaLemming/cinder-gesture-lab/releases/tag/mobile-test-2026-10-21). The Android APK is debug-signed for direct sideload testing, with ARM64/ARMv7, Android 7/API24 minimum and API36 target. It is not a store release.

The iPhone download is an **unsigned arm64 IPA**, requiring signing and provisioning before installation. It retains the native executable from the existing local Xcode device build and replaces the game PCK with the clean final export. Private provisioning profiles and signatures are excluded. The accompanying **complete Xcode project ZIP** includes the engine frameworks. Extract it, open `Cinder.xcodeproj`, select your Apple developer team and physical iPhone, then build/run. No private certificate or key is distributed. A signed IPA and successful physical-device launch are not asserted.

Both targets use Godot 4.7.2 stable, the shared opaque app icon, ETC2/ASTC texture imports and runtime-only data filters. All 24 registered scenes and 17 runtime JSON files are checked against source. Development tests, evidence, authoring ledgers and the unpromoted codec draft are excluded. Godot's iOS exporter leaves20 zero-byte app-icon/splash catalogue placeholders in the PCK; these documented packaging extras contain no generated asset bytes.

The release includes checksums, build metadata, content verification and [Godot/MoltenVK notices](../licenses/GODOT_LICENSE.txt). Signature, alignment, ZIP CRC and PCK MD5 checks are packaging checks. Physical Android/iPhone play, mobile timing/performance, complete routes and store submission remain unverified or unperformed. Original failed/canceled/unexecuted desktop evidence keeps its original scope.

Source exports are reproducible from `export_presets.cfg` with matching official templates. Supply a Godot executable using `CINDER_GODOT` or the local setup; all Godot jobs use the repository queue:

```sh
python3 scripts/dev/dev.py engine --headless --path . --export-debug Android exports/android/Cinder-debug.apk
python3 scripts/dev/dev.py engine --headless --path . --export-debug iOS exports/ios/Cinder.ipa
```

Create the output directories first. The iOS preset deliberately exports the Xcode project only. Configure local Android SDK/JDK paths in Godot; the repository contains no SDK, signing credentials or developer toolchain. Reinstall the engine/templates if local cleanup has removed them. The app icon is temporary test branding.

[Local cleanup record](LOCAL_CLEANUP.md) describes what was removed and retained. Unfinished branches and drafts are separate development history, not additional accepted content.
