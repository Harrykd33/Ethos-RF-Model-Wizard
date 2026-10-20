# Rotorflight Model Wizard

A standalone Lua wizard that creates a nine-channel Rotorflight radio model
through Ethos's built-in **Create model** flow. Choose the existing FrSky
layout or an **ExpressLRS (ELRS)** layout on the first wizard page.

It assigns arm, throttle hold, a shared rates/profile selector, blackbox and
rescue. The full Rotorflight Lua suite, an internet connection and a connected
flight controller are not required to create the model.

## Requirements

- Ethos firmware supporting Lua wizard pages and mix creation. Tested with
  X18RS simulators running **26.1.2** and **26.2.0-RC1**.
- **System > Sticks > First four channels fixed** set to **OFF**.
- Select the **Rotorflight** category when available, or **Other** on older firmware.

The package detects `system.registerWizard()` at startup. Supporting firmware
gets a dedicated **Rotorflight** category. Older firmware gets a **Rotorflight
Wizard** System tool: its launch button activates the setup pages for one
creation session. Normal model creation keeps those pages hidden. The new API was announced for
**26.2.0-RC2**. The 26.1.2 and 26.2.0-RC1 simulators do not provide it.

The **First four channels fixed OFF** checkbox confirms your manual stick
setting; the wizard does not change that setting automatically. The new
Rotorflight category selects the Other model type automatically.

The category registration and controller were tested with an API shim on
26.1.2, including real mix outputs and persistence. Category page layouts were
rendered through a test adapter. The real RC2 category tile and automatic
callback timing still need verification on supporting firmware.

API references: [registerWizard](https://ethos-lua-doc.frsky-rc.com/api/system/registerWizard/)
and [registerWizardPage](https://ethos-lua-doc.frsky-rc.com/api/system/registerWizardPage/).

## Installation

1. Extract `rotorflight-model-wizard-standalone-en.zip`.
2. Copy the entire **rotorflight-model-wizard** folder into the radio or
   simulator's **scripts** folder.
3. Safely eject the radio drive when copying over USB, then fully restart
   the radio or simulator.

The installed files should be arranged as follows:

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

Keep the folder name **rotorflight-model-wizard** unchanged. Keep all three
Lua files and both icon PNG files together; copying only `main.lua` is insufficient. The script uses
absolute file paths so its later callbacks work on physical radios.

### Using it alongside the full suite

If `scripts/rfsuite/lib/register_model_wizard.lua` exists, the standalone
copy defers to the suite's wizard integration to avoid duplicate pages.

To run independently, close the simulator or power down the radio before
moving the `rfsuite` folder to a backup location **outside scripts**. Retain
`rfsuite.user`, your models and `radio.bin`.

The older **rotorflight-wizard** script is separate. This package creates a
**Rotorflight Wizard** launcher on older firmware; supporting newer firmware
shows its own **Rotorflight** category directly in **Create model**.

## Create a model: new Rotorflight category

Use this flow when **Rotorflight** appears beside the built-in model types:

1. Set **System > Sticks > First four channels fixed OFF**.
2. Open **Model > Model select > + model tile > Create model > Rotorflight**.
3. Confirm **First four fixed OFF**. Set **Use ELRS channel order ON** for
   ELRS, or leave it OFF for the FrSky layout.
4. Choose **Ignore blackbox** and **Ignore rescue** on this first page if you
   do not need those functions. Their assignment pages will be skipped.
5. Assign arm, throttle hold and all three rates/profile positions. Assign
   blackbox and rescue only if enabled.
6. Review the channel and switch assignments. There is no separate create
   toggle in this mode.
7. Press **Next** to let Ethos invoke the final mix-generation callback, then
   name and save the model. Incomplete assignments leave the draft unchanged.
   Only the stick-setting instruction and switch-assignment note are displayed;
   validation messages remain hidden.

All nine channel slots are created together, even when optional pages are
skipped. CH8/CH9 stay at -100% when ignored.

## Create a model: older firmware (including 26.1.2)

1. Open **System > Sticks** and set **First four channels fixed OFF**.
2. Open **System** and select the **Model Wizard RF logo tile**. Scroll to the next System menu page
   if needed. Its first page explains the stick setting and **Other** selection.
   Press **Create Rotorflight model**.
3. In Model select, select the large **+ model tile**, then **Create model**.
4. Select **Other**. Selecting Heli supplies its own mixes and changes the
   resulting channel order. Older firmware cannot check this selection in Lua.
5. Confirm **First four fixed OFF**. The redundant **Other model selected**
   and **Set up Rotorflight switches** options have been removed.
6. Set **Use ELRS channel order ON** for ELRS, or leave it OFF for FrSky.
7. Assign arm (**CH5 ELRS / CH6 FrSky**) and throttle hold
   (**CH6 ELRS / CH3 FrSky**).
8. Assign all three profile/rates switch positions for **CH7**.
9. Assign blackbox on **CH8**, or turn **Ignore blackbox ON**.
10. Assign rescue on **CH9**, or turn **Ignore rescue ON**.
11. Review the assignments and turn **Create CH1-CH9 ON** before pressing
    Next. It stays disabled until all required assignments are valid.
12. Name and save the model, then check its mixes and channel monitor.

The launch applies to the next model-creation session. Completing or cancelling
that session does not activate later wizards. Opening the launcher without
pressing its button does not activate anything. To clear a pending launch before
starting creation, reopen the launcher and leave without pressing the button.

Normal **Create model** flows remain unchanged when the launcher is not used.

Arm, throttle hold and any assigned rescue must use separate physical switches. CH7
requires all three distinct positions of one physical three-position switch.

Blackbox and rescue are optional. In the new category, choose Ignore on the
first page to skip the assignment page. In the older flow, Ignore disables
the picker on its own page. Either option removes that switch requirement. CH8 and CH9 remain present at **-100%**
when ignored, so channel numbers stay fixed. The review shows **Ignored**.
Turn Ignore OFF to restore its previous selection before creating the draft.

Assignments lock after draft generation. Restart model creation if you need
to change them afterward or if generation reports an error.

## FrSky channel map (ELRS option OFF)

| Channel | Mix name | Function and output |
| --- | --- | --- |
| CH1 | Aileron | Aileron stick |
| CH2 | Elevator | Elevator stick |
| CH3 | RF Throttle | -100% with hold engaged; +100% otherwise |
| CH4 | Rudder | Rudder stick |
| CH5 | Pitch | Collective from the throttle stick, independent of CH3 |
| CH6 | RF Arm | +100% at the armed position; -100% otherwise |
| CH7 | RF Profile | Shared rates/profile selector: -100%, 0%, +100% |
| CH8 | RF Blackbox | +100% at the active position; -100% otherwise |
| CH9 | RF Rescue | +100% at the active position; -100% otherwise |

## ELRS channel map (ELRS option ON)

| Channel | Mix name | Function and output |
| --- | --- | --- |
| CH1 | Aileron | Aileron stick |
| CH2 | Elevator | Elevator stick |
| CH3 | Pitch | Collective from the throttle stick, independent of hold |
| CH4 | Rudder | Rudder stick |
| CH5 | RF Arm | ELRS AUX1: +100% armed; -100% disarmed |
| CH6 | RF Throttle | -100% with hold engaged; +100% otherwise |
| CH7 | RF Profile | Shared rates/profile selector: -100%, 0%, +100% |
| CH8 | RF Blackbox | +100% at the active position; -100% otherwise |
| CH9 | RF Rescue | +100% at the active position; -100% otherwise |

This follows Rotorflight's **AECR1T23** order for ELRS. Collective needs
stick resolution on CH3; CH5/AUX1 carries the two-position arm state.
CH6 is the governor command, not another arm channel. Rates/profile,
blackbox and rescue keep their existing CH7/CH8/CH9 assignments.

References: [Rotorflight ETHOS setup](https://rotorflight.org/docs/setup/radio-setup/radio-setup-ethos/ethos-generic-radio-setup)
and [ExpressLRS switch configuration](https://www.expresslrs.org/software/switch-config/).

Throttle (**CH3 FrSky / CH6 ELRS**) supplies a fixed command for the
**flight-controller governor**, rather than a throttle-stick curve for
bypass operation. Collective remains independent of throttle hold.

CH7 supplies one shared selector channel. Configure both the desired rate
and profile selections in Rotorflight to use that channel.

## After creation

Check **Model > Mixes** and the channel monitor to verify the saved channel
numbers, stick directions and switch outputs, including throttle hold.

Complete receiver binding, RF setup and failsafe separately. In Rotorflight,
configure the receiver channel map, arm/blackbox/rescue mode ranges and
CH7 rates/profile selection. For ELRS, set the receiver map to AECR1T23,
arm on CH5/AUX1, throttle on CH6, blackbox on CH8 and rescue on CH9.
Configure the appropriate external RF module/CRSF link, binding and ELRS
switch mode separately. The wizard does not write flight-controller
settings or configure radio stick rates.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Wizard page is missing | Check the complete installation and restart Ethos. Select **Rotorflight** when available; otherwise start from **System > Rotorflight Wizard > Create Rotorflight model**, then choose **Other**. If the full suite's wizard integration is installed, the standalone copy defers to it. |
| Rotorflight category is missing on 26.1.2/26.2.0-RC1 | Expected: those versions lack `system.registerWizard()`. Use **System > Rotorflight Wizard > Create Rotorflight model**, then **Other**. |
| Helicopter channel-order page appears | Restart creation and select **Other**. |
| Outputs have the wrong channel numbers | Confirm **First four channels fixed OFF**, then restart creation as **Other**. |
| Create control is disabled | Fill in arm, throttle hold and all three profile positions; assign blackbox/rescue or turn their Ignore options ON. No validation message is shown. Check the setup confirmations and unassigned fields. |
| Saved model has no wizard mixes | In the older **Other** flow, turn **Create CH1-CH9 ON** before continuing. In the new category, complete a valid review and continue with **Next**. |
| `cannot open ... model_wizard.lua` | Reinstall the complete current package under the exact folder name shown above. Clear the affected compiled caches and restart Ethos. |
| Changes do not appear after an update | With the radio or simulator closed, remove `main.luac`, `lib/register_model_wizard.luac` and `app/lib/model_wizard.luac` if present. Keep the corresponding `.lua` files. Restart Ethos to recompile them. |

## Build from this repository

The files under `rotorflight-model-wizard/` are the standalone source.
Run from the **Ethos RF Model Wizard** repository root:

```powershell
python package.py
```

This regenerates the category icon from `assets/build_icon.py`, then rebuilds
`rotorflight-model-wizard-standalone-en.zip` with the three Lua files, icon,
this README and the root `ethos_lua_manifest.json`. Compiled
Lua caches and tests are excluded. Python's standard library is sufficient.
See `tests/README.md` for simulator validation instructions.

## License

GPLv3: <https://www.gnu.org/licenses/gpl-3.0.en.html>

The older System tool uses the supplied Model Wizard RF Helicopter logo. The
newer Rotorflight category keeps its existing icon. To regenerate the older
icon, install Pillow and run `python assets/build_legacy_icon.py`. Normal ZIP
packaging uses the checked-in mask and needs no image library.

The older System tile has no separate text label; the enlarged logo supplies
its title. Select that logo to open the launcher.
