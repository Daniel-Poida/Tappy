# Tappy 1.1

A playful macOS pointer for presentations, demos and screen shares. Original vector artwork, a soft shadow and a light + dark double outline keep the pointer readable across backgrounds.

## The magic update

Exactly four characters, each with a unique synthesized sound:

| Character | Sound |
| --- | --- |
| Classic cartoon glove | Cartoon knock |
| Sailor Moon inspired wand | Moon chime |
| Princess Star inspired wand | Star sparkle |
| Wizard's magic wand | Magic swish |

Rapid clicks build energy: the glove squashes and rotates more, the impact burst grows, magical wands sparkle, and the sound becomes louder and slightly higher. Energy decays after a pause. The pointer tip stays anchored to the actual click position throughout the animation. System Reduce Motion is respected by the live pointer.

Settings include a clickable light/dark preview, personality intensity, size, shadow, animation, sound and master volume. Preferences persist between launches. Both the app icon and menu bar icon are drawn from the same glove geometry; the menu icon adapts to macOS light/dark appearance and indicates enabled, disabled and presentation states.

- `⌃⌥P`: enable / disable Tappy (also exits Presentation Mode).
- `⌃⌥T`: enable / exit Presentation Mode.
- Normal mode passes clicks and drags through to your apps.
- Presentation Mode blocks mouse buttons, dragging and scrolling while leaving the keyboard available. It requires **System Settings → Privacy & Security → Accessibility → Tappy**. It only reports enabled after a blocking event tap is installed.
- The pointer follows the mouse across displays and Spaces. Tappy restores the system pointer when disabled, quit or put to sleep.
- Share or record the **entire screen** to include the overlay; enable system audio sharing for sounds.

## Build

Requires macOS 13+, Swift 5.9+ and Xcode Command Line Tools.

```sh
swift build
swift run
```

Build a universal Apple Silicon + Intel application, regenerate the icons, and create the 1.1 installer:

```sh
./build-dmg.sh
```

Outputs `build/Tappy.app`, `build/Tappy-1.1.dmg` and its SHA-256 checksum. The local bundle and DMG are ad-hoc signed; distribution with Apple notarization requires a Developer ID certificate.

```sh
./test.sh
```

The tests cover click energy and decay, volume scaling, playable and unclipped distinct sound files, the exact four-character set, vector bounds and coordinates on displays left of and above the main screen.

## License

MIT
