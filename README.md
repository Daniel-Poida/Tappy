# Tappy

A minimal macOS cursor highlighter inspired by [Pokey](https://pokeyapp.com/).

Turns your cursor into a big pointing hand that taps on every click, with a knock sound and a burst effect. The faster you click, the wilder the tap.

## Features

- Global pointing-hand cursor overlay
- Tap animation + sound on every click
- Burst intensity adapts to click speed
- Pointer mood slider (shy → in-your-face)
- Multiple pointer styles
- Menu bar toggle
- Global hotkey: `⌃⌥P`
- Preferences window

## Requirements

- macOS 13.0+
- Xcode Command Line Tools / Swift 5.9+

## Build

```bash
swift build -c release
```

## Run

```bash
swift run
```

The first time you run it, macOS will ask you to grant **Accessibility** access so the app can listen to global mouse events. Go to **System Settings → Privacy & Security → Accessibility** and enable Tappy.

## Create .app bundle

```bash
./build-app.sh
```

This produces `build/Tappy.app`, which you can open or move to `/Applications`.

## License

MIT
