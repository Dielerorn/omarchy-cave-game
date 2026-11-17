#!/usr/bin/env bash
# Download the Cave Game wallpapers from wallhaven.cc and cut each one to
# 3440x1440. The images are fan uploads, so they are not committed here.
#
#   ./fetch-wallpapers.sh                 into ~/.config/omarchy/themes/<theme>/backgrounds
#   ./fetch-wallpapers.sh DIR             into DIR/<theme>/backgrounds
#   ./fetch-wallpapers.sh --force [DIR]   re-cut files that already exist
#
# Downloads are cached in ~/.cache/omarchy-cave-game and checked against the
# SHA-256 recorded below. An image that is gone or has changed is skipped with
# a warning; the rest still install.

set -euo pipefail

FORCE=0
if [[ ${1:-} == "--force" ]]; then FORCE=1; shift; fi
DEST="${1:-$HOME/.config/omarchy/themes}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/omarchy-cave-game"
W=3440
H=1440
UA="omarchy-cave-game/1.0"

say()  { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m warn\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror\033[0m %s\n' "$*" >&2; exit 1; }

for cmd in curl magick sha256sum awk; do
  command -v "$cmd" >/dev/null || die "needs $cmd"
done

# theme  file  wallhaven id  extension  vertical/horizontal bias (0 = top/left)
# resize filter  sha256 of the original
WALLS=(
  "cave-game     01-cave           nzqdvn jpg 0.50 Lanczos e2c21623fb91b0b36141dda6a8c73c6a33e6af80b61345e59f09f09d0665e79c"
  "cave-game     02-sunset         8gd961 png 0.50 Lanczos c522091363766d6a6220ec635409a719155572da28cb65d8ea5326c535910a33"
  "cave-game     03-torchlit-lake  poj7vm png 0.55 Lanczos add4309f90bba9939aa5d27749125e5ba9e0aa3095b3f73d85ca65a0a2183550"
  "cave-game     04-dusk           mlwgvy png 0.40 Lanczos b59d7919335df69b16b7a7556bcd93a2b88f1e1b389b3b5d5f91a40a80cb415d"
  "cave-game     05-creeper-night  01g2r9 png 0.50 Lanczos db85be9b3862f6949d4130ceab3f12e91c61ef8f7efc49fbeaa125ff315ee98a"
  "cave-game     06-moonrise       9dx3xk png 0.55 Lanczos c159531fc1859022f32267bcdce2c3f3a5d4e2d407d7ab9d01ec4e5cba8da6d3"
  "cave-game     07-diamond-ore    2kg5z9 png 0.50 Point   bda5ffee4cd9244f418b24fe54a7b318031f9a11c982c864cbceaef388ab0736"
  "cave-game-day 01-village        r2qzqj png 0.50 Lanczos afc88abd5b66515e7675a0d705df6e73856397e05080fcc4265bc967c6b8feb8"
  "cave-game-day 02-lake           lyg5yr jpg 0.50 Lanczos 745313fe21f8e3d3e88d653a70c6d7a7a48f006cc1e4a9ffa18b48fc1bd65b88"
  "cave-game-day 03-hills          01qg81 jpg 0.55 Lanczos 46d5d0d0c5c79bbfaa68365c98ef4617bcbfc3ba0b86238d4ec869aa3d01bf54"
  "cave-game-day 04-grass-block    nmkek9 jpg 0.00 Point   e0c28ad17220d56d8cd35dd21e0f31d469a32dc1185f71eb51071a64eb01a47e"
  "cave-game-day 05-creeper        nkj9v6 png 0.50 Point   da8f5b6aec264caecd7de206cd036fa5a3d0ec2182b0468f224ec6d4e34dca23"
  "cave-game-day 06-snowy-taiga    7prgv3 png 0.50 Lanczos 0f216d488a21c5f47f1170ed31ac962612f4526d2dc293bba90e521c19c15d8b"
)

mkdir -p "$CACHE"
done_count=0
skipped=()

for row in "${WALLS[@]}"; do
  read -r theme name id ext bias filter sum <<<"$row"
  out="$DEST/$theme/backgrounds/$name.jpg"
  src="$CACHE/wallhaven-$id.$ext"
  url="https://w.wallhaven.cc/full/${id:0:2}/wallhaven-$id.$ext"

  if [[ -f $out && $FORCE == 0 ]]; then
    done_count=$((done_count + 1))
    continue
  fi

  if [[ ! -f $src ]] || ! echo "$sum  $src" | sha256sum -c --status; then
    say "downloading $name"
    if ! curl -fsSL --retry 2 -m 120 -A "$UA" -o "$src.part" "$url"; then
      warn "$name: download failed ($url)"
      rm -f "$src.part"; skipped+=("$name"); continue
    fi
    mv "$src.part" "$src"
    if ! echo "$sum  $src" | sha256sum -c --status; then
      warn "$name: the file at $url has changed since this theme was made; skipping it"
      rm -f "$src"; skipped+=("$name"); continue
    fi
  fi

  # Scale to cover 3440x1440, then crop, sliding the window by $bias along
  # whichever axis has spare pixels.
  read -r w h < <(magick identify -format '%w %h\n' "$src[0]")
  read -r sw sh x y < <(awk -v w="$w" -v h="$h" -v W="$W" -v H="$H" -v b="$bias" 'BEGIN {
    s = (W / w > H / h) ? W / w : H / h
    sw = sprintf("%.0f", w * s); sh = sprintf("%.0f", h * s)
    x = (sw > W) ? sprintf("%.0f", (sw - W) * b) : 0
    y = (sh > H) ? sprintf("%.0f", (sh - H) * b) : 0
    print sw, sh, x, y
  }')

  sharpen=()
  [[ $filter == Lanczos ]] && sharpen=(-unsharp 0x0.8+0.6+0.02)

  mkdir -p "$(dirname "$out")"
  magick "$src[0]" -filter "$filter" -resize "${sw}x${sh}!" "${sharpen[@]}" \
    -crop "${W}x${H}+${x}+${y}" +repage -strip -quality 92 "$out"
  say "$theme/$name.jpg"
  done_count=$((done_count + 1))
done

say "$done_count of ${#WALLS[@]} wallpapers in place under $DEST"
if (( ${#skipped[@]} > 0 )); then
  warn "skipped: ${skipped[*]}"
  exit 2
fi
