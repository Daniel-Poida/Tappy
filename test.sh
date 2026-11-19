#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build/ModuleCache
swiftc -parse-as-library -module-cache-path "$PWD/.build/ModuleCache" \
    Sources/FingerCelArtwork.swift Sources/IdleAnimation.swift Sources/Appearance.swift Sources/Settings.swift Sources/CursorState.swift Sources/PointerArtwork.swift \
    Sources/SoundManager.swift Sources/CursorView.swift Sources/CursorOverlayView.swift Sources/SingleInstance.swift Sources/SystemArrowGuard.swift Sources/SystemCursorController.swift Sources/PresentationShield.swift Sources/CursorOverlayWindow.swift \
    Tests/TappyTests/TappyTests.swift -o .build/TappyChecks
.build/TappyChecks
