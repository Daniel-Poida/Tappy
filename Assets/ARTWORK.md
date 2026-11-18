# Tappy 1.1 artwork

Production transparent PNGs, generated with the built-in imagegen tool and copied into the project:

- `Sources/Resources/Hands/Classic.png`
- `Sources/Resources/Hands/MoonWand.png`
- `Sources/Resources/Hands/StarWand.png`
- `Sources/Resources/Hands/WizardWand.png`

The original alpha is preserved. The app renders each square image without distorting its proportions, anchors the fingertip to the click position and joins the short wrist to a procedural rubber-hose forearm. The forearm shares the glove's animated transform. Version 1.3 adds independent length and lower-opacity controls. The narrow white keyline and black contours make both glove and arm readable on light and dark backgrounds.

## Prompt set

All four calls used `transparent_background: true` and the following shared specification:

> Use case: stylized-concept. Asset type: production transparent PNG cursor sprite for a polished macOS app. Create ONE beautifully drawn classic 1930s rubber-hose cartoon WHITE GLOVE HAND, strong confident ink contours, warm off-white fabric, restrained cool-gray cel shadows, expressive organic anatomy, a real broad palm and soft puffy segmented fingers, three short iconic crease marks, thick rolled white cuff with ribbing, short BLACK rubber-hose wrist projecting vertically downward from cuff. Premium hand-inked animation character asset, NOT an emoji, NOT a flat UI icon, NOT a simplistic vector mitten, NOT 3D plastic. Bold near-black outer line with a narrow crisp WHITE outer keyline for visibility on dark and light screens. Absolutely transparent alpha background. No text, no labels, no watermarks, no rectangular background, no cast shadow. Square 1024x1024 canvas. Entire object fits with 70px margin. Wrist opening centered horizontally at x=512 near y=900, wrist segment ends near y=950. The highest pointing tip is centered at x=512 near y=80. Hand has substantial volume, glove width about 500px and is very readable at 100px screen size.

### Classic

> Subject: classic cartoon pointing gesture seen from the BACK of the glove, index finger pointing straight UP toward the top center, slightly bent natural finger, wide rounded index not a long narrow tube. Two other folded digits form clear soft knuckles on the right, large bent thumb on the left. Only this one pointing hand and short black wrist, no prop, no sparkles.

### Moon wand

> Subject: a cartoon gloved hand with a NATURAL CONVINCING GRIP around a Sailor Moon inspired magical moon scepter. The fingers visibly wrap around the pink handle, a large thumb crosses the front of the handle diagonally and overlaps curled fingers. The wand points perfectly vertically UP. Gold open crescent moon at its top with open upward horns, a vivid pink heart jewel, small elegant white wings, gold details. Tiny gold diamond at top center is the precise highest tip. Show full wand and hand, clear separation and convincing finger anatomy. No pointing finger, no disconnected floating object. Pink-and-gold magical girl styling, visually recognizable and luxurious.

### Star wand

> Subject: a cartoon gloved hand with a NATURAL CONVINCING GRIP around the magical wand of Star Butterfly from Star vs the Forces of Evil / Princess Star. Fingers visibly curl around handle, a large thumb crosses the front of handle diagonally. The wand points perfectly vertically UP. A lavender-purple circular wand head, a large GOLD FIVE-POINTED STAR face centered on it with its top point highest at center, tiny WHITE FEATHER WINGS on each side, small pink heart below the star, slender pink-and-purple handle. Show full wand and hand, clear silhouette, visually distinctive colorful magical-girl prop. No pointing finger, no disconnected floating object.

### Magic wand

> Subject: a cartoon gloved hand with a NATURAL CONVINCING GRIP around a Harry Potter inspired slender wooden wizard's magic wand. Fingers visibly wrap round a knobbly carved wooden handle, a large thumb crosses the front diagonally and overlaps curled fingers. The wand points perfectly vertically UP with its precise tapered wooden tip the highest point at top center. Rich walnut wood, gentle taper and organic carved rings in the grip, understated gold-brown highlights, NO gold diagonal stripes, NO blade, NO sword, NO big star or objects around it. Show full wand and hand, clear silhouette, convincing anatomy and charming animation character design.

## Version 1.3 anatomy correction

The three wand sprites were edited with the built-in imagegen tool, preserving each wand, tip position, cuff, wrist and transparent background. The classic glove already had four digits. Production file paths above remain unchanged.

Final edit prompt (applied separately to MoonWand, StarWand and WizardWand):

> Use case: precise-object-edit. Edit the attached transparent cursor sprite. Change ONLY the glove finger anatomy so the cartoon hand has EXACTLY FOUR DIGITS TOTAL: ONE large thumb crossing diagonally over the front of the wand handle, and EXACTLY THREE rounded curled fingers stacked vertically on the LEFT side of the handle. Remove the extra fourth curled digit / upper extra knuckle currently hiding behind the thumb: the final silhouette must show only three left finger lobes plus the one thumb, with no additional finger or knuckle behind the thumb. Keep a believable soft rounded grip. Keep everything else as closely identical as possible: exact wand and its ornaments, exact wand tip position, the original canvas dimensions, hand position, glove cuff and black wrist position, original cream white glove, dark bold ink contours, cel shading, narrow white external keyline, and full transparent alpha background. No cast shadow, no text, no new decorations, no new prop, no cropping. This is a minimal anatomy correction for a production app asset; preserve composition and alignment.

In 1.3 the procedural forearm follows the glove's changing angle and fades toward a transparent tip. Its length ranges from the short arm to the original full-screen extension; its lower opacity is adjustable independently.


## Version 1.3 palm and idle layers

Built-in imagegen edits removed the three decorative back-of-glove stripes from the palms of MoonWand, StarWand and WizardWand. Every glove retains exactly four digits. The production files above were replaced as requested.

Six transparent idle layers are stored in `Sources/Resources/Hands/Idle/`: `ClassicWave.png`, `ClassicFist.png`, `Catch.png`, `MoonWandObject.png`, `StarWandObject.png`, `WizardWandObject.png`.

Final prompt specifications:

- Palm correction: remove only the three black decorative teardrop stripes from the right palm, fill with matching cream fabric and shading; preserve natural finger creases, four digits, prop, canvas alignment, cuff, wrist and transparency.
- ClassicWave: a friendly two-finger wave, index and neighboring finger extended together, remaining finger folded, thumb naturally on the left; exactly four digits; preserve the original palm, cuff, wrist, shading, glove-back stripes, contours and transparency.
- ClassicFist: a soft relaxed fist, three fingers curled into the palm and thumb resting across them; exactly four digits; preserve the original palm/cuff/wrist position and style.
- Catch: remove the entire prop and show an empty upward-facing cupped four-digit catching palm in the original lower half of the canvas. Remove the three decorative stripes from this palm; preserve natural creases, cuff and wrist, leaving the upper half transparent.
- Each Object layer: remove the entire glove, cuff and wrist; retain the original wand alone in its exact original canvas alignment and restore the handle portions previously hidden by the fingers. Preserve the original bottom ornament, style and transparency.

Idle animation is assembled in code from these independent layers. The prop follows a timed toss and one revolution before the glove catches it. The classic glove crossfades its pointing, wave and fist poses.

## Version 1.3.3 wrist join

Source PNGs retain their original pixels. Rendering preserves each curved cuff while cutting the painted wrist out from its opening (`PointerGeometry.wristRim` and `gloveClip`). The procedural forearm starts two local points inside that opening. A single `PointerFigure` Canvas draws the forearm and glove using one animated phase and transform, then applies one shadow to the combined silhouette. Bitmaps are decoded once and drawn synchronously through CoreGraphics in the same Canvas pass as the arm. This keeps the joint continuous during click compression, spring overshoot and idle gestures. Catching hands are aligned to the selected character's cuff.

`Tappy-1.3.3-tap-preview.png` shows enlarged rendered tap and rebound frames on light and dark backgrounds.
