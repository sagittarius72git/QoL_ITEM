# QoL Item

A mod that bundles a few handy items.

- **Rope ladder** … hang it from a ledge to climb down, or set it up from below to climb up
- **Homemade water dispenser** … lets you drink water from the fluid grid with Auto Drink
- **Reusable makeshift bandage / antiseptic** … first aid supplies your companions can use any number of times
- **Ankle warmers / wool ankle warmers** … ankle warmth you can wear even with hooves, talons and other mutated feet
- **Mutant plague mask / mutant plague half mask** … gas masks you can wear even with a mutated mouth
- **Small and large cardboard box recipes** … lets you craft the game's own cardboard boxes

**Requires a Lua-enabled build** (`lua_api_version: 2`).

---

## Rope ladder
Crafting menu: Other → Tools

Use it (`a`) and choose one of three options.

- **Lower it from a ledge** … pick an adjacent ledge and it hangs straight down from there, **up to 3 levels** (for climbing down from a roof or cliff).
- **Set it up here** … hang it on an adjacent tile at the same level (for climbing up one level from below, just like a grappling hook). If that tile has no ground, you throw it up onto the edge above and it dangles there.
- **Throw it across a gap** … throw it onto ground farther away at the same level to make a bridge (see below).

Examine the ledge on the upper level to "Pull up", or examine the topmost tile of the rope ladder to "Take it down".
- Use it, choose "Throw it across a gap" and pick a direction. You throw it onto the ground on the other side, **up to 3 tiles away** at the same level, and hook it there. The ladder spans the open air in between, and you can cross it like a bridge.
- **Retrieve any ladder thrown across a gap before you remove this mod.**

## Homemade water dispenser
Crafting menu: Other → Containers

1. Use it, choose "Set up the water dispenser", and place it on an empty floor tile **inside a building with a fluid grid**
2. Mark that tile as an "Auto Drink" zone

It holds up to 1 L of water. Within a minute of running dry, it refills with **clean water** from the fluid grid where it stands (the same map area). It never refills with dirty water. If it is next to a sink, bathtub, shower or tank, it draws from that fixture's grid.
If you get thirsty during a long activity nearby (within 60 tiles on the same level), you drink from it automatically. Examine it to check the water or take it down.

- The game's Auto Drink won't look for a drink again for 30 minutes if it finds none.
- You can't drink from it manually (it is for Auto Drink only).
- If it stands in an area with no fluid grid, it won't fill.

## Reusable makeshift bandage / antiseptic

Both are in the crafting menu under Other → Medical (First aid 1).

| | Materials | Time |
|---|---|---|
| Reusable makeshift bandage | 6 rags (bloody rags also work), 2 short strings or 10 duct tape | 10 minutes |
| Reusable makeshift antiseptic | 1 small or medium tin can (opened ones also work) or glass bottle, 1 rag (bloody also works), 1 dose of antiseptic | 5 minutes |

Put them in a companion's inventory and the companion will use them to treat themselves when hurt. **They never run out, no matter how many times they are used.**

| | Reusable makeshift bandage | Reusable makeshift antiseptic | (For reference) makeshift bandage |
|---|---|---|---|
| Bandage power | 2 | ― | 2 |
| Chance to stop bleeding | 75% | ― | 75% |
| Disinfection (treating bites) | ― | Power 1, 30% | ― |
| Time | 3 seconds | 2 seconds | 3 seconds |

- **The player can't use them** (you'll see a message that it needs at least 1 charge).
- If the companion also carries real bandages and so on, which one gets used is up to the game's AI.
- Companions may also use them to treat you or other companions (they don't run out then either).

## Ankle warmers / wool ankle warmers

Crafting menu: Armor → Feet (Tailoring).

| | Materials | Time |
|---|---|---|
| Ankle warmers | same as socks (2 rags and so on) | 10 minutes |
| Wool ankle warmers | same as wool socks (yarn and so on, Tailoring 1) | 1 hour |
| (Either) from socks you have | 1 pair of socks or wool socks, cutting 1 | 5 minutes |

Warmth and other stats are the same as regular socks and wool socks. You can wear them with hooves, talons, rabbit feet, leg tentacles or the huge mutation.

## Mutant plague mask / mutant plague half mask

Crafting menu: Armor → Head (Tailoring).

| | Materials | Time |
|---|---|---|
| Mutant plague mask | same as a gas mask + 4 leather (or 4 plastic chunks), Tailoring 3, Fabrication 1, wrench | 30 minutes |
| (Same) from a gas mask you have | 1 gas mask, 4 leather (or 4 plastic chunks), Tailoring 2 | 20 minutes |
| Mutant plague half mask | 3 filter masks, 1 hose, 20 charcoal, 3 leather (or 3 plastic chunks), Tailoring 3, Fabrication 1, wrench | 20 minutes |

- Filters and protection are the same as a gas mask (it must be prepared before use). In exchange, encumbrance is a bit higher than a gas mask (30 → 35).
- The half mask covers only the mouth (it doesn't protect your eyes).
- You can wear them with a muzzle, beak, mandibles, proboscis, saber teeth and similar mutations, or the huge mutation.

## Small and large cardboard boxes

Lets you craft these items from the base game. Crafting menu: Other → Containers (Fabrication 1, cutting 1), the same way as the game's own cardboard box recipe.

| | Materials | Time |
|---|---|---|
| Small cardboard box | 18 cardboard, 20 duct tape | 3 minutes |
| Large cardboard box | 130 cardboard, 150 duct tape | 15 minutes |

## Settings

You can change these in `main.lua`.

- Rope ladder: `mod.cfg.max_levels` (maximum number of levels it can hang from a ledge), `mod.cfg.move_cost` (time it takes to lower one level), `mod.cfg.allow_hanging` (whether it can dangle), `mod.cfg.bridge_max_dist` (how far it can be thrown across a gap)
- Homemade water dispenser: `CFG.need_fixture` (`true` restores the old rule that it can only be placed next to a sink or the like), `CFG.fixtures` (sinks and other fixtures), `CFG.refill_charges` (amount per refill)
