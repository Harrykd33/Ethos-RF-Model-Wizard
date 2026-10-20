# Simulator checks

Use a disposable X18RS Ethos 26.1.2 simulator workspace with a valid, empty
model00.bin. These macros create mixes and save the test model. Do not run
against a personal simulator workspace or radio.

Stage the following files at the scratch workspace root:

- rotorflight-model-wizard/app/lib/model_wizard.lua as controller.lua
- rotorflight-model-wizard/lib/register_model_wizard.lua as register.lua
- rotorflight-model-wizard/icon.png as icon.png
- tests/model_wizard.lua as check.lua

Run /check.lua using the simulator macro runner. Test the standard layout
first. For ELRS, use a fresh empty workspace and prefix check.lua with
`TEST_ELRS = true`. For a scratch radio already configured with First four
channels fixed OFF, also prefix `TEST_PRECONFIGURED = true`; otherwise the
macro toggles that setting from the X18RS factory default using UI events.

Form fields are mocked; source lookup, mix generation, channel evaluation,
switches, sticks and model persistence use real firmware. Success must be
confirmed by a PASS message, because macro assertion failures may not cause
the host simulator runner to return a failing process exit code.

Coverage: default layout, selection changes, missing/duplicate assignments,
independent switches, exact nine-channel allocation, repeated-run protection,
locked fields, 48 arm/hold/profile/blackbox/rescue combinations, stick endpoints,
save/reload and cleanup/reset. Both layouts passed on X18RS 26.1.2 during
this change. A separate native Other-model flow also saved an ELRS model
with exactly CH1-CH9; preparation and review screens were visually checked.

Navigation regression: selecting ELRS alone enables all six assignment/review
pages and turns the setup toggle ON. Turning setup OFF clears ELRS. Both
standard and ELRS native flows were tested from default OFF selections through
all seven pages to a saved nine-channel model on X18RS Ethos 26.1.2.

Optional-switch regression: prefix the macro with `TEST_IGNORE_BLACKBOX = true`
and/or `TEST_IGNORE_RESCUE = true` to test either skip option. All four ignore
combinations passed on each layout (384 switch combinations total), including
unassigned ignored switches, re-enabling required assignment, inactive saved
outputs, and reset/locking. CH8 and CH9 are always present.

Native tests also saved standard/ELRS models with both options assigned and
both ignored. Review screenshots were checked with missing assignments and
with both options ignored: the create control stays near the top, clear of
the navigation footer, and is disabled when required assignments are missing.

## Custom category API (0.5.0)

Prefix the macro with `TEST_CATEGORY = true` to test category controller mode.
The registration section always tests both the old API and a shim of
`system.registerWizard(name, icon, pages)`. It checks feature detection,
registration without registerWizardPage, absolute paths, real mask loading,
lazy controller loading, one mask load, reset behavior, optional-page
availability, centralized final run, and missing-input rejection.

Category and legacy modes passed all layouts and ignore combinations:
16 variants / 768 switch combinations, with real 26.1.2 source/mix/output
and model-save APIs. Named analog constants were verified on 26.1.2 and
26.2.0-RC1. Neither cached firmware supplies system.registerWizard.

The legacy native Create model flow saved standard and ELRS models with
both optional functions assigned and both ignored. Category forms were
rendered with a test-only adapter to registerWizardPage for visual checks,
including a valid review, missing assignments and skipped optional pages.
This adapter does not verify the actual new category tile or native run
callback timing.

Required follow-up on real supporting firmware (announced for 26.2.0-RC2):
select the Rotorflight tile; verify both layouts, each optional-page
combination, invalid inputs, review -> Next -> name -> save, Back navigation,
cancel/restart, and exact CH1-CH9 with ignored channels at -100%. Confirm
that native run happens after the review and runs only once per draft.

## Cleanup (0.5.2)

Instructional prompts, status text and input-validation messages are removed.
Required setup fields and internal checks remain. Invalid run calls return
false without creating mixes or displaying a Lua validation error. The legacy
Create CH1-CH9 control remains disabled until inputs are valid.

Channel names share one table; the ELRS selector updates the three differing
slots in place. Selected-layout labels are refreshed only when that choice
changes. Page builds read screen dimensions once, and short text avoids the
wrapping/substitution path. No wakeup/paint callbacks or logging were added.

The final 0.5.2 checks passed all 16 mode/layout/ignore variants (768 switch
combinations), saved both legacy layouts through the real simulator UI, and
visually verified message-free review pages, optional-page skipping and title
spacing. Actual RC2 category integration remains pending as documented above.

In an isolated 26.1.2 Lua benchmark using mock form fields and the same five
page-build sequence, incremental retained Lua memory fell from about 17.68 KiB
(0.5.1) to 16.52 KiB after GC. Screen-size queries fell from 10 to 5. These
figures describe that controller/fixture sequence, not total radio RAM or FPS.

## Instructions (0.5.3)

Restored the System > Sticks / first-four-fixed-OFF instruction on setup and
the requested click-box / flip-switch note on pages 2-6. Validation messages
remain hidden. The real 26.1.2 native ELRS flow saved exact CH1-CH9; setup
and the three-profile-field page were visually checked for fit.

## Explicit legacy launcher (0.6.0)

The Other-model confirmation and legacy setup opt-in have been removed.
The legacy controller starts only after an explicit launcher activation.
Registration tests capture registerSystemTool/openPage and check that every
page is hidden before launch, activation is consumed by the next wizard init,
normal creation cannot load the controller, opening the tool without pressing
its button does not arm creation, and relaunch resets selections. New firmware
registers only its category, with no legacy launcher.

All 16 channel/controller variants passed on 26.1.2. Ten native UI cases also
passed: normal Plane, Glider, Heli and Other creation with zero Rotorflight
page builds/controller loads; explicit standard/ELRS creation with assigned
and ignored optional channels, each followed by clean normal creation; cancel
from the launcher; and cancel from active Rotorflight creation. Both layouts
retained exact CH1-CH9. Native category testing on supporting RC2 firmware
remains pending as described above.

The actual legacy UI path is System > Rotorflight Wizard > Create Rotorflight
model, then Model select > + > Create model > Other. A macro must use the real
System-menu button to enter the Lua tool: directly calling openPage(toolIndex)
from a 26.1.2 macro changes its Lua execution context, preventing later macro
sleep calls. Production navigation uses the standard native button event path.

## Legacy logo and instructions (0.6.1)

The older System tool uses the supplied logo as a grayscale PNG mask. Its
launch page shows the stick setting and large + tile > Create model > Other
instructions above the button. Simulator screenshots confirmed both fit.
Both controller modes now display FrSky in place of Standard.

All 16 controller configurations (768 switch combinations) passed on 26.1.2,
with the category API shim for modern registration. All ten native legacy
creation/cancellation flows passed. ZIP manifest validation also passed.

## Logo-only System tile (0.6.2)

Verified the label-free, enlarged logo in the real 26.1.2 System menu.
The complete artwork fits inside its tile. The native launcher cancellation
flow still passes. Modern category naming and icon remain unchanged.

## Heli FBL (0.7.0)

`heli_fbl.lua` runs in a disposable blank X18RS simulator with first-four-fixed
OFF, production controller at `/controller.lua`, and TEST_CATEGORY, TEST_ESC,
TEST_IGNORE_RESCUE, TEST_SHARED flags. It tests both governor modes in legacy
and category controller flows, rejected duplicate/unsafe switch assignments,
162 switch combinations per configuration, custom gains and speeds, shared
gyro/bank switches, ignored rescue, linear sticks and save/reload. All eight
FBL cases passed; all 16 FrSky/ELRS regression configurations also passed.

Two native 26.1.2 Other-model creation flows passed for FBL and ESC governors.
They saved exactly CH1-CH8, exercised throttle hold and governor run, reloaded
the saved model, then created a normal Plane without Rotorflight pages. These
use scratch-only assignment fixtures; production files do not preassign
switches. Screenshots verified the compact hold/rescue, gyro/value, bank,
governor/value and review pages fit above navigation controls.

The native draft tests caught that named source lookup resolves the active
model rather than newly created draft logical switches. Production governor
gates reference LS1 onward with category/member descriptors. Keep native draft
creation checks when changing these references; live-model tests alone do not
exercise that distinction. The modern category API remains shim-tested.

## Shared bank/idle-up governor control (0.7.1)

Model type choices are FrSky RF, ELRS RF and Heli FBL. The first page and
Heli FBL governor/hold page use Create Heli FBL Model. Bank/IdleUP 1/2/3
selects CH7 (-100/0/+100). ESC governor throttle values stay on CH3 and use
those same physical bank positions. FBL governor uses CH7 for speed selection
and CH3 for hold/run without a separate governor-on assignment or logic switch.
The two redundant governor assignment pages are skipped in both controller modes.

All 24 controller configurations passed (16 RF/ELRS and 8 Heli FBL), including
mode changes that retain the bank assignments, ignored rescue, shared gyro/bank,
162 switch combinations per FBL case, hold overrides and persistence. FBL tests
leave the old governor-on and separate ESC speed positions unset and also create
a valid FBL model with createLogicSwitch unavailable. Native 26.1.2 Other-model
creation passed for both governor modes, saved CH1-CH8, verified hold/run on
reload and completed a following normal Plane wizard without RF pages leaking.
Screenshots verified requirements, governor/hold, gyro, bank/idle-up and review.

## Launcher wording and shared logo (0.7.2)

The legacy launch instruction and button now say Create Heli FBL Model. Both
icon assets come from Model Wizard Helicopter Logo.png, resized as grayscale
masks for the legacy tile and modern category. Packaging uses the checked-in
masks and no longer regenerates an unrelated category symbol.

The 26.1.2 native launcher/Other creation/save-reload flow passed, followed by
normal model creation. Registration tests passed for both legacy and modern
API-shim paths with the new masks. Native screenshots verified the complete
System logo and launcher wording. Real modern category rendering still needs
firmware with registerWizard; its registration/mask loading was shim-tested.

## Framed helicopter icon (0.7.3)

Both icon masks now derive from Model Wizard Helicopter Icon.png, including
its rounded frame, title and helicopter. Empty outer black margins are removed;
the artwork is inverted into Ethos mask polarity and resized for each tile.
The native 26.1.2 System menu displays the complete framed icon with theme
colors. Native creation/save-reload and legacy/modern registration-shim tests
passed using the new production masks.

## Native Ethos tile styling (0.7.4)

Both icon assets now contain only the helicopter glyph as an 8-bit grayscale
mask. The original embedded frame, title and dark panel are omitted, and the
legacy tool name is Model Wizard so Ethos draws the caption and tile chrome.
The native 26.1.2 menu was visually checked with the icon selected and unselected:
Ethos supplies black/orange and white/dark appearances respectively. The native
launcher/creation/reload flow and both registration paths passed; modern
registration still uses the API shim.
