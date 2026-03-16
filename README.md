# linux-wallpaperengine-TUI
A lightweight, fast, linux-wallpaperengine UI by me!~

## Dependencies

**Required:**
- [linux-wallpaperengine](https://github.com/Almamu/linux-wallpaperengine) - I mean, it's kinda obvious but I have to say it (:3)
- [fzf](https://github.com/junegunn/fzf)
- [jq](https://stedolan.github.io/jq/)
- [inotify-tools](https://github.com/inotify-tools/inotify-tools)

**Required depending on setup(O_O):**
- [xrandr](https://www.x.org/wiki/Projects/XRandR/)
- [wlr-randr](https://sr.ht/~emersion/wlr-randr/)
- If you're on hyprland hyprctl is an option so don't worry about it (^ᗜ^ )

**Optional (color tools):**
- [wallust](https://codeberg.org/explosion-mental/wallust) - the best btw
- [pywal](https://github.com/dylanaraps/pywal) - deprecated, while it is supported do not use it please!
- [pywal16](https://github.com/eylles/pywal16)
- [matugen](https://github.com/InioX/matugen)

## Installation

You probably already did this part hundreds of times in the past, you know what to do you're smart:

```bash
git clone https://github.com/Joplys/linux-wallpaperengine-TUI
cd linux-wallpaperengine-TUI
chmod +x walliwalli.sh
cp walliwalli.sh ~/.local/bin/walliwalli
```

Make sure `~/.local/bin` is in your `PATH`. If it isn't, add this to your `~/.bashrc` or `~/.zshrc`, or don't, im not your boss:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

On first run, the TUI should (SHOULD NOT WILL) automatically detect your Steam/Wallpaper Engine workshop directory. On the off-chance it can't find it, you can set it manually via **Settings → Library → Edit wallpaper directory**.

## Usage

Just run:

```bash
walliwalli
```

A cool and cute :3 fuzzy-searchable list of your wallpaperengine wallpapers should appear, if it doesn't and you checked that you put in the right directory in the settings please tell me.

Press Escape or Ctrl+C to exit without launching anything.

Oh also the settings menu is really useful, GO CHECK IT, you WILL use it.

## Issues

If you find any bugs while using it, please tell me, please, (╥﹏╥).

## License

See [LICENSE](LICENSE).
