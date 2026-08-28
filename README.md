# Botanical Lock

Botanical Lock is a wallpaper-first secure lock screen for Omarchy 4. The active background fills the display while a neutral translucent panel contains the authentication interface.

## Features

- Uses the current Omarchy wallpaper without maintaining a separate wallpaper library.
- Plays the active Motion Backgrounds video directly inside the secure lock surface.
- Automatically falls back to Omarchy's static background image.
- Large clock, date, and time-aware greeting.
- Translucent right-side panel with matching wallpaper blur.
- `~/.face` profile image with a monogram fallback.
- Password authentication and optional fingerprint status through Omarchy's PAM configuration.
- Native `ext-session-lock-v1` Wayland session security.
- Multi-monitor lock surfaces.
- Display blanking one minute after locking, with suspend/resume handling.
- Honors Omarchy's coffee-button Stay Awake mode, keeping locked displays awake
  until Stay Awake is turned off.

## Requirements

- Omarchy 4 with its standard Quickshell runtime.
- Omarchy's existing password PAM configuration.
- Qt Multimedia, provided by the current Omarchy desktop stack, for live-video decoding.

Static backgrounds work without another plugin. Live backgrounds require [Motion Backgrounds](https://github.com/pulkitchauhan03/omarchy-motion-backgrounds) to be installed, enabled, and currently using a video.

## Install

Use Omarchy's official plugin manager:

```bash
omarchy plugin add https://github.com/pulkitchauhan03/omarchy-botanical-lock.git --enable
```

The manifest declares Botanical Lock as a replacement for `omarchy.lock`. Enabling it switches Omarchy to this lock implementation while retaining the stock PAM authentication flow and session-lock protocol.

No install script, manual file copy, or shell restart is required on a fresh installation.

## Use

Lock the session through Omarchy's normal shortcut or command:

```bash
omarchy system lock
```

Botanical Lock uses `~/.face` as the profile image when that file is available. Without it, the panel displays a generated monogram.

### Live wallpapers

Motion Backgrounds records its active video in:

```text
~/.local/state/motion-backgrounds/current.json
```

Botanical Lock watches this file and decodes the selected video with Qt Multimedia inside each secure lock surface. Playback loops silently only while the lock screen is visible. Selecting a static wallpaper clears the video state and restores the normal image path automatically.

The state file may not exist when the shell first loads, especially on a fresh
Motion Backgrounds installation. Botanical Lock retries the missing file and
picks it up as soon as the first video is activated; restarting the Omarchy
shell is not required.

This design does not expose the unlocked desktop's `mpvpaper` surface above the lock screen.

## Preview and diagnostics

Open the lock design without locking the session:

```bash
omarchy-shell lock preview
```

Close the preview and inspect status:

```bash
omarchy-shell lock hidePreview
omarchy-shell lock status
```

The status response includes the selected live-video path and whether preview playback is active.

Validate the installed plugin manifest and QML entry point with:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/io.github.pulkitchauhan.botanical-lock
```

## Update

```bash
omarchy plugin update io.github.pulkitchauhan.botanical-lock
```

## Remove

```bash
omarchy plugin remove io.github.pulkitchauhan.botanical-lock
```

When the enabled replacement is removed, Omarchy restores the built-in `omarchy.lock` plugin automatically.

## Safety testing

After installation, test manual lock and unlock before relying on idle locking. If you use suspend or fingerprint authentication, test those paths as well. The preview command verifies layout and video playback, but it does not acquire the secure Wayland session lock.
