#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build/ModuleCache
swiftc -parse-as-library -module-cache-path "$PWD/.build/ModuleCache" \
    Sources/Settings.swift Sources/CursorState.swift Sources/PointerArtwork.swift \
    Sources/SoundManager.swift Sources/CursorView.swift Sources/CursorOverlayWindow.swift \
    Tests/TappyTests/TappyTests.swift -o .build/TappyChecks
.build/TappyChecks
