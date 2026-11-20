# Pointer motion delivery

The native overlay receives local and global AppKit mouse events. Both monitor
callbacks read the latest `NSEvent.mouseLocation` and update the cached rendered
frame immediately. They do not replay older event coordinates or wait for the
animation clock. This applies to hover movement, dragging and Presentation Mode.
The panel accepts mouse-moved events and its view tracks movement even when
another application retains keyboard focus.

`CursorOverlayView.move` changes the current frame's position and top clearance,
and cancels the displayed idle pose as soon as the state cancels it. It preserves
the artwork's current animation phase, size and angle. It marks the view dirty;
[AppKit redraws dirty views in the event loop](https://developer.apple.com/documentation/appkit/nsview/needsdisplay),
coalescing high-rate input instead of synchronously rasterizing the full overlay
for every mouse event. The previous image is still cleared in the same draw pass
as the new joined hand and forearm.

The 90-Hz timer advances animation, angle smoothing and cursor hiding. It no
longer samples mouse position. A separate 30-Hz recovery timer handles cursor
warps and missed input, and requests a redraw only when the position changes.
Both timers and both mouse monitors stop when Tappy is disabled. Existing cursor
restoration and the screen-sharing fix are retained.

Validation covers exact subpixel position updates between animation ticks,
unchanged animation phase, immediate idle-pose cancellation, latest-position
retention under rapid input, pixel comparison with a fresh frame, and movement
tracking while presenting. This removes the old wait for the next 90-Hz position
sample (up to about 11.1 ms). It does not establish physical input-to-display
latency: display refresh, AppKit event delivery and compositing still contribute.
