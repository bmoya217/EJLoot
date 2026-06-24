# EJ Loot

EJ Loot is a lightweight World of Warcraft addon for tracking missing transmog appearances, mounts, toys, and pets from the Encounter Journal.

I made it because I liked knowing what mogs I still needed from legacy raids, but did not want the load-time cost of a much larger collection tracker. EJ Loot keeps the scope small: it looks at the loot currently available in the Encounter Journal, shows what you are missing, and remembers collectible drops it has seen before.

## Features

- Tracks missing transmog appearances from the current Encounter Journal view.
- Tracks mount drops and shows lockout status by difficulty.
- Remembers mounts, toys, and pets it has seen and shows the selected types when no Encounter Journal instance is selected.
- Prunes collected appearances and collectibles from the list as you learn them.
- Adds a minimap button for quick display controls.
- Can display next to the Adventure Guide or as a movable standalone frame.

## Usage

Open the Encounter Journal and select an instance or encounter. EJ Loot scans the visible loot table and lists missing appearances, mounts, toys, and pets under their bosses.

The minimap button controls the frame:

- Left-click: show or hide EJ Loot.
- Right-click: toggle between Adventure Guide positioning and screen positioning.
- Drag: move the minimap button.

When the frame is in screen mode, drag the frame itself to reposition it.

## How It Works

EJ Loot only scans loot that the Encounter Journal exposes. When no instance is selected, the addon cannot rescan instance loot, so it displays the enabled types of cached collectibles it has seen before and removes collected items as collection events come in. Choose those types from the minimap button's **No instance view** submenu.

## Installation

Copy this folder into your World of Warcraft addons directory:

```text
World of Warcraft/_retail_/Interface/AddOns/EJLoot
```

Then enable **EJ Loot** from the in-game AddOns menu.

## License

MIT. See [LICENSE](LICENSE).
