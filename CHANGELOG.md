# Changelog

## 1.4.2

- Redraw the Classic and Witch idle hands with consistent dorsal anatomy; add three-finger and middle-finger poses.
- Play the requested sequence: index → two → three → fist → middle → fist → index, once per configured idle interval.
- Use the middle finger for right-clicks, with a fist on both press and release. Keep short clicks, holding, rapid repeats and primary-click interruption coherent.
- Preserve right-button identity in the live overlay, presentation shields and preview. Anchor clicks to the active fingertip.
- Replace deformed finger meshes with sixteen complete painted cels per hand. Register the cuff and wrist using constant uniform transforms; retain visible fist pauses at 1.5× playback speed without global squash resizing.
- Add an animated preview and updated screenshots.

## 1.4.1

- Fix the system arrow appearing over Dock by temporarily registering a transparent system arrow while Tappy is active.
- Restore the original cursor images on disable and quit through a separate restore helper; pipe EOF also handles an unexpected parent exit. Recover a leftover restore journal on launch.
- Avoid repeated show/hide cycles when the transparent image is installed. Retain balanced Quartz hiding when registration is unavailable.
- Verify Dock behaviour and normal cursor restoration manually; test helper reuse, acknowledgements and parent-exit cleanup.

## 1.4

- Recover system cursor hiding over Dock and menus even when the visibility flag is stale: coalesced mouse-event refresh, movement polling and a bounded heartbeat, with one balanced hide request.
- Add a horror witch hand, Finn's silver sword with blue gem, and red and green lightsabers as a second four-character row.
- Keep four digits, native rendering, cuff alignment, light/dark readability and the original first-row characters.
- Add four distinct synthesized click sounds, style-specific impact colours, witch finger poses and independent sword/saber idle layers.
- Fit all eight cards and the preview into the existing settings window without scrolling; retain all sliders on the right.

## 1.3.4

- Draw the live cursor on one native AppKit surface and clear its complete transparent backing before every frame, preventing retained copies when size and other settings change.
- Use explicit click motion on that surface; glove, arm and shadow are rendered from one current settings snapshot.
- Allow only one active overlay per process and one running Tappy instance, including already running older versions.
- Test repeated settings changes against a fresh framebuffer, rapid tap interruption, complete clearing, and instance lock ownership.

## 1.3.3

- Render glove and forearm in one Canvas using the same animated phase and transform, removing the gap during clicks and spring rebound.
- Trim each sprite at the cuff and start the procedural arm inside it; remove the mismatched straight wrist segment from pointer rendering.
- Decode sprites once and draw them synchronously through CoreGraphics; remove the painted wrist from its opening while retaining the curved cuff.
- Apply the shadow to the joined silhouette. Align idle catching hands with the same cuff attachment.
- Verify actual rendered joint pixels through compression and overshoot, in addition to geometry checks.

## 1.3.2

- Keep the system cursor hidden when Tappy is active in the background.
- Restore cursor visibility after app, Space and display transitions without accumulating hide requests.
- Retry failed operations and balance cursor restoration on disable, cleanup and quit.

## 1.3.1

- Idle gestures play once per configured interval, with no internal loop. An interval of 30 seconds produces one animation at 30, 60, 90 seconds of inactivity.
- Preview plays the gesture once. Input resets the countdown.


## 1.3

- Exactly four fingers on every cartoon glove.
- Natural pointer angle based on screen position and movement.
- Saved forearm length control: minimum is the short arm, maximum reaches the screen bottom as in 1.1. Independent opacity and smooth fading.
- Native macOS window colors and title bar; Light, Dark and System appearance in Settings.
- Presentation Mode blocks mouse input on every display without repeated Accessibility permission dialogs. Keyboard focus and exit shortcuts remain available.
- Universal macOS application for Apple Silicon and Intel.

- Configurable idle finger play and wand juggling, cancelled by mouse or keyboard activity.
- Removed decorative glove-back stripes from the palms holding wands.
- Status menu dismisses when its icon is clicked again.

- Final settings layout has no scrolling: characters and preview on the left, sliders on the right.
- Idle delay defaults to one minute; wand flight takes 0.7 seconds, with a clean closed-grip catch.
- Character and Appearance submenus were removed from the tray menu.
