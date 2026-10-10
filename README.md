# Exteros Quality of Life System

A modular Quality of Life system for **Factorio 2.0 and 2.1**. It streamlines the parts of the game that get repetitive, without removing the challenges the factory is built on.

[![Factorio Version](https://img.shields.io/badge/Factorio-2.0+-orange.svg)](https://mods.factorio.com/mod/Exteros-QoL-System) [![Factorio 2.1](https://img.shields.io/badge/Factorio-2.1-orange.svg)](https://mods.factorio.com/mod/Exteros-QoL-System) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Quality of Life Features

Most features ship **disabled by default**; Belt Visualizer, Player Searchlight, Held Item Count and Auto Inventory Sort are on by default. Turn features on or off in the mod settings, or in the in-game Settings Hub for the runtime ones. All hotkeys listed below are defaults and can be rebound in Options > Controls > Mods.

⚙️ **Settings Hub** - A draggable menu for the runtime options. Open it with the QoL shortcut button in the toolbar (next to copy and paste) or with SHIFT + E, close it with Escape. Features are listed on the left, the settings of the selected one on the right. Installed addons that add their own runtime settings get their own entry.

⚙️ **Even Distribution** - Spreads items evenly across several entities in one drag, instead of filling them one at a time. Hold CONTROL and drag across entities: the left button splits what you carry evenly, the right button balances it with what they already hold. Each item goes to the right slot (fuel, ammo, ingredients, modules) and only as much as fits, with optional fuel and ammo limits and a hand-only mode.

⚙️ **Force Insert** - Fast transfer normally stops at a container's red bar limit. This lifts the limit for the duration of the transfer, in open GUIs and while dragging across entities in the world. Machines that would immediately consume the items are held for that moment and restored afterwards.

⚙️ **Belt Brush** - Hold a belt, underground belt, pipe to ground, loader, wall, heat pipe, or inserter, and pick a lane count to paint that many lanes at once. CONTROL + SHIFT + B cycles the shape between straight, corners, and underground or pipe pairs. CONTROL + SHIFT + N cycles through balancers, or the cascade shape for underground belts. Balancers cover every combination from 1 to 8 lanes, plus 16 to 16. The lane count is changed with CONTROL + mouse wheel (or keypad + / −).

⚙️ **Belt Reverser** - Reverses the direction of a whole transport line at once with CONTROL + R, including underground belts and loaders.

⚙️ **Copy Chest** - Moves the entire contents of one container into another. SHIFT + C copies the source, SHIFT + V pastes into the target.

⚙️ **Chest Limit** - While you hold a container, a small window sets how many of its slots stay blocked. Every container of that kind you build afterwards starts that way. CONTROL + mouse wheel (or keypad + / −) changes the value for the held container directly, without opening the window.

⚙️ **Squeak Through** - Lets you walk between pipes, solar panels, and other structures that normally block the gap.

⚙️ **Auto Deconstruct** - Marks miners for deconstruction once they have exhausted the resource under them. It also cleans up what the miner leaves behind (output chests, fuel inserters, unused beacons, pipe gaps), and optionally dead belts and unused poles.

⚙️ **Inventory Repair** - Repairs damaged placeable items in your inventory over time, using repair packs you are carrying.

⚙️ **Time Controls** - Buttons in the top-left corner adjust game speed while you play. In multiplayer, only admins can use them.

⚙️ **Auto Alt Mode** - Turns on Alt mode when you join a game, whether that is a new save, a loaded one, or a multiplayer server. Players can opt out for themselves even while the server has it on.

⚙️ **Auto Inventory Sort** - Sorts chests, cargo wagons, and vehicles when you open them. SHIFT + I sorts an open container by hand.

⚙️ **Held Item Count** - Shows how many of the item in your hand you are carrying, in the centre of the screen; for a blueprint or a ghost, shows how many more times you can build it. Pick the number format in the mod settings.

⚙️ **Player Searchlight** - Turns your character to face the entity you have selected. Flashlight size, intensity, and color can be changed per player; leave them at their defaults and your flashlight stays exactly vanilla.

⚙️ **Wire Shortcuts** - Cycles the wire in your hand between red, green, and copper with ALT + W.

⚙️ **Planner Zapper** - Dropping a blueprint, blueprint book, deconstruction planner, upgrade planner, or selection tool destroys it instead of leaving it on the ground.

⚙️ **Quality Scroll** - Cycles the quality of the item in your cursor with CONTROL + SHIFT + mouse wheel. Requires the Quality DLC.

⚙️ **Renamer** - Opens a small window for renaming the entity under your cursor with CONTROL + SHIFT + R, for anything that carries a name such as a train stop or a roboport.

⚙️ **Player Colors** - Sets your character and chat color from the mod settings.

⚙️ **Rate Calculator** - Select machines with ALT + X or the toolbar shortcut and see what they produce and consume per second, minute or hour, how many belts or inserters that is, and which ingredients limit the output. Works on Factorio 2.0 and 2.1, includes the Space Age machines, and fixes several wrong numbers of the original. Based on Rate Calculator by raiguard and Rate Calculator+ by Kesha.

⚙️ **Ghost Builder** - Hover over a ghost, or over something marked for upgrade, while carrying the right item, and it gets built or upgraded instantly, no need to pick the item up first. CONTROL + SHIFT + G toggles it on and off.

⚙️ **Planner Menu** - Opens a window with every planner and selection tool in the game, vanilla and modded, click one to take it into your hand. Default key to open it is CONTROL + B. The Planner Cycler (ALT + Q / ALT + SHIFT + Q) switches between them without opening the window.

⚙️ **Tape Measure** - Drag a selection to see its width, height, and tile count, drawn on the map and printed to chat. Default key CONTROL + SHIFT + M.

⚙️ **Bottleneck** - Draws a small colored status light on assembling machines, furnaces, rocket silos, and optionally mining drills: green for working, yellow for output full, red for stopped, orange for low or no power. Pure prototype graphics set in data stage, no running cost.

⚙️ **Belt Visualizer** - CONTROL + G over a belt, underground belt, splitter, loader, or linked belt highlights the whole connected line, following through undergrounds and splitters in both directions. Pressing it again on the same line cycles between both lanes, left lane only, right lane only, and off. A toolbar toggle makes the highlight follow whatever belt your cursor is hovering over.

---

## Addons

Optional mods that build on the QoL System. Install them only if you want what they add.

🧪 **[Exteros' QoL System - Cheats](https://mods.factorio.com/mod/Exteros-QoL-Cheats)** - Reach, crafting and mining speed, inventory slots, stack sizes, productivity on every recipe, and roboport range. Cheat Mode used to be part of this mod; since 0.3.3 / 0.4.3 it lives in the addon, so installing the QoL System never changes the balance of your game. Your cheat settings carry over once you install it.

🔧 **[Exteros' QoL System - Tweaks](https://mods.factorio.com/mod/Exteros-QoL-Tweaks)** - Fuel stats, the recycler return rate for quality upcycling, and roboport charging (charging stations that scale with quality, adjustable charging speed). Every tweak has its own switch and nothing changes until you turn it on.

---

## Installation

Install through the in-game mod manager, or download the mod from the [Factorio Mod Portal](https://mods.factorio.com/mod/Exteros-QoL-System).

## Compatibility

- **Factorio 2.0** and **2.1** - released as two rows built from the same source.
- **Space Age**, **Quality**, and **Elevated Rails** - supported.
- **Other mods** - for the features I know have an equivalent on the mod portal, the matching feature here switches itself off automatically, so the two never compete for the same hotkey or the same entity. Not every feature has a conflicting mod on record.
- **Missing a mod?** I can only switch off features for mods I know about, and there are far too many on the mod portal to find them all. If you use a mod that does the same thing as one of my features and both run at once, please [open an issue](https://github.com/pabienko/Exteros-QoL-System/issues) with its name and I will add it.

---

## License & Contact

Developed by **Exteros**, licensed under the MIT License. The Rate Calculator and parts of Even Distribution are based on code by raiguard (Rate Calculator, flib, Even Distribution Lite) and RateCalculatorPlus by Kesha, all MIT.  
Project source: [GitHub Repository](https://github.com/pabienko/Exteros-QoL-System)  
Contact: [GitHub Profile](https://github.com/pabienko)

## Localization

* 🇬🇧 English
* 🇨🇿 Czech
* 🇷🇺 Russian - contributed by [V1ncvega](https://github.com/V1ncvega); settings added since then stay in English until translated

---

## Inspiration & Credits

This mod builds on ideas and mechanics from several mods in the Factorio community. Thanks to their authors:

- **[Even Distribution Lite](https://mods.factorio.com/mod/EvenDistributionLite)** by raiguard - The drag detection and item transfer my Even Distribution is built on.
- **[Even Distribution](https://mods.factorio.com/mod/even-distribution)** by 321freddy - Inspired the fuel and ammo limits and slot routing; this is my own implementation.
- **[Squeak Through 2](https://mods.factorio.com/mod/squeak-through-2)** - For the essential movement improvements.
- **[Auto Deconstruct](https://mods.factorio.com/mod/AutoDeconstruct)** - For the clever automation of exhausted miners; this is my own implementation.
- **[Picker Extended Reborn](https://mods.factorio.com/mod/kry-picker-extended)** - For quality of life features I had not thought of.
- **[Force Inventory Insert](https://mods.factorio.com/mod/force-inventory-insert)** - For the idea of lifting the red bar limit during a fast transfer.
- **[Belt Brush](https://mods.factorio.com/mod/beltbrush2)** - For the idea of painting several belt lanes at once.
- **[Rate Calculator](https://mods.factorio.com/mod/RateCalculator)** by raiguard, forked as **[Rate Calculator +](https://mods.factorio.com/mod/RateCalculatorPlus)** by Kesha - For the production/consumption rate calculator itself.
- **[BottleneckLite](https://mods.factorio.com/mod/BottleneckLite)** by raiguard - Inspired the Bottleneck status lights; this is my own implementation.
- **[belt-visualizer](https://mods.factorio.com/mod/belt-visualizer)** by _CodeGreen - Inspired the Belt Visualizer belt line highlight; this is my own implementation.
- **[Adjustable Flashlight](https://mods.factorio.com/mod/adjustable_flashlight)** by _CodeGreen - Inspired the flashlight settings in Player Searchlight; this is my own implementation.
