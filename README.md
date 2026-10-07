# QoL Item

A mod that bundles a few handy items.

- **Rope ladder** … hang it from a ledge to climb down, or set it up from below to climb up
- **Homemade water dispenser** … lets you drink water from the fluid grid with Auto Drink
- **Reusable makeshift bandage / antiseptic** … first aid supplies your companions can use any number of times
- **Folding laser turret** … an automatic turret you unfold and place. It can be connected to the electric grid

**Requires a Lua-enabled build** (`lua_api_version: 2`).

---

## Rope ladder

Crafting menu: Other → Tools (Fabrication 2, 30 minutes, cutting 1).
Materials: 2 ropes' worth of rope (long rope, makeshift rope, vine or plastic rope; ×10 for short ones), 8 2x4s

Use it (`a`) and choose one of two options.

- **Lower it from a ledge** … pick an adjacent ledge and it hangs straight down from there, **up to 3 levels** (for climbing down from a roof or cliff).
- **Set it up here** … hang it on an adjacent tile at the same level (for climbing up one level from below, just like a grappling hook). If that tile has no ground, you throw it up onto the edge above and it dangles there.

Climbing and retrieving work the same as the game's grappling hook. Examine the ledge on the upper level to "Pull up", or examine the topmost tile of the rope ladder to "Take it down".
It can't be hung into deep water or onto walls, furniture or people (if one is on a level partway down, it stops just above it).

### Two or more levels, and dangling

- When it hangs two or more levels, use `>` and `<` to climb along the rope ladder one level at a time. From the top you can step back onto the ledge as usual.
- Any section above the ground is **dangling**. On any level you can hang on the rope ladder and enter a building through an adjacent window and so on (for sneaking into an upper floor from the roof). If 3 levels don't reach the ground, the bottom is left dangling too.
- Stepping sideways off a rope ladder tile into the air makes you fall.
- Retrieving it takes the whole thing down from the top (it turns back into one rope ladder). If a section partway down is destroyed, everything below it falls.
- **Retrieve any rope ladder that hangs two or more levels or is dangling before you remove this mod.**

## Homemade water dispenser

Crafting menu: Other → Containers (Fabrication 1, 20 minutes, cutting 1).
Materials: 1 gallon jug (or 4 plastic bottles / 1 plastic canteen), 1 rubber hose or leather hose, 2 2x4s or 4 heavy sticks, 20 duct tape or 1 long string

1. Use it, choose "Set up the water dispenser", and place it on an empty floor tile **inside a building with a fluid grid** (it doesn't have to be next to a sink or the like)
2. Mark that tile as an "Auto Drink" zone

It holds up to 1 L of water. Within a minute of running dry, it refills with **clean water** from the fluid grid where it stands (the same map area). It never refills with dirty water. If it is next to a sink, bathtub, shower or tank, it draws from that fixture's grid.
If you get thirsty during a long activity nearby (within 60 tiles on the same level), you drink from it automatically. Examine it to check the water or "Take it down".

- The game's Auto Drink won't look for a drink again for 30 minutes if it finds none.
- In the cold the water inside freezes and can't be drunk. Placing it indoors is recommended.
- You can't drink from it manually (it is for Auto Drink only).
- If it stands in an area with no fluid grid, it won't fill. Examining it shows "There is no clean water in the fluid grid."

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
- The old "makeshift treatment" becomes a **reusable makeshift bandage** as it is. If you also want them to carry the antiseptic, craft a new one.

## Folding laser turret

Crafting menu: Weapons → Ranged (Electronics 5, 2 hours). Like the shoddy laser rifle, you learn it automatically or from electronics books.
Materials: 1 shoddy laser rifle, 1 small storage battery, 7 pipes, 2 tiny electric motors, 1 spring, 1 camera of any kind, 5 electronic scrap, 30 cable, soldering (30). Tools: fine screwdriver, wrench, hacksaw

1. Use it (`a`) to unfold it where you stand (it becomes a one-tile vehicle).
2. Interact with the vehicle on the turret's tile and set the turret's firing mode to **automatic**.
3. It shoots nearby enemies automatically, using power.

- To carry it, **fold** it from the vehicle menu and it turns back into an item (remaining battery charge and damage are kept).
- It runs on its built-in small storage battery. **It is empty the first time you unfold it**, so charge it first.
- To run it from the electric grid, build a "jumper cable connector" in a building with a grid (construction menu: Workshop), then connect it to the turret with a jumper cable. Unplug the cable before folding it.
- The targeting unit can be removed but not put back (nor installed on other vehicles). Without it, the turret can't fire automatically.

## Settings

You can change these in `main.lua`.

- Rope ladder: `mod.cfg.max_levels` (maximum number of levels it can hang from a ledge), `mod.cfg.move_cost` (time it takes to lower one level), `mod.cfg.allow_hanging` (whether it can dangle)
- Homemade water dispenser: `CFG.need_fixture` (`true` restores the old rule that it can only be placed next to a sink or the like), `CFG.fixtures` (sinks and other fixtures), `CFG.refill_charges` (amount per refill)
