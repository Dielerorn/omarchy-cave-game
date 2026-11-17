# Cave Game

Minecraft the way it was in Alpha and Beta, before the big updates. Blocky
clouds, torches in a dark tunnel, a dirt hut by the lake at sunset. "Cave Game"
was the game's first working title.

`cave-game` is the night/underground half. `cave-game-day` is the daytime half.

## Where the colours come from

| token | dark | day | from |
|---|---|---|---|
| `background` | `#201812` | `#C6C6C6` | dirt behind the old menus / the inventory screen's grey |
| `foreground` | `#E0E0E0` | `#373737` | a menu button's label / the GUI's shadow line |
| `accent` | `#7FB238` | `#3F6E15` | the green on top of a grass block |
| `red` | `#E4533F` | `#9E1F14` | TNT, redstone |
| `orange` | `#E8762B` | `#873800` | lava |
| `yellow` | `#F0C23C` | `#6B4E00` | gold |
| `green` | `#7FB238` | `#2D5A0B` | grass, leaves |
| `cyan` | `#4FD2C6` | `#0A5A55` | diamond |
| `blue` | `#5D7DE8` | `#1F35A8` | water |
| `magenta` | `#B068E0` | `#7A2AA6` | the Nether portal |
| `brown` | `#866043` | `#6B4A2E` | dirt, oak log |
| `bright_yellow` (dark) | `#FFFFA0` | | the colour a button label turned under the mouse |

Every ANSI colour in the day half is darkened to read on the grey: at least
4.5:1 for normal colours and 3.5:1 for bright ones.

## Small touches

- **Window border:** a grass block's side, green at the top fading to dirt at the bottom.
- **Tooltips** (`shell.tooltip.toml`, both halves): the in-game item tooltip,
  a near-black violet card with a purple edge and white text.
- **Menu and launcher highlight** (`shell.menu.toml`, `shell.launcher.toml`,
  dark half only): the highlighted row turns the same pale yellow `#FFFFA0`
  as a hovered button in the old menus.
- **Icons:** Yaru-olive.
- **Text cursor:** white (`bright_foreground`), or `#1A1A1A` in the day half.
  If your kitty template sets `cursor_trail_color {{ accent }}`, the trail is
  grass green, darkened to `#3F6E15` by day (3.6:1 on the grey).

## Wallpapers

Thirteen fan screenshots from wallhaven.cc, each cut to 3440×1440. On 16:9 and
32:9 screens Omarchy crops to the middle. They are not part of the repo.
`fetch-wallpapers.sh` (run by `install.sh`) downloads them, checks them against
recorded checksums and crops them. Sources are listed in `CREDITS.md`.

Night: `01-cave`, `02-sunset`, `03-torchlit-lake`, `04-dusk`,
`05-creeper-night`, `06-moonrise`, `07-diamond-ore`.

Day: `01-village`, `02-lake`, `03-hills`, `04-grass-block`, `05-creeper`,
`06-snowy-taiga`.

Minecraft is a trademark of Mojang/Microsoft. This is an unofficial fan theme.

## Rebuilding the preview

`preview.png` is the image the theme picker shows. `forge/backdrop.py` draws a
blocky backdrop: dirt for night, sky over grass for day. `forge/preview.py`
then draws a bar, a terminal, the palette and a menu on top of it, all in the
theme's `colors.toml` colours. Run both again after changing a palette (they
need Python 3, ImageMagick and Pango):

    cd themes/cave-game/forge
    python3 backdrop.py night /tmp/night.png
    python3 backdrop.py day   /tmp/day.png
    python3 preview.py ../ /tmp/night.png ../preview.png
    python3 preview.py ../../cave-game-day /tmp/day.png ../../cave-game-day/preview.png
