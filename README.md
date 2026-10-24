# QoL Item

A mod that bundles a few handy items. Requires a Lua-enabled build (`lua_api_version: 2`).

## Rope ladder
Crafting: Other → Tools. Use it (`a`) and choose:
- Lower it from a ledge: hangs straight down from an adjacent ledge, up to 3 levels.
- Set it up here: hang it on an adjacent tile to climb up one level. With no ground there, it dangles in the air.
- Throw it across a gap: throw it onto ground up to 3 tiles away at the same level to make a bridge.

Examine the ledge to "Pull up", or the topmost tile to "Take it down". Retrieve any ladder thrown across a gap before you remove this mod.

## Homemade water dispenser
Crafting: Other → Containers. Place it on a floor inside a building with a fluid grid, then mark that tile as an "Auto Drink" zone.
- Refills itself with up to 1 L of clean water from the fluid grid (never dirty water).
- When you get thirsty during an activity nearby (within 60 tiles on the same level), you drink from it automatically. You can't drink from it manually.

## Reusable makeshift bandage / antiseptic
Crafting: Other → Medical (First aid 1). Give them to a companion and the companion uses them for first aid. They never run out, and the player can't use them.
- Bandage: same as a makeshift bandage (power 2, 75% to stop bleeding).
- Antiseptic: disinfects bites (power 1, 30%).

## Ankle warmers / wool ankle warmers
Crafting: Armor → Feet. Same stats as socks / wool socks, and you can wear them with hooves, talons, leg tentacles, the huge mutation and similar. They can also be made from socks you have.

## Mutant plague mask / mutant plague half mask
Crafting: Armor → Head. Same stats as a gas mask (encumbrance 35), and you can wear them with a muzzle, beak, mandibles or other mouth mutations, or the huge mutation. The half mask covers only the mouth. The full mask can also be made from a gas mask you have.

## Small and large cardboard boxes
Lets you craft the game's own cardboard boxes under Other → Containers.

## Settings
Change them in `main.lua`: `mod.cfg` (rope ladder) and `CFG` (water dispenser).

<!-- Assisted-by: Claude:claude-opus-5-5 -->
