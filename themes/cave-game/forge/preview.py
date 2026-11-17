#!/usr/bin/env python3
"""Compose a theme-picker preview: wallpaper, bar, a terminal and a menu,
all drawn in the theme's colors.toml palette."""
import re, subprocess, sys, tempfile, os, html

theme_dir, wallpaper, out = sys.argv[1:4]
c = {}
for line in open(os.path.join(theme_dir, "colors.toml")):
    m = re.match(r'\s*(\w+)\s*=\s*"(#[0-9A-Fa-f]{6})"', line)
    if m:
        c[m[1]] = m[2]
menu_sel = c["accent"]
mp = os.path.join(theme_dir, "shell.menu.toml")
if os.path.exists(mp):
    m = re.search(r'selected-text\s*=\s*"(#[0-9A-Fa-f]{6})"', open(mp).read())
    if m:
        menu_sel = m[1]
border_top = c["accent"]
border_bot = "#866043"
FONT = "IosevkaTermSlab Nerd Font"
W, H = 2560, 1440
tmp = tempfile.mkdtemp()

def span(text, color=None, bold=False):
    t = html.escape(text)
    attrs = f' foreground="{c[color]}"' if color else ""
    if bold:
        attrs += ' weight="bold"'
    return f"<span{attrs}>{t}</span>" if attrs else t

def pango(markup, path, size, fg, bg, width=None):
    cmd = ["magick", "-background", bg, "-fill", fg, "-density", "72"]
    if width:
        cmd += ["-size", f"{width}x"]
    cmd += [f"pango:<span font_family=\"{FONT}\" size=\"{size*1024}\">{markup}</span>", path]
    subprocess.run(cmd, check=True)

P = lambda *a: "".join(a)
prompt = P(span("~/world", "blue", True), " ", span("❯", "green", True), " ")
term = "\n".join([
    P(prompt, "ls"),
    P(span("region/", "blue", True), "  ", span("screenshots/", "blue", True), "  level.dat  ", span("start.sh", "green", True), "  ", span("session.lock", "muted")),
    P(prompt, "git log --oneline -4"),
    P(span("a1f3c09", "yellow"), " ", span("(HEAD, main)", "cyan"), " Dig the stairs down to bedrock"),
    P(span("7c2e5b1", "yellow"), " Light the long tunnel every 8 blocks"),
    P(span("e90d44a", "yellow"), " Fence the sheep in before nightfall"),
    P(span("31b8f7e", "yellow"), " First night: dirt hut by the lake"),
    "",
    P(span("-- the torch rule", "muted")),
    P(span("local", "magenta"), " ", span("LIGHT", "orange"), " = ", span("14", "orange")),
    P(span("function", "magenta"), " ", span("place_torch", "blue"), "(world, x, y, z)"),
    P("  ", span("if", "magenta"), " world:", span("is_dark", "blue"), "(x, y, z) ", span("then", "magenta")),
    P("    world:", span("set", "blue"), "(x, y, z, ", span('"torch"', "green"), ")"),
    P("  ", span("end", "magenta")),
    P(span("end", "magenta")),
    "",
    P(span("! ", "red", True), span("A creeper is nearby", "red"), span("  ·  ", "muted"), span("diamonds: ", "foreground"), span("3", "bright_cyan", True)),
    P(prompt, span("█", "bright_foreground")),
])
pango(term, f"{tmp}/term.png", 26, c["foreground"], c["background"])

swatches = []
for k in ["red", "orange", "yellow", "green", "cyan", "blue", "magenta", "brown"]:
    swatches.append(f"{tmp}/sw_{k}.png")
    subprocess.run(["magick", "-size", "64x64", f"xc:{c[k]}", swatches[-1]], check=True)
for k in ["bright_red", "bright_yellow", "bright_green", "bright_cyan", "bright_blue", "bright_magenta", "muted", "foreground"]:
    swatches.append(f"{tmp}/sw_{k}.png")
    subprocess.run(["magick", "-size", "64x64", f"xc:{c[k]}", swatches[-1]], check=True)
subprocess.run(["montage", *swatches, "-tile", "8x2", "-geometry", "64x64+6+6", "-background", c["background"], f"{tmp}/swatch.png"], check=True)

menu_rows = ["Apps", "Learn", "Trigger", "Style", "Setup", "Install", "System"]
rows = []
for i, r in enumerate(menu_rows):
    if i == 3:
        rows.append(f'<span foreground="{menu_sel}">  {html.escape(r)}</span>')
    else:
        rows.append(f"  {html.escape(r)}")
pango("\n".join(rows), f"{tmp}/menu.png", 30, c["foreground"], c["background"])

clock = f'<span foreground="{c["foreground"]}">Tuesday 23:55</span>'
ws = "  ".join(f'<span foreground="{c["accent"] if i == 1 else c["muted"]}" weight="bold">{i}</span>' for i in range(1, 6))
pango(ws, f"{tmp}/ws.png", 20, c["foreground"], c["background"])
pango(clock, f"{tmp}/clock.png", 20, c["foreground"], c["background"])

def window(x, y, w, h, active, inner, inner_offset=(28, 24)):
    top, bot = (border_top, border_bot) if active else (c["darker_background"], c["darker_background"])
    return [
        "(", "-size", f"{w}x{h}", f"gradient:{top}-{bot}",
        "(", "-size", f"{w-6}x{h-6}", f"xc:{c['background']}", ")", "-geometry", "+3+3", "-composite",
        *sum([["(", img, ")", "-geometry", f"+{ox}+{oy}", "-composite"] for img, ox, oy in inner], []),
        ")", "-geometry", f"+{x}+{y}", "-composite",
    ]

bar_h = 40
gap = 16
cmd = ["magick", "(", wallpaper, "-resize", f"x{H}^", "-gravity", "center", "-crop", f"{W}x{H}+0+0", "+repage", ")", "-gravity", "northwest"]
cmd += ["(", "-size", f"{W}x{bar_h}", f"xc:{c['background']}", ")", "-geometry", "+0+0", "-composite"]
cmd += ["(", f"{tmp}/ws.png", ")", "-geometry", "+20+8", "-composite"]
cmd += ["(", f"{tmp}/clock.png", ")", "-geometry", f"+{W//2-80}+8", "-composite"]
# Leave most of the wallpaper showing: a terminal top-left, the palette under
# it, and a small menu card on the right.
tw, th = 1240, 740
cmd += window(gap, bar_h + gap, tw, th, True, [(f"{tmp}/term.png", 28, 24)])
cmd += window(gap, bar_h + 2 * gap + th, 700, 220, False, [(f"{tmp}/swatch.png", 30, 30)])
mw, mh = 360, 330
cmd += window(W - gap - mw, bar_h + gap, mw, mh, False, [(f"{tmp}/menu.png", 28, 30)])
cmd += [out]
subprocess.run(cmd, check=True)
print(out)
