# Rotorflight Model Wizard

A standalone Lua wizard that creates a nine-channel Rotorflight radio model
through Ethos's built-in **Create model** flow.

It assigns arm, throttle hold, a shared rates/profile selector, blackbox and
rescue. The full Rotorflight Lua suite, an internet connection and a connected
flight controller are not required to create the model.

## Requirements

- Ethos firmware supporting Lua wizard pages and mix creation. Tested with
  X18RS simulators running **26.1.2** and **26.2.0-RC1**.
- **System > Sticks > First four channels fixed** set to **OFF**.
- A new model created using the **Other** model type.

The model type and stick setting are essential for the channel order below.
The wizard's preparation checkboxes confirm that you have set them; they do
not change those settings automatically.

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
    README.md
    lib/
      register_model_wizard.lua
    app/
      lib/
        model_wizard.lua
```

Keep the folder name **rotorflight-model-wizard** unchanged. Keep all three
Lua files together; copying only `main.lua` is insufficient. The script uses
absolute file paths so its later callbacks work on physical radios.

### Using it alongside the full suite

If `scripts/rfsuite/lib/register_model_wizard.lua` exists, the standalone
copy defers to the suite's wizard integration to avoid duplicate pages.

To run independently, close the simulator or power down the radio before
moving the `rfsuite` folder to a backup location **outside scripts**. Retain
`rfsuite.user`, your models and `radio.bin`.

The older **rotorflight-wizard** System Tool is a separate script. This
wizard appears inside **Create model**, not in the System Tools menu.

## Create a model

1. Open **System > Sticks** and set **First four channels fixed OFF**.
2. Open **Model > Model select**.
3. Select the large **+ model tile**, then **Create model**. The small plus
   beside the folder heading creates a folder.
4. Select **Other**. Selecting **Heli** adds Ethos's own helicopter mixes
   and changes the resulting channel order.
5. On **Rotorflight switch setup**, confirm **Other model selected** and
   **First four fixed OFF**, then enable **Set up Rotorflight switches**.
6. Assign the armed position for **CH6**.
7. Assign the throttle-hold position for **CH3**.
8. Assign the three positions of the shared rates/profile switch for **CH7**.
9. Assign the blackbox-active position for **CH8**.
10. Assign the rescue-active position for **CH9**.
11. Review the assignments and turn **Create reviewed CH1-CH9 ON**. This
    creates the draft mixes; do this before pressing Next.
12. Continue to the model-name screen and finish saving the new model.

Arm, throttle hold and rescue must use separate physical switches. CH7
requires all three distinct positions of one physical three-position switch.

Assignments lock after draft generation. Restart model creation if you need
to change them afterward or if generation reports an error.

## Channel map

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

CH3 supplies a fixed command for the **flight-controller governor**. It is
not a throttle-stick curve for governor-bypass operation.

CH7 supplies one shared selector channel. Configure both the desired rate
and profile selections in Rotorflight to use that channel.

## After creation

Check **Model > Mixes** and the channel monitor to verify the saved channel
numbers, stick directions and switch outputs, including throttle hold.

Complete receiver binding, RF setup and failsafe separately. In Rotorflight,
configure the receiver channel map, arm/blackbox/rescue mode ranges and
CH7 rates/profile selection. The wizard does not write flight-controller
settings or configure radio stick rates.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Wizard page is missing | Check the installation folder, restart Ethos and create a new model as **Other**. If the full suite's wizard integration is installed, the standalone copy defers to it. |
| Helicopter channel-order page appears | Restart creation and select **Other**. |
| Outputs have the wrong channel numbers | Confirm **First four channels fixed OFF**, then restart creation as **Other**. |
| Saved model has no wizard mixes | Turn **Create reviewed CH1-CH9 ON** on the review page before continuing to the name screen. |
| `cannot open ... model_wizard.lua` | Reinstall the complete current package under the exact folder name shown above. Clear the affected compiled caches and restart Ethos. |
| Changes do not appear after an update | With the radio or simulator closed, remove `main.luac`, `lib/register_model_wizard.luac` and `app/lib/model_wizard.luac` if present. Keep the corresponding `.lua` files. Restart Ethos to recompile them. |

## Build from this repository

Run from the `rotorflight-lua-ethos-suite` repository root:

```powershell
python bin/package/build_model_wizard.py --lang en
```

The package is written to:

```text
build/rotorflight-model-wizard-standalone-en.zip
```

The builder uses the shared wizard source and resolves translations before
packaging. Other available repository locales can be selected with `--lang`;
new untranslated strings use English fallbacks.

## License

GPLv3: <https://www.gnu.org/licenses/gpl-3.0.en.html>
