# Botanical Lock

A wallpaper-first lock screen for Omarchy 4. Your active Omarchy wallpaper fills the screen; a translucent botanical-green panel on the right contains the authentication UI.

## Features

- Uses the current Omarchy wallpaper; the plugin does not ship or select a background.
- Large clock and date on the wallpaper.
- Translucent right-side authentication panel with a monogram, greeting, password field, and fingerprint indicator.
- Retains Omarchy's stock PAM and Wayland session-lock service.
- Keeps the display visible for one minute after locking before blanking it.

## Development

Validate before enabling:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/io.github.pulkitchauhan.botanical-lock
```

The plugin must be installed into `~/.config/omarchy/plugins/` and enabled as a replacement for `omarchy.lock`. Test manual lock, idle lock, and suspend/resume before relying on it.
