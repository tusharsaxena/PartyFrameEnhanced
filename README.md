# Ka0s Party Frame Enhanced

![WoW](https://img.shields.io/badge/WoW-Midnight_12.1.0-purple)
![CurseForge Version](https://img.shields.io/curseforge/v/1698335)
![License](https://img.shields.io/badge/License-MIT-orange)
![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)
![Tests](https://img.shields.io/badge/Tests-357%2F357_passing-green)

Party frames show you everyone's health. They don't show you what the healer is halfway through
casting, or which mob the tank actually has targeted. Party Frame Enhanced puts that next to each
party member's frame: a cast bar, a small frame for whatever they're targeting, and one for their pet.

It works with Blizzard's party frames (classic or raid-style) and with EllesmereUI's, and it figures
out which one you're using and attaches itself to it. If you'd rather not tie anything to your party
frames, any of the three can live in its own movable stack instead.

- **Cast bars** change color with the kind of cast, carry a small shield when the cast can't be
  interrupted, and flash red when it gets interrupted.
- **Target frames** show the target's name, health and raid marker, colored by class for players and
  by hostility for everything else. Clicking one targets that unit.
- **Pet frames** show the pet's name, health and raid marker, and a click targets the pet.

## Screenshots

**_Live (in a party)_**

![Live (in a party)](https://media.forgecdn.net/attachments/1951/827/partframeenhanced-screenshot-01-png.png)

**_Unlocked (preview, in a party)_**

![Unlocked (preview, in a party)](https://media.forgecdn.net/attachments/1951/828/partframeenhanced-screenshot-02-png.png)

**_Unlocked (preview, solo)_**

![Unlocked (preview, solo)](https://media.forgecdn.net/attachments/1951/829/partframeenhanced-screenshot-03-png.png)

## Usage

Install it and join a party. Each member gets a cast bar across the top of their frame, a target
frame just to the right, and their pet's frame below that. A unit with no party frame on screen gets
nothing until it has one, which is why your own row doesn't appear in Blizzard's classic party
layout: that layout never shows you.

To move things around, type `/pfe unlock` or untick **Lock frame** on the **General** page. Every bar
and frame fills with made-up data, so you can arrange it all without waiting for a pull. Solo, you
get a stand-in party frame to hang them on. You nudge attached elements with the offset sliders on
each feature's **Size & Position** tab, and drag free-placement stacks wherever you want them. Lock
again and the real data comes back.

**Cast Bars**, **Target Frames** and **Pet Frames** each get their own settings page, with tabs for
size and position, the bar, the border and the text. That's also where you switch a feature to
**Free placement**, and the tab then shows only the settings for the placement you picked. The
**General** page picks which party frames to attach to. Leave it on **Automatic** unless you run
both UIs.

When someone wanders out of range, their cast bar, target frame and pet frame dim along with their
party frame, to whatever opacity that frame uses. Blizzard's classic party frames never dim, so with
those the addon does it for them, at half opacity past about 40 yards. **Fade with party frames** on
the **General** page turns this off.

Target and pet frames are secure buttons, the same kind Blizzard's own unit frames are made of, so
clicking them works in combat. The game also refuses to let any addon move one mid-fight. If someone
joins or leaves during a pull, those frames hide until combat ends and then reappear in the right spot.

Every option is under **Settings → AddOns → Ka0s Party Frame Enhanced**, and typing `/pfe` on its
own takes you there. `/pfe help` (or `/partyframeenhanced help`) prints the full command list.

There is a **minimap button** too. Left-click opens the settings. Right-click opens a small menu with
two checkboxes: **Enabled** turns the addon on or off (the same as `/pfe enable` / `/pfe disable`),
and **Locked** unlocks and re-locks the elements (the same switch as **Lock frame**). While the addon
is off, **Locked** is grayed out until you enable it again. Hover the button to see whether the addon
is enabled and locked; it answers even while the addon is switched off. If you use Titan Panel,
ElvUI's data texts or Bazooka, the addon shows up there as well, and clicking it does exactly the
same thing. To put the
button away, untick **Minimap button** on the **General** page; it stays away on every character and
every profile until you tick it back.

## How it works

1. When your group or your layout changes, the addon checks the party frames on screen and works out
   which frame shows which party member. It only reads them. It never moves, hides or restyles them.
2. Each cast bar, target frame and pet frame gets pinned to the frame showing its party member, or put
   in its feature's stack if that feature is in free placement.
3. Cast bars start and stop on the game's own cast events and animate from the game's cast timer.
   Target frames update the moment a member switches target, and their health refreshes a few times a
   second while they're visible. Pet frames follow the pet's health events.
4. In Midnight, a lot of combat information is hidden from addons. Party Frame Enhanced never tries to
   read it; it passes those values straight to the game to draw, which is why a pull can't break it.

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
| Something looks wrong and you want to report it | Type `/pfe debug on`, reproduce it, then `/pfe debug` to open the log and copy it into your issue. |

## Issues and feature requests

Bugs and feature requests are tracked at
[https://github.com/tusharsaxena/PartyFrameEnhanced/issues](https://github.com/tusharsaxena/PartyFrameEnhanced/issues).
Please file them there rather than in comments. That list is the addon's whole backlog, so anything
filed there gets seen.

## Version History

| Version | Date | Highlights |
|---|---|---|
| 1.0.1 | 2026-09-18 | - Fixed the target frame of someone who joins your party while already targeting something: it stayed blank and red until they changed target, and now fills in with the right name and color straight away. |
| 1.0.0 | 2026-09-18 | - First version: cast bars, target frames and pet frames for your party, attached to Blizzard or EllesmereUI party frames or placed freely. |