#!/usr/bin/env bash
# Cave Game for Omarchy -- installer.
#
#   ./install.sh                     both themes + wallpapers, then apply Cave Game
#   ./install.sh --help              options
#
# Nothing here touches /usr/share/omarchy. The themes land in
# ~/.config/omarchy/themes. If they are already there, the old copies are
# backed up to ~/.local/state/omarchy-cave-game/ first. Backups don't go
# inside the themes folder, because Omarchy would list them as themes.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES="$HOME/.config/omarchy/themes"
BACKUPS="$HOME/.local/state/omarchy-cave-game"
STAMP="$(date +%s)"

APPLY_THEME=cave-game
DO_WALLS=1

say()  { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m warn\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Cave Game for Omarchy

  ./install.sh [options]

  --no-wallpapers   skip downloading the wallpapers (run ./fetch-wallpapers.sh later)
  --theme NAME      apply NAME at the end: cave-game, cave-game-day, or none
  -h, --help        this

Default: install both themes, download and crop the 13 wallpapers, then apply
"cave-game".
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --no-wallpapers) DO_WALLS=0 ;;
    --theme)         APPLY_THEME="${2:-}"; shift ;;
    -h|--help)       usage; exit 0 ;;
    *)               usage; die "unknown option: $1" ;;
  esac
  shift
done

case $APPLY_THEME in
  cave-game|cave-game-day|none) ;;
  *) die "--theme must be cave-game, cave-game-day or none" ;;
esac

mkdir -p "$THEMES"
for theme in cave-game cave-game-day; do
  dest="$THEMES/$theme"
  if [[ -d $dest ]]; then
    mkdir -p "$BACKUPS"
    cp -a "$dest" "$BACKUPS/$theme.$STAMP"
    say "backed up the existing $theme to $BACKUPS/$theme.$STAMP"
  fi
  mkdir -p "$dest"
  # Copy over the top so wallpapers already in backgrounds/ stay put.
  cp -r "$HERE/themes/$theme/." "$dest/"
  find "$dest" -name '__pycache__' -type d -prune -exec rm -rf {} +
  say "installed $theme"
done

if (( DO_WALLS )); then
  "$HERE/fetch-wallpapers.sh" "$THEMES" || warn "some wallpapers did not download; the themes still work"
fi

if [[ $APPLY_THEME != none ]]; then
  if command -v omarchy >/dev/null; then
    omarchy theme set "$APPLY_THEME"
  else
    warn "omarchy is not on PATH; apply it later with: omarchy theme set $APPLY_THEME"
  fi
fi

say "done. Switch between them with: omarchy theme set \"Cave Game\" / \"Cave Game Day\""
