# 📡 AirTag: Lost Signal

**A native iOS pixel-art adventure with Liquid Glass-inspired menus.** Play as TAG-01, a tiny fictional tracker separated from its human. Rescue missing signals, befriend ECHO, and uncover what silenced the network.

## Adventure
- **5 worlds / 30 story missions**: Neon City, Circuit Forest, Data Depths, Ghost Network and Core Zero.
- **Unlimited procedural missions** after the finale: each maze has a guaranteed path between the spawn and exit.
- **Retro combat**: chase-resistant movement, corrupted signal enemies, five guardians, sonar pulse, energy dash, shields and battery management.
- **Pickups and progression**: collect pings, energy batteries, repair kits, and purchase permanent upgrades with earned bits.
- **Automatic local saves** after each action, chapter selection, persistent unlocks and best-score tracking.
- **Liquid Glass** menus on iOS 26+, with a translucent material fallback on iOS 17–25.
- Offline single-player; **no real AirTag location access** and no location permission required.

## Controls
Swipe the game board or tap the directional pad to explore. Collect all glowing cyan pings and neutralize the boss (every sixth mission) to unlock the portal. Step into the green portal to finish. SONAR spends 30 energy to stun and damage enemies nearby; DASH spends 18 energy to travel up to three tiles in your last direction. Batteries refill energy, repair kits restore a heart. Earn bits for upgrades.

## Build locally (macOS)
1. Install Xcode and XcodeGen (e.g. via Homebrew).
2. Run:
   \`\`\`sh
   swift scripts/GenerateIcon.swift
   xcodegen generate --spec project.yml
   xcodebuild -project AirTagQuest.xcodeproj -scheme AirTagQuest -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
   \`\`\`
3. Open the generated Xcode project to run the app in an iPhone simulator. For installing on a physical iPhone, you must sign it with your own Apple development credentials.

## GitHub Actions and IPA
The workflow at \`.github/workflows/ios-ipa.yml\` builds for iOS Simulator, compiles an unsigned iOS-device app, creates \`AirTagQuest-unsigned.ipa\` and uploads it in the workflow's artifacts. The IPA is **unsigned**, so it must be signed by an appropriate sideloading/development tool before installation on a device. No certificates or Apple credentials are stored in the repository.

## Tech
SwiftUI + Canvas pixel rendering, Swift / Codable / UserDefaults, XcodeGen, GitHub Actions. Icon art is generated with native CoreGraphics. iOS 17+.

*AirTag is an Apple trademark. This is an independent fictional game and is not affiliated with or endorsed by Apple.*
