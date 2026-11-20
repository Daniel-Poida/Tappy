# System cursor ownership

Tappy hides the system cursor through one balanced Quartz hide request and
allows background cursor control on its own WindowServer connection.

Dock can force its arrow visible while Quartz still reports the cursor hidden.
Repeated hide calls and a transparent `NSCursor` on Tappy's own connection did
not solve that behaviour during testing. The 1.4.1 implementation temporarily
registers a transparent `com.apple.coregraphics.Arrow` image system-wide.
This affects the running session; it does not edit system resources or cursor
preferences. Other cursor shapes retain their normal images.

`TappyCursorGuard` owns the original arrow images and metadata. It writes a
private restore journal before installing the transparent image, then waits on
a pipe held only by Tappy. Disabling Tappy, quitting, or losing the parent process
closes that pipe. The helper restores the original images and acknowledges the
restore. A journal left by a killed helper is recovered on the next launch.
One helper holds the restore lock; repeated activation reuses it. Missing APIs
or failed registration fall back to balanced Quartz hiding.

The helper is universal, signed with the app, and lives in `Contents/Helpers`.
It has no UI, input monitoring, accessibility permission or startup registration.

The dynamically resolved cursor registration and copy signatures follow
[Mousecape's CGSCursor.h](https://github.com/alexzielenski/Mousecape/blob/master/Mousecape/mousecloak/CGSInternal/CGSCursor.h).
These are optional private interfaces, resolved at runtime. The supported public
cursor API remains available if the symbols are absent.

Validation includes cursor hide/show balancing, forced-show simulation, original
image restore ownership, helper acknowledgement, reuse and cleanup, and pipe EOF
when the parent exits without running destructors. The Dock behaviour and normal
system cursor restoration were confirmed manually by the user on November 19,
2026. Headless tests do not establish visual behaviour over Dock.


## Capture cursor image (1.4.3 preview)

WebRTC's [macOS cursor monitor](https://webrtc.googlesource.com/src/+/refs/heads/main/modules/desktop_capture/mouse_cursor_monitor_mac.mm)
reads `NSCursor.currentSystemCursor.image` and composites that image separately;
its image capture path does not consult the Quartz visibility flag. A missing
image leaves the previous shape cached. The installed Telemost binaries include
this monitor, which makes this a likely explanation for the receiver-only arrow.

Tappy now publishes a real 16×16 RGBA cursor whose pixels all have zero alpha,
using the existing background cursor connection. Mouse/context changes reapply
that cursor; a five-Hz stationary heartbeat repairs delayed cursor changes.
The original current cursor is saved before arrow registration and restored
after the guarded arrow image on disable and normal quit. The Dock guard and
balanced Quartz ownership are retained. No capture or Accessibility permission
is requested, and no recording or conference is started by Tappy.

Tests cover RGBA validity, all transparent pixels, movement and heartbeat
refresh, hide balancing and restoration. These checks do not establish what
Telemost viewers see; that verification remains pending.

On November 19, the local read-only cursor-image probe reported 56×80 pixels
with 873 nontransparent pixels under 1.4.2, despite a hidden Quartz visibility
flag. With 1.4.3 enabled, the same API returned 16×16 pixels with zero
nontransparent pixels. `swift Tools/InspectCaptureCursor.swift` reproduces the
image check without recording the screen or changing the cursor. Receiver-side
Telemost verification is still required.
