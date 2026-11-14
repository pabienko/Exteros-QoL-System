# Exteros' QoL

A modular Quality of Life system for **Factorio 2.1**. Streamlines the repetitive parts of the game without removing the challenge.

[![Factorio 2.1](https://img.shields.io/badge/Factorio-2.1-orange.svg)](https://mods.factorio.com/mod/Exteros-QoL-System) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Quality of Life Features

Most features are **disabled by default**; Belt Visualizer, Player Searchlight, Held Item Count and Auto Inventory Sort are on. Admins can switch any feature on or off anytime in Exteros' Hub, no restart needed. Hotkeys below are defaults, rebindable in Options > Controls > Mods.

⚙️ **Exteros' Hub** - Settings window for every installed Exteros mod. Toolbar button or SHIFT + E, close with Escape. Export/import the settings as one line of text.

⚙️ **Even Distribution** - CONTROL + drag across entities: left button splits what you carry evenly, right balances it with what they hold. Optional fuel/ammo limits and a hand-only mode.

⚙️ **Force Insert** - Lifts a container's red bar limit during a fast transfer.

⚙️ **Belt Brush** - Hold a belt, underground belt, pipe to ground, loader, wall, heat pipe or inserter to paint several lanes at once. CONTROL + SHIFT + B cycles shape, CONTROL + SHIFT + N cycles balancers, CONTROL + mouse wheel sets the count.

⚙️ **Belt Reverser** - CONTROL + R reverses a whole transport line, undergrounds and loaders included.

⚙️ **Copy Chest** - SHIFT + C copies a container, SHIFT + V pastes it.

⚙️ **Chest Limit** - While holding a container, set how many slots stay blocked for new ones built after. CONTROL + mouse wheel adjusts it directly.

⚙️ **Squeak Through** - Walk through pipes, solar panels and other gap-blocking structures.

⚙️ **Auto Deconstruct** - Marks depleted miners for deconstruction and cleans up around them (chests, inserters, beacons, pipe gaps, optionally belts and poles).

⚙️ **Inventory Repair** - Repairs damaged placeable items in your inventory with carried repair packs.

⚙️ **Time Controls** - Top-left buttons adjust game speed, admin-only in multiplayer.

⚙️ **Auto Alt Mode** - Turns on Alt mode when you join; players can opt out.

⚙️ **Auto Inventory Sort** - Sorts chests, wagons and vehicles on open. SHIFT + I sorts by hand.

⚙️ **Held Item Count** - Shows how many of the held item you carry, centre screen. For a blueprint or ghost: how many more times you can build it.

⚙️ **Player Searchlight** - Turns your character to face the selected entity. Flashlight size, intensity and color are server-wide settings.

⚙️ **Wire Shortcuts** - ALT + W cycles the held wire between red, green and copper.

⚙️ **Planner Zapper** - Dropping a planner, blueprint or selection tool destroys it instead of leaving it behind.

⚙️ **Quality Scroll** - CONTROL + SHIFT + mouse wheel cycles the cursor item's quality. Requires Quality DLC.

⚙️ **Renamer** - CONTROL + SHIFT + R renames the entity under your cursor.

⚙️ **Player Colors** - Sets your character and chat color in the mod settings.

⚙️ **Rate Calculator** - ALT + X (or toolbar) shows what selected machines produce/consume per second, minute or hour, the belts/inserters needed, and the limiting ingredient. Works with Space Age. Based on Rate Calculator by raiguard and Rate Calculator+ by Kesha.

⚙️ **Ghost Builder** - Hover a ghost or upgrade-marked entity with the right item to build it instantly. CONTROL + SHIFT + G toggles it.

⚙️ **Planner Menu** - CONTROL + B opens a window with every planner and selection tool; click one to take it. ALT + Q / ALT + SHIFT + Q cycles without the window.

⚙️ **Tape Measure** - CONTROL + SHIFT + M, then drag to see width, height and tile count.

⚙️ **Bottleneck** - Status light on machines, optionally mining drills: green working, yellow full, red stopped, orange low/no power.

⚙️ **Belt Visualizer** - CONTROL + G on a belt highlights everything feeding into it and everything it feeds. Press again to cycle both lanes, left only, right only, off. A toolbar toggle follows the cursor.

---

## Other Mods

🧪 **[Exteros' Cheats](https://mods.factorio.com/mod/Exteros-QoL-Cheats)** - Reach, crafting and mining speed, inventory slots, stack sizes, productivity on every recipe, and roboport range.

🔧 **[Exteros' Tweaks](https://mods.factorio.com/mod/Exteros-QoL-Tweaks)** - Fuel stats, the recycler return rate for quality upcycling, and roboport charging.

---

## Installation

Install through the in-game mod manager, or from the [Factorio Mod Portal](https://mods.factorio.com/mod/Exteros-QoL-System). [Exteros' Lib](https://mods.factorio.com/mod/exteros-lib) comes with it as a dependency.

## Compatibility

- **Factorio 2.1** only.
- **Space Age**, **Quality**, and **Elevated Rails** - supported.
- **Other mods** - the matching feature switches itself off for conflicting mods I know of, so they never compete for the same hotkey or entity. Not every feature has one on record.
- **Missing a mod?** If one does the same thing as a feature here and both run at once, please [open an issue](https://github.com/pabienko/Exteros-QoL-System/issues) with its name.

---

## License & Contact

Developed by **Exteros**, licensed under the MIT License. Rate Calculator and parts of Even Distribution are based on code by raiguard (Rate Calculator, flib, Even Distribution Lite) and RateCalculatorPlus by Kesha, all MIT.  
Project source: [GitHub Repository](https://github.com/pabienko/Exteros-QoL-System)  
Contact: [GitHub Profile](https://github.com/pabienko)

## Localization

* 🇬🇧 English
* 🇨🇿 Czech
* 🇷🇺 Russian - contributed by [V1ncvega](https://github.com/V1ncvega); new settings stay in English until translated

---

## Inspiration & Credits

Thanks to the authors of these mods for the ideas this one builds on:

- **[Even Distribution Lite](https://mods.factorio.com/mod/EvenDistributionLite)** by raiguard - drag detection and item transfer this is built on.
- **[Even Distribution](https://mods.factorio.com/mod/even-distribution)** by 321freddy - inspired the fuel/ammo limits and slot routing (own implementation).
- **[Squeak Through 2](https://mods.factorio.com/mod/squeak-through-2)** - for the movement improvements.
- **[Auto Deconstruct](https://mods.factorio.com/mod/AutoDeconstruct)** - inspired automating exhausted miners (own implementation).
- **[Picker Extended Reborn](https://mods.factorio.com/mod/kry-picker-extended)** - for features I hadn't thought of.
- **[Force Inventory Insert](https://mods.factorio.com/mod/force-inventory-insert)** - inspired lifting the red bar limit during a fast transfer.
- **[Belt Brush](https://mods.factorio.com/mod/beltbrush2)** - inspired painting several belt lanes at once.
- **[Rate Calculator](https://mods.factorio.com/mod/RateCalculator)** by raiguard, forked as **[Rate Calculator +](https://mods.factorio.com/mod/RateCalculatorPlus)** by Kesha - the rate calculator itself.
- **[BottleneckLite](https://mods.factorio.com/mod/BottleneckLite)** by raiguard - inspired the Bottleneck status lights (own implementation).
- **[belt-visualizer](https://mods.factorio.com/mod/belt-visualizer)** by _CodeGreen - inspired Belt Visualizer (own implementation).
- **[Adjustable Flashlight](https://mods.factorio.com/mod/adjustable_flashlight)** by _CodeGreen - inspired the flashlight settings (own implementation).
