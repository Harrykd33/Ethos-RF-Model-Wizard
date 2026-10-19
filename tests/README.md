# Simulator checks

Use a disposable X18RS Ethos 26.1.2 simulator workspace with a valid, empty
model00.bin. These macros create mixes and save the test model. Do not run
against a personal simulator workspace or radio.

Stage the following files at the scratch workspace root:

- rotorflight-model-wizard/app/lib/model_wizard.lua as controller.lua
- rotorflight-model-wizard/lib/register_model_wizard.lua as register.lua
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
