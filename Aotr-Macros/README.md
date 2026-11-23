# Aotr-Macros

Auto-farm macros for **Attack on Titan Revolution** (Roblox), by **ExRaSc**. Windows only.

| Macro | File |
|---|---|
| Outskirt mission | `outskirt-mission/OutskirtMissionMacro.ahk` |
| Female raid | `female-raid/FemaleRaidMacro.ahk` |

## Use
1. Install **AutoHotkey v1.1** (not v2) and run a `.ahk` file, or download the `.exe` from **Releases**.
2. Start an **Outskirt mission** or a **Female raid**. The macros only work inside them, not in the lobby. Run as administrator if keys don't register.
3. Do the **SETUP** steps at the top of the script (F3, F4, F5...). Your setup is saved next to the script in an `.ini` file.
4. Start with `DRY_RUN` on to check the on-screen status box. Press **Ctrl+F1** to switch it off, then **F1** to start. **F2** quits.

## Abilities
**Must have abilities: Heatwave, Seismic Shock, Tectonic Quake, Incendiary Volley.** These are all you need.

If your loadout uses different slots or keys, open the script in any text editor and change the keys at the top (`ABILITY_ONE` to `ABILITY_FIVE`, one per hotbar slot, e.g. `"r"`, `"f"`, `"c"`, `"x"`, `"z"`). Then make sure the raid `PRIORITY` list matches this order: **Heatwave, Seismic Shock, Tectonic Quake, Incendiary Volley** (Heatwave first).

In human form the raid macro presses slot 4 then slot 3 as buffs (Founder's Order, Black Flare), then slot 5 to shift.

## My setup
- **Family:** Fritz
- **Skills:** Founders Order, both family perk slots, Order:Rage, Black and Red Flares. Support branch go right to capstone, Offence branch go right to capstone, defense branch go left to Tough As Nails and Titan Shifting.
- **Perks:** Avatar Of Ymir, StormWrath, 15th Commander, Font Of Inspiration, Adaptation and Immortal.
- **Artifacts:** Crown/Colossal Scars, Scorched Cloak. Both with Shifter Damage %.
- **Memories:** Divine Decree, Sparks Of Black, Elementalist, StatterPoint and Blood Awakening.
- **Serum:** Colossal.
- **Vessel:** Atomic Armageddon.
- **ODM/TS abilities:** Red Flare, Order:Rage, Black Flare, Founder's Order and Titan Shifting.
- **Titan abilities:** Seismic Shock, Heatwave, Incendiary Volley, Tectonic Quake and last slot empty.

This is my loadout, and so far it has been capable of doing the raid and mission on Freedom difficulty with modifiers (Oddball, Injury Prone, Fog, Time Trail), finishing consistently at around 1:30 for the raid and 0:45 for the mission. Yours may be better or worse, you may do it with or without modifiers, and on any difficulty your stats and gear allow.

Should it need tuning, open the script with any text editor and modify it to fit your build.

## Credits
Aotr-Macros by ExRaSc: https://github.com/ExRaSc/Aotr-Macros
