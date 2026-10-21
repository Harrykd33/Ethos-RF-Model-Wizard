# Ethos RF Model Wizard

Standalone model creation for **FrSky RF**, **ELRS RF** and **Heli FBL**.
Select the model type on the **Create Heli FBL Model** page, assign physical
switch positions, review the channel map, then name and save the model.

The current package is **0.7.5**. It works without the full Rotorflight Lua
suite, an internet connection or a connected flight controller.

## Features

- FrSky RF and ELRS RF: nine-channel Rotorflight layouts with arm, throttle
  hold, shared rates/profile selection, optional blackbox and optional rescue.
- Heli FBL: eight-channel layout with governor selection, three editable gyro
  gains, linear collective, Bank/IdleUP 1/2/3 and optional rescue.
- ESC governor speed commands on **CH3**, selected by the bank/idle-up switch.
- FBL governor speed selection on **CH7**, with CH3 reserved for run/hold.
- Compact Heli FBL pages group related assignments and values together.
- Larger helicopter icons in both versions, with native Ethos labels, tile
  borders, backgrounds and selected/unselected colors.
- Automatic choice of the newer Rotorflight category or the older System
  launcher, depending on the firmware APIs available.

## Requirements

- Ethos with Lua wizard pages and mix creation. Heli FBL **ESC governor** mode
  also requires native logic switch creation; **FBL governor** mode does not.
- **System > Sticks > First four channels fixed** set to **OFF**.
- On older firmware, launch **System > Model Wizard** before creating a model,
  then select **Other** as described below.

The **First four fixed OFF** checkbox confirms your manual setting; the wizard
cannot change the radio's stick setting for you.

Native creation has been verified in the X18RS **26.1.2** simulator. The newer
`registerWizard` category path has been tested with an API shim and real mixer
outputs; its category tile and callback timing still need verification on
firmware that provides that API.

## Install or update

1. Extract `rotorflight-model-wizard-standalone-en.zip`.
2. Copy the entire **rotorflight-model-wizard** folder into the radio or
   simulator's **scripts** folder, replacing the previous wizard files.
3. Safely eject the radio drive after USB copying, then fully restart the
   radio or simulator.

Keep this folder structure:

```text
scripts/
  rotorflight-model-wizard/
    main.lua
    icon.png
    legacy-icon.png
    README.md
    lib/
      register_model_wizard.lua
    app/
      lib/
        model_wizard.lua
```

Keep the folder name unchanged and install all three Lua files and both icons.
The current test installation locations are:

- Simulator: `C:\Users\dover\AppData\Roaming\FrSky Suite\.simulator\26.1.2\persist\X18RS\scripts\rotorflight-model-wizard`
- Radio drive: `D:\scripts\rotorflight-model-wizard`

### Full-suite coexistence

If `scripts/rfsuite/lib/register_model_wizard.lua` exists, this standalone
script defers to that suite integration to prevent duplicate wizard pages.
For standalone use, close the radio or simulator before moving the suite's
`rfsuite` folder to a backup location outside **scripts**. Keep your models,
`radio.bin` and `rfsuite.user` data.

The older script named **rotorflight-wizard** is a separate installation.

## Open the wizard

### Older firmware: System launcher

Use this flow on firmware such as **26.1.2**:

1. Set **System > Sticks > First four channels fixed OFF**.
2. Open **System > Model Wizard**. Scroll to the next System menu page if
   needed; look for the large helicopter icon.
3. Press **Create Heli FBL Model**.
4. In Model select, choose the large **+ model tile**, then **Create model**.
5. Select **Other**. The built-in Heli wizard adds its own mixes and changes
   the channel allocation.
6. On **Create Heli FBL Model**, confirm **First four fixed OFF** and select
   **FrSky RF**, **ELRS RF** or **Heli FBL** under **Model type**.
7. Complete the assignments for that model type using the sections below.
8. On review, turn **Create CH1-CH9 ON** for either RF layout, or
   **Create CH1-CH8 ON** for Heli FBL. Then continue to name and save the model.

An explicit launch activates only the next creation session. Completing or
cancelling that session leaves later normal wizards unchanged. Opening the
launcher without pressing its button does not activate the setup pages.
Reopen the launcher and leave without pressing the button to clear a pending
launch before starting creation.

### Newer firmware: Rotorflight category

When the firmware provides `system.registerWizard`, select
**Model > Model select > + model tile > Create model > Rotorflight**.
Confirm the stick setting and select the desired **Model type**.

This category uses the Other model type automatically. On its review page,
press **Next** to create the mixes; there is no separate create toggle.

## FrSky RF and ELRS RF setup

1. Assign the armed position and throttle-hold position.
2. Assign all three positions of one three-position switch for rates/profile.
3. Assign blackbox and rescue, or enable their **Ignore** options.
4. Review and create the model using the control for your firmware version.

On assignment pages, click the box and flip the desired physical switch to
its intended position and direction. Arm, hold and rescue must use separate
physical switches. All three rates/profile positions must be distinct
positions of the same switch.

In the newer category, the Ignore controls on the first page skip optional
assignment pages. In the older flow, each Ignore control disables the picker
on its own page. Ignored blackbox/rescue channels remain present at **-100%**,
so later channels do not move. Assignments lock after mix creation.

## Heli FBL setup

After selecting **Heli FBL**, complete these compact assignment pages:

1. **Create Heli FBL Model**: select **Governor type**, assign **Throttle hold
   (CH3)**, then assign **Rescue active (CH8)** or turn **Ignore rescue ON**.
2. **Gyro gain**: assign three positions of one three-position switch and edit
   the corresponding CH5 gains from **-100% to +100%**.
3. **Bank/IdleUP**: assign **Bank/IdleUP 1/2/3** to three distinct positions
   of one switch. These produce **-100%, 0%, +100% on CH7**. ESC governor mode
   also shows an editable throttle percentage beside each assignment.
4. Review the map and create the model. The bank/idle-up page leads directly
   to review; there is no separate governor-on assignment page.

### Governor type

| Option | Speed selection | CH3 behavior |
| --- | --- | --- |
| **FBL gov: CH7 speeds** | Bank/IdleUP 1/2/3 on **CH7** selects the FBL's three speeds | +100% with hold released; -100% with hold engaged |
| **ESC gov: CH3 speeds** | The same bank/idle-up switch selects three editable **CH3** throttle values; CH7 keeps its bank mapping | Selected throttle value with hold released; -100% with hold engaged |

ESC throttle values range from **0% to 100%**: 0% produces radio output -100%,
50% produces 0%, and 100% produces +100%. These percentages are throttle
commands, not RPM values. Configure the actual governor speeds in your ESC
or FBL unit as appropriate.

ESC percentages and gyro gains initially default to **zero**. Enter the values
required by your setup. The gyro and bank functions may share one switch;
throttle hold must be independent of both. Rescue must use a separate switch.
Ignoring rescue keeps CH8 fixed at -100%.

FBL governor mode needs no additional on switch and creates no logic switches.
ESC governor mode creates four native logic switches to enforce hold, starting
at LS1 in the new Other model. No background Lua task is required after creation.

## Channel maps

| Channel | FrSky RF | ELRS RF | Heli FBL |
| --- | --- | --- | --- |
| CH1 | Aileron | Aileron | Aileron |
| CH2 | Elevator | Elevator | Elevator |
| CH3 | RF Throttle / hold | Collective | ESC throttle speeds or FBL run/hold |
| CH4 | Rudder | Rudder | Rudder |
| CH5 | Collective | RF Arm / AUX1 | Gyro gain |
| CH6 | RF Arm | RF Throttle / hold | Collective |
| CH7 | Shared rates/profile | Shared rates/profile | Bank/IdleUP 1/2/3 |
| CH8 | Blackbox | Blackbox | Rescue |
| CH9 | Rescue | Rescue | Not created |

Collective follows the throttle/collective stick linearly and remains
independent of throttle hold. For the RF layouts, throttle is a fixed governor
command: **-100% held / +100% released**, not a throttle-stick curve. Arm,
blackbox and rescue produce **+100% active / -100% inactive**. Rates/profile
uses **-100%, 0%, +100%**.

## After creation

Check **Model > Mixes** and the channel monitor for channel order, stick
response, switch direction and throttle hold. Complete RF-module setup,
receiver binding and failsafe separately.

For Rotorflight, configure the receiver mapping, arm/blackbox/rescue ranges
and shared CH7 rates/profile selection to match the selected RF layout.
For Heli FBL, configure the FBL receiver inputs, CH5 gyro gains, CH7 banks,
CH8 rescue and the selected governor mode to match the generated model.
The wizard does not write flight-controller or ESC settings.

## Troubleshooting

| Issue | Check |
| --- | --- |
| Wizard does not appear | Install the complete folder and restart. On older firmware use **System > Model Wizard > Create Heli FBL Model**, then **Other**. Check for a full-suite integration that takes precedence. |
| No Rotorflight category on older firmware | Use the System launcher; the category appears only when the firmware supplies `registerWizard`. |
| Wrong channel order or a built-in Heli channel page | Set first four channels fixed OFF and start a new creation flow using **Other**. |
| Create control is disabled for RF | Confirm the stick setting; assign arm, hold and all three profile positions; assign or ignore blackbox/rescue. Check switch separation. |
| Create control is disabled for Heli FBL | Confirm the stick setting; assign hold, all three gyro positions and all three bank/idle-up positions; assign or ignore rescue. Check switch separation. FBL governor needs no extra on assignment. |
| No mixes after older-firmware creation | Enable **Create CH1-CH9** for RF or **Create CH1-CH8** for Heli FBL on review before continuing. |
| Icon or changes look outdated | Fully restart. The current icon is a large helicopter with Ethos drawing the label and tile styling. |
| Lua file cannot open, or old code still loads | Reinstall the complete package. With the radio/simulator closed, remove stale `main.luac`, `lib/register_model_wizard.luac` and `app/lib/model_wizard.luac` if present; keep the matching `.lua` files. Restart. |

Incomplete assignments leave creation disabled without validation popups.

## Build and icon assets

From the **Ethos RF Model Wizard** repository root, run:

```powershell
python package.py
```

This rebuilds `rotorflight-model-wizard-standalone-en.zip` from the standalone
folder and `ethos_lua_manifest.json`, including this README and both icons.
Python's standard library is sufficient; tests and compiled Lua caches are
excluded. Simulator test notes are in [tests/README.md](tests/README.md).

Both wizard versions use the larger helicopter-only glyph extracted from
`assets/Model Wizard Helicopter Icon.png`. The embedded title, panel and frame
are omitted so Ethos controls the label, background, border and theme colors.
The older System tool is **Model Wizard**; the newer category is **Rotorflight**.

To regenerate the checked-in icon masks, install Pillow and run:

```powershell
python assets/build_icon.py
```

## License

GPLv3. See [LICENSE](LICENSE).
