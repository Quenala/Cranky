# Cranky

**Author:** Quenala\
**Version:** 2.0\
**Windower:** 4

A lightweight Windower 4 addon that displays the most recent Weapon Skills used, including the player name, job, WS name and damage.

---

## Features

- Shows the last N weapon skills (configurable, default 5)
- Displays player name + job abbreviation (when available)
- Colour-coded damage:
  - **Red** → under 20 000
  - **Orange** → 20 001 – 50 000
  - **Yellow** → 50 001 – 80 000
  - **Teal** → over 80 000
  - **Green** → 99999 (damage cap)
- Short aliases for long WS names (e.g. `Knights of Round` → `KoR`, `Tachi: Fudo` → `Fudo`, `Blade: Shun` → `Shun`)
- Configurable column order
- Draggable GUI (position is saved globally)
- Optional shake effect when someone hits 99999 damage
- Toggle individual columns on/off
- Adjustable font size and number of rows

---

## Installation

1. Download / copy the `Cranky` folder into your Windower `addons` directory:

   ```
   Windower4/addons/Cranky/
   ```
2. Make sure the folder contains at least:
   - `Cranky.lua`
3. Load the addon in-game:

   ```
   //lua load cranky
   ```
4. (Optional) Add it to your `scripts/init.txt` so it loads automatically:

   ```
   lua load cranky
   ```

---

## Commands

All commands start with `//cranky` (or just `//cranky` to see the help).

| Command | Description |
| --- | --- |
| `//cranky toggle name` | Show / hide player names |
| `//cranky toggle ws` | Show / hide weapon skill names |
| `//cranky toggle damage` | Show / hide damage numbers |
| `//cranky order name damage ws` | Set column order (any combination of `name`, `ws`, `damage`) |
| `//cranky order` | Show current column order |
| `//cranky shake` | Toggle the shake effect on 99999 damage |
| `//cranky rows 5` | Set how many WS lines to display (1–20) |
| `//cranky size 11` | Set font size (8–15) |
| `//cranky reset` | Clear the current WS history |
| `//cranky show` | Show the GUI |
| `//cranky hide` | Hide the GUI |

### Examples

```
//cranky order damage name ws
//cranky order name ws damage
//cranky rows 8
//cranky size 12
//cranky shake
```

---

## Column Order

The display order of the three columns can be freely arranged.

**Default:** `name damage ws`

You can change it with the `order` command. The setting is saved globally and persists after reloads / relogs.

---

## WS Aliases

Long weapon skill names are automatically shortened for a cleaner display:

- All **Great Katana** WS → `"Tachi: "` is removed (`Tachi: Fudo` → `Fudo`)
- All **Katana** WS → `"Blade: "` is removed (`Blade: Shun` → `Shun`)
- Many popular WS have short community aliases (e.g. `KoR`, `SB`, `Rudra`, `VS`, `Reso`, `CdC`, etc.)

---

## Shake Effect

When a weapon skill hits the **99999** damage cap, the GUI can briefly shake for 1 second.

- Enabled by default
- Toggle with `//cranky shake`
- The original position is always restored after the shake

---

## Settings

Settings are stored in:

```
Windower4/addons/Cranky/data/settings.xml
```

Position and all options are saved **globally** (same for every character).

You can also edit the defaults directly in `Cranky.lua` if you prefer.

---