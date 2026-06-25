# EJ Loot

EJ Loot is a small World of Warcraft addon for finding missing loot from the Adventure Guide.

It scans the Encounter Journal view you are looking at and lists missing transmog appearances, mounts, toys, and pets in a compact frame. The goal is to answer one narrow question quickly: what can I still collect from this instance?

## Features

- Shows missing transmog appearances from the current Encounter Journal loot table.
- Tracks collectible mount, toy, and pet drops discovered while browsing instance loot.
- Keeps remembered collectibles available even when no instance is selected.
- Removes collected appearances and collectibles as collection updates are received.
- Shows instance lockout status for tracked mount drops where available.
- Supports an Adventure Guide anchored frame or a movable standalone frame.
- Includes a minimap button, slash commands, and an addon options panel.
- Lets you hide individual tracked mounts, toys, and pets you no longer want listed.

## Usage

Open the Adventure Guide, choose an instance or encounter, and EJ Loot will list the missing items it can see from that Encounter Journal loot table.

The minimap button provides the quickest controls:

- Left-click to show or hide the EJ Loot frame.
- Right-click to open quick options.
- Drag to move the minimap button.

The options panel includes display settings, minimap visibility, which collectible types appear when no instance is selected, and per-item tracking for discovered mounts, toys, and pets.

Slash commands are also available:

```text
/ejloot
/ejl
```

Use `/ejloot help` in chat to see the available command options.

## Notes

EJ Loot only knows about loot that the Encounter Journal exposes. If an item has not appeared in a scanned Encounter Journal loot table yet, EJ Loot cannot track it until you browse that loot in game.

Remembered collectibles are stored locally in saved variables. Collected items are pruned automatically, and hidden tracked collectibles can be restored from the options panel.

## License

MIT. See [LICENSE](LICENSE).
