# Ka0s Party Frame Enhanced

![WoW](https://img.shields.io/badge/WoW-Midnight_12.1.0-purple)
![CurseForge Version](https://img.shields.io/curseforge/v/1698335)
![License](https://img.shields.io/badge/License-MIT-orange)
![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)
![Tests](https://img.shields.io/badge/Tests-407%2F407_passing-green)

Party frames show you everyone's health. They don't show you what the healer is halfway through
casting, or which mob the tank actually has targeted. Party Frame Enhanced puts that next to each
party member's frame: a cast bar, a small frame for whatever they're targeting, and one for their pet.

It works with Blizzard's party frames (classic or raid-style) and with EllesmereUI's. It figures out
which one you're using and attaches to it. If you'd rather not tie anything to your party frames, any
of the three can live in its own movable stack instead.

- Cast bars change color with the kind of cast. They show a small shield when the cast can't be
  interrupted, and flash red when someone interrupts it.
- Target frames show the target's name, health and raid marker. Players are colored by class and
  everything else by hostility. Click one to target that unit.
- Pet frames show the pet's name, health and raid marker, and clicking one targets the pet.

## Screenshots

**_Live (in a party)_**

![Live (in a party)](https://media.forgecdn.net/attachments/1951/827/partframeenhanced-screenshot-01-png.png)

**_Unlocked (preview, in a party)_**

![Unlocked (preview, in a party)](https://media.forgecdn.net/attachments/1951/828/partframeenhanced-screenshot-02-png.png)

**_Unlocked (preview, solo)_**

![Unlocked (preview, solo)](https://media.forgecdn.net/attachments/1951/829/partframeenhanced-screenshot-03-png.png)

## Usage

Install it and join a party. Each member gets a cast bar across the top of their frame, a target
frame just to the right, and their pet's frame below that. Everything starts locked. Type
`/pfe unlock`, or untick **Lock frame** on the **General** page, and every bar and frame fills with
made-up data so you can see what you're arranging. Solo, you get a stand-in party frame to hang them
on. `/pfe lock` brings the real data back. It won't unlock in combat, and a pull locks it for you.

Setting it up the way you like takes three steps. The **Cast Bars**, **Target Frames** and
**Pet Frames** pages are laid out the same way, so you do each step once per feature.

1. Pick what you want. The first box on each page's **General** tab turns that feature on or off,
   so switch off anything you don't need. The **General** page decides whether you get a row for
   yourself too (**Include my own row**) and which party frames to attach to. Leave **Frame system** on
   **Automatic** unless you run both Blizzard's frames and EllesmereUI's.
2. Place each feature on its **Size & Position** tab. Attached, it sits on each party frame, and
   the anchor points and X and Y offsets nudge it into place. Switch **Anchor mode** to **Free
   placement** and all five go in one stack you drag wherever you want, with a growth direction and
   spacing. The tab only shows the settings for the mode you picked.
3. Make it look right. The **Bar**, **Border** and **Text** tabs hold the textures, colors and
   fonts. Cast bars get a color for each kind of cast, target frames can color NPCs by how they
   feel about you, and target and pet frames have a **Marker** tab for the raid marker.

When someone wanders out of range, their cast bar, target frame and pet frame dim with their party
frame. The minimap button opens the settings on a left click, and a right click gives you
**Enabled** and **Locked** switches. You can hide it on the **General** page.

Everything else is under Settings → AddOns → Ka0s Party Frame Enhanced, which `/pfe` opens, and
`/pfe help` (or `/partyframeenhanced help`) lists every command.

## How it works

In Midnight, a lot of what a party member is doing is secret to addons, a cast's name and timing
included. An addon can hand those values to the game to draw, but it can't read them. Party Frame
Enhanced is built around that, so a pull can't break it.

1. When your group or your layout changes, the addon checks the party frames on screen and works out
   which frame shows which party member. It only reads them. It never moves, hides or restyles them.
2. Each cast bar, target frame and pet frame gets pinned to the frame showing its party member, or put
   in its feature's stack if that feature is in free placement.
3. Cast bars start and stop on the game's own cast events. The bar gets the game's cast timer as it
   is and the game runs the countdown, so the addon never reads the time left. Target frames update
   the moment a member switches target, and their health refreshes a few times a second while
   they're visible. Pet frames follow the pet's health events.

## FAQ

| Question | Answer |
|---|---|
| Does it replace my party frames? | No. It adds to them and never moves, hides or restyles them. |
| Does it work in raids? | No, and that's on purpose. It's party-only: in a raid, or solo, it shows nothing. |
| Does it work with ElvUI, Cell or Grid2? | Not as an attachment yet. Use free placement, which works with any setup. |
| Why can't it hide the target frame when a party member targets me? | The game hides "is that you?" from addons in combat, so the addon has no way to tell. |
| Do I need EllesmereUI? | No. It's optional; without it the addon uses Blizzard's frames. |

## Troubleshooting

| Symptom | Fix |
|---|---|
| Nothing shows next to my party frames | Type `/pfe status`. It tells you which party frames the addon found, which members have a frame, and whether something is switched off. The usual culprits are **General visibility** set to **Never** or the wrong **Frame system** on the **General** page. Solo or in a raid, nothing shows on purpose; `/pfe unlock` shows you what it would look like. |
| My own row is missing | Blizzard's classic party layout doesn't show you. Use the raid-style layout, EllesmereUI, or free placement. |
| Target or pet frames are missing after someone joined mid-fight | They come back when combat ends. The game doesn't let addons move clickable frames in combat. |
| The settings panel won't open, or it's grayed out | It locks in combat on purpose. Try again once combat ends. |
| Something looks wrong and I want to report it | Follow [Reporting a bug](#reporting-a-bug) below. |

## Reporting a bug

1. Type `/pfe debug on` and reproduce the bug.
2. Type `/pfe diagnostics`.
3. If the debug window isn't open, open it with `/pfe debug`. Press **Copy**, copy the entire output, and include it with your bug report.

The diagnostics report goes in below the debug trace, in the same window, so one copy gets you both.

## Issues and feature requests

I track bugs and feature requests at
[https://github.com/tusharsaxena/PartyFrameEnhanced/issues](https://github.com/tusharsaxena/PartyFrameEnhanced/issues).
Please file them there rather than in comments. That list is the addon's whole backlog, so anything
you file there gets seen.

## Version History

| Version | Date | Highlights |
|---|---|---|
| 1.1.0 | 2026-09-27 | - When a party member is out of range, their cast bar, target frame and pet frame fade with their party frame. Turn off **Fade with party frames** if you'd rather they didn't.<br>- Raid markers draw above the border, pet frames get their own raid marker, and the marker sits at the top of the bar by default.<br>- The minimap button's tooltip shows whether the addon is enabled and locked. Left-click opens settings, and right-click gives you Enabled and Locked switches.<br>- `/pfe diagnostics` writes a report to paste into a bug report, and the README has a new "Reporting a bug" section.<br>- The Size & Position tab only shows the settings for the placement you picked, and the settings panel stays locked during combat. |
| 1.0.1 | 2026-09-18 | - Fixed the target frame of someone who joins your party while already targeting something: it stayed blank and red until they changed target, and now fills in with the right name and color straight away. |
| 1.0.0 | 2026-09-18 | - First version: cast bars, target frames and pet frames for your party, attached to Blizzard or EllesmereUI party frames or placed freely. |

## Credits

The debug console uses [JetBrains Mono](https://www.jetbrains.com/lp/mono/), licensed under the SIL
Open Font License 1.1. It ships inside the bundled LibKa0s payload, with its license text beside it.
