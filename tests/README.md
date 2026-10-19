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
