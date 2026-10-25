# Heli Wizard

Standalone helicopter model setup for FrSky Ethos, with **FrSky RF**, **ELRS RF**
and **Heli FBL** layouts. No Rotorflight Lua suite or connected flight controller
is required. Supports the older System launcher, including Ethos 26.1.2, and
the model-category launcher in Ethos 26.2.0.

## Install

1. Extract `rotorflight-model-wizard-standalone-en.zip`.
2. Copy the complete `rotorflight-model-wizard` folder into the radio or
   simulator's `scripts` folder. Keep the folder name unchanged and include
   all three Lua files and both icons.
3. Safely eject the radio drive, then fully restart the radio or simulator.

## Create a model

First open **System > Sticks** and disable **First four channels fixed**.
The wizard's confirmation switch does not change this setting for you.

- **Ethos 26.2.0:** open **Model > Model select > + > Create model > Heli Wizard**.
- **Older firmware:** open **System > Heli Wizard**, press **Create Heli FBL Model**,
  then choose **Model select > + > Create model > Other**.

Confirm **First four fixed OFF**, select the model type and complete the switch
assignments. Click each switch box, then flip the physical switch to the desired
position. On review, turn **Click button to create CH1-CH9** ON for RF layouts,
or **Click button to create CH1-CH8** ON for Heli FBL. Then continue to name and
save the model. Assignments lock after mix creation.

## Setup

**FrSky RF / ELRS RF:** assign arm, throttle hold and all three positions of one
rates/profile switch. Assign blackbox and rescue, or enable their **Ignore**
options. Arm, hold and rescue must use separate physical switches.

**Heli FBL:** select the governor type, assign throttle hold, then assign rescue
or enable **Ignore rescue**. Assign three gyro switch positions and gains, plus
three Bank/IdleUP positions. Each three-position group must use one switch;
gyro and bank may share a switch. Hold must be independent of both, and rescue
must use a separate switch.

- **FBL governor:** CH7 selects banks/speeds; CH3 outputs +100% running and -100% held.
- **ESC governor:** Bank/IdleUP selects three editable throttle commands on CH3;
  hold overrides them to -100%. This mode requires native logical-switch creation.

Gyro gains range from -100% to +100%. ESC commands range from 0% to 100%
(0% = -100% radio output; 50% = 0%; 100% = +100%). Gains and ESC commands default
to zero; enter values appropriate for your setup. Actual RPM settings belong
in the FBL or ESC.

## Channel maps

| Channel | FrSky RF | ELRS RF | Heli FBL |
| --- | --- | --- | --- |
| CH1 | Aileron | Aileron | Aileron |
| CH2 | Elevator | Elevator | Elevator |
| CH3 | Throttle / hold | Collective | Throttle / hold |
| CH4 | Rudder | Rudder | Rudder |
| CH5 | Collective | Arm / AUX1 | Gyro gain |
| CH6 | Arm | Throttle / hold | Collective |
| CH7 | Rates / profile | Rates / profile | Bank/IdleUP |
| CH8 | Blackbox | Blackbox | Rescue |
| CH9 | Rescue | Rescue | Not created |

Collective stays linear and independent of hold. RF throttle is a fixed governor
command: -100% held, +100% released. Rates/profile and Bank/IdleUP use
-100%, 0%, +100%. Ignored blackbox/rescue channels remain at -100%.

After saving, check **Model > Mixes** and the channel monitor for channel order,
stick response, switch direction and throttle hold. Configure receiver mapping,
RF module, binding, failsafe and FBL/ESC settings separately.

## Troubleshooting

- **Missing or outdated wizard:** reinstall the complete folder and fully restart.
  A suite integration at `scripts/rfsuite/lib/register_model_wizard.lua` takes
  precedence over the standalone wizard.
- **Create control disabled:** confirm the stick setting, complete required
  assignments and check switch separation. Assign or ignore optional functions.
- **Wrong channels or no mixes:** on older firmware choose **Other**, then enable
  the Create control on review before continuing.
- **Old code still loads:** with the radio/simulator closed, remove stale `.luac`
  files from the wizard folder, keep the `.lua` files and restart.

## Development

Run `python package.py` from the repository root to rebuild and verify the
standalone ZIP. Test instructions are in `tests/README.md` in the repository.

Licensed under GPLv3.
