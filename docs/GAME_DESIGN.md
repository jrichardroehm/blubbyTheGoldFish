# Game Design Document: Blubby the Goldfish

## Overview

Blubby the Goldfish is a 2D pixel art **exploration/open-world game** where players control a goldfish named Blubby swimming through a large, hand-crafted underwater map. The objective is three-fold:

1. Explore a large open map — roughly **3 minutes to swim edge-to-edge**, and about **1 minute to swim to the surface** on the first map.
2. Discover and enter points of interest scattered across the map (a sunken ship, a cave, and other hidden locations), each offering an "inside look" and unique characters to interact with (e.g., a crab, Davy Jones).
3. Complete the map's side quests to reach the win condition.

This is a passion project for the team, built primarily to nail the ascending/descending buoyancy mechanics as a testbed for a future, more ambitious diving game.

> Note: An earlier version of this design centered on a "chase" mechanic with a net antagonist. That concept has been shelved in favor of the open-world exploration design above.

---

## Storyline

- **Opening:** Blubby starts out as a house pet in a fishbowl/tank. The game begins with Blubby getting **flushed down the toilet**, a comedic, unceremonious send-off, and this is how he ends up in the open sea.
- This origin frames the whole game as Blubby adjusting to (and exploring) his new world, and sets up the tone for the "forgetting" loop mechanic at the end: Blubby is a goldfish who forgets things easily, starting with how he got here in the first place.
- The exact framing of the flush (cutscene vs. playable intro sequence) and how much backstory is shown before/after are still open for Patrick to design.

---

## Game Summary

- **Genre:** Exploration / Open World / Adventure
- **Target Audience:** Casual players, retro/pixel art enthusiasts, exploration-game fans
- **Platform:** PC (Windows/Linux) first, with **web as the next planned port, followed by mobile (iOS/Android)** — design decisions should avoid choices that would make porting difficult later.
- **Game Engine:** Godot
- **Monetization:** None planned. This is being built for the team's own learning and enjoyment, and as a precursor project to a future diving game.

---

## Core Gameplay Mechanics

### 1. Player Movement

- Players control Blubby using arrow keys or WASD.
- Blubby swims left/right with smooth acceleration and deceleration.
- Vertical movement (up/down) is controlled by a **buoyancy mechanic**, now with depth-based water pressure (see Technical Details below).
- **Hardcore mode** (manual tail-flap controls, tapping left/right to swim) will launch **as an optional toggle at launch** (not held back for post-launch), since it's already abstracted out from core movement.

### 2. World Exploration

- The first map is large enough to take ~3 minutes to cross horizontally and ~1 minute to reach the surface from the bottom.
- The map contains discoverable locations Blubby can swim into for an "inside look," including:
  - A sunken ship
  - A cave
  - A coral reef
  - An underwater cavern system (a deeper, connected network beyond the single cave)
  - A sunken town/ruins
  - A kelp forest
  - Other hidden/secret locations (TBD)
- These locations contain interactable characters, such as:
  - A crab
  - Davy Jones
  - An octopus
  - A sea turtle (potential friendly guide/mentor character)
  - An eel (mysterious/slightly menacing, fits darker areas like caves)
  - (Potential) other sea creatures
- A **beta fish** lurks passively in the background throughout the map: an ambient presence rather than an active threat, adding atmosphere and a sense of "not being alone" in the water.

### 3. Win Condition

- Players win by completing all side quests on the map — targeting **3-5 side quests** for the first map (a short, tight loop appropriate for a first playable/testbed build).
- Upon completion, the game "resets" narratively: Blubby forgets everything (a goldfish-memory joke baked into the story) and the loop begins again.
- The forgetting beat should play **comedic and lighthearted** — leaning into goldfish-memory jokes and silly dialogue on reset, rather than a heavier or more mysterious tone.

### 4. Scoring / Progression

- Traditional arcade scoring (points for pellets) is de-emphasized in favor of quest/discovery-based progression.
- Food pellets (as an arcade collectible) are **cut** — there's no net-chase pressure driving that urgency anymore.
- The team is open to some other food-related mechanic (not pellets) to give Blubby something to interact with while exploring. Concept TBD.

### 5. Removed/Shelved Mechanics

The following mechanics from the original arcade concept are **shelved for now**:
- The chasing net antagonist
- Net-based difficulty progression (net speed scaling with score)
- Beta fish as something the net can "catch" (beta fish is now a background ambient character instead)

---

## Art and Style

### Visual Style

- Pixel art aesthetic targeting a **Stardew Valley level of pixel density** — modern, clean, and higher-detail than chunky SNES-era games like Final Fantasy V.
- **Grid density has been decided at 64x64** (tile/grid unit size). All tile-based assets and level layout should be built to this grid.
- Parallax backgrounds for depth throughout the open water.
- Smooth animations for Blubby and other characters.

### Key Assets

- Blubby sprite (idle, swimming in all directions).
- Sunken ship, cave, coral reef, cavern system, sunken town/ruins, kelp forest, and other location interiors.
- Character sprites: crab, Davy Jones, octopus, sea turtle, eel, beta fish (ambient/background), and other creatures TBD.
- Water/depth layering to visually communicate pressure and depth.
- UI elements (quest tracker, depth indicator, etc.). **Visual style/approach left to Patrick as lead designer**.

---

## Audio Design

### Music

- Upbeat, retro-inspired soundtrack (chiptune-influenced).
- Distinct tracks for menus, general exploration, and location-specific themes (e.g., ship, cave).
- Ambient/atmospheric music for deep or unique areas (replacing the old "net chase" intensity track).

### Sound Effects

- Splashing sounds when Blubby swims.
- Unique sounds for eating food / discovering locations.
- Ambient underwater sound design to reinforce depth and pressure.

---

## Technical Details

### Buoyancy & Depth Pressure Mechanic

The vertical movement mechanic is being reworked to incorporate **depth-based water pressure**:

- As Blubby swims deeper, water pressure increases, which **decreases buoyancy**. Blubby will naturally start sinking at depth and must actively inflate to ascend.
- Conversely, as Blubby ascends, pressure decreases, which **increases buoyancy**, meaning Blubby will ascend faster the closer to the surface they get, requiring the player to manage/counteract this to avoid shooting upward uncontrollably.
- This creates a "control window" the player must manage: too little air and you sink, too much air near the surface and you rocket up.
- The original placeholder equation (`y = x³` buoyancy based on fluid density, displaced volume, and gravity) will need to be extended to factor in a depth/pressure term. **This needs prototyping and playtesting to tune correctly** — treat original values as a starting point, not final.
- Buoyancy tuning will happen **alongside content development** rather than as a gating prototype phase — iterate on the mechanic while the map and locations are being built out in parallel.

### Game Engine

- **Godot**, .NET 6.0 SDK
- Use Godot's 2D capabilities for parallax, smooth animation, and physics-driven buoyancy.

### File Structure

```
Project (blubbyTheGoldFish)
├── Level (open world map)
│   ├── Locations
│   │   ├── SunkenShip
│   │   ├── Cave
│   │   ├── CoralReef
│   │   ├── CavernSystem
│   │   ├── SunkenTown
│   │   ├── KelpForest
│   │   └── (other TBD locations)
├── Gui (pause menu, start menu, quest tracker)
├── Player
├── Characters
│   ├── Crab
│   ├── DavyJones
│   ├── Octopus
│   ├── SeaTurtle
│   ├── Eel
│   └── BetaFish (ambient)
├── Game (start-up file)
└── Audio
    ├── Music (menu, exploration, location themes)
    └── SFX
```

### Resolution

- **Grid density: 64x64.** Tile/grid unit size is decided; targeting Stardew Valley-comparable pixel density overall.

### Controls

- Keyboard (arrow keys/WASD).
- Optional gamepad support.
- Design with browser/web input in mind first (next planned port), then mobile touch controls for the port after that.

---

## Game Loop

1. **Start Screen:** Players press a key to start.
2. **Gameplay:**
   - Blubby explores the open map, managing depth via the buoyancy/pressure mechanic.
   - Blubby discovers and enters locations (sunken ship, cave, etc.) and interacts with characters found there.
   - Side quests are completed progressively.
3. **End/Loop Screen:**
   - Once all side quests are complete, the game "resets" — Blubby forgets, and the player begins the loop again.

---

## Team Roles

- **Lead Designer:** Patrick
- **Lead Software Engineer / Developer:** [Your Name] (jrich)
- **Music/SFX:** James

---

## Open Questions / TBD

- Full design of the 3-5 side quests (what each involves, which locations they're tied to)
- What non-pellet food/interaction mechanic (if any) Blubby should have while exploring
- UI design for quest tracking and depth/pressure indication (left to Patrick)
- Exact framing of the toilet-flush opening (cutscene vs. playable intro, how much backstory to show)
- Depth-pressure buoyancy formula (needs prototyping/tuning, in parallel with content work)
- Any additional hidden/secret locations beyond the six now listed

---

## Summary

Everything above serves two goals at once: a short, playable exploration game, and a proving ground for the buoyancy/depth-pressure mechanic the team wants to carry into a future, more ambitious diving game. If a decision doesn't clearly serve one of those two goals, it's probably scope creep for this first map.
