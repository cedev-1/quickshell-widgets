# Quickshell Widgets

Quickshell components for Hyprland on NixOS, all in one flake. Enable only the ones you want.

- **clock**: desktop clock. Originally from [Caelestia](https://github.com/caelestia-dots/shell), extracted without extra dependencies.
- **stats**: CPU (with temperature), RAM, disk and optional NVIDIA GPU/VRAM, read from `/proc`, `df`, `/sys/class/hwmon` and `nvidia-smi`.
- **header**: floating header with three rounded islands: active window title, workspaces and date/time. Requires the Lua dispatch syntax (Hyprland >= 0.55).
- **lock**: lock screen with a blurred wallpaper, a big clock and a password field (password only, authenticated through PAM). Inspired by the lock screen of Caelestia, without weather, fingerprint or Howdy.
- **frame**: Caelestia-style screen frame. A vertical bar on the left (logo, workspaces, time), a rounded border around the screen, a dashboard (calendar, clock, system stats) that slides from the top edge, an application launcher that slides from the bottom edge, a session menu, an optional AI usage panel and notifications that slide out of the sides. Replaces Waybar, the header, the notification daemon and the launcher.

All components run in a single Quickshell process.

<img width="967" height="712" alt="image" src="https://github.com/user-attachments/assets/b4148b26-4af6-4a5b-9150-6787e07e367c" />

## Try it

```sh
nix run github:cedev-1/quickshell-clock-widget
```

Only the clock is shown by default. Choose the components with `QS_COMPONENTS`:

```sh
QS_COMPONENTS=clock,stats,header nix run github:cedev-1/quickshell-clock-widget
```

## NixOS

Add the input to your system `flake.nix` and import the module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    quickshell-widgets = {
      url = "github:cedev-1/quickshell-clock-widget";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, quickshell-widgets, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        quickshell-widgets.nixosModules.default
      ];
    };
  };
}
```

Then enable what you need:

```nix
services.quickshell-widgets = {
  enable = true;
  screens = [ "HDMI-A-1" ];

  clock.enable = true;

  stats = {
    enable = true;
    position = "bottom-left";
    gpu = true;
  };

  frame = {
    enable = true;
    gpu = true;
  };

  lock = {
    enable = true;
    wallpaper = ./wall.png;
  };

  header = {
    enable = true;
    showTitle = false;
    rounding = vars.rounding;
    font = vars.font;
  };
};
```

The widgets run as a systemd **user** service bound to `graphical-session.target`. If you start Hyprland without UWSM, that target may not be active: enable `programs.hyprland.withUWSM` or add `exec-once = systemctl --user start quickshell-widgets` to your Hyprland config.

Check it with `systemctl --user status quickshell-widgets`.

## Lock screen

Enabling `lock` installs the `quickshell-lock` command and a `quickshell-lock` PAM service. Bind the command to a key, for example in a Lua Hyprland config:

```lua
hl.bind("SUPER + L", hl.dsp.exec_cmd("quickshell-lock"))
```

For automatic locking after some idle time, call the same command from `hypridle`.

The lock uses the `ext-session-lock` protocol: if the process crashes, the session stays locked. To recover, switch to a TTY (`Ctrl+Alt+F3`), log in and run `systemctl --user restart quickshell-widgets`, then unlock with your password.

### Testing safely

To try it without risk, run it from a checkout with an automatic unlock after 30 seconds and the standard `login` PAM service. In a first terminal:

```sh
QS_COMPONENTS=lock LOCK_PAM=login LOCK_AUTOUNLOCK=30 LOCK_WALLPAPER=/path/to/wall.png quickshell -p ./qml
```

In a second terminal:

```sh
quickshell ipc -p ./qml call lock lock
```

`LOCK_AUTOUNLOCK` is meant for testing only and is not exposed as a NixOS option.

## Frame

The frame is one transparent window per screen that draws the bar and the border as a single shape. Panels attach to the border with rounded, concave junctions, like in Caelestia. It reserves space on all four edges, so disable any other bar (Waybar, the header) and reduce `gaps_out` in your Hyprland config to keep the windows snug against the border.

The dashboard opens when the pointer touches the top edge (`hover`) and closes when it leaves. You can also bind the `quickshell-dashboard` command, which toggles it on the focused screen:

```lua
hl.bind("SUPER + D", hl.dsp.exec_cmd("quickshell-dashboard"))
```

### Launcher

The launcher slides from the bottom edge of the focused screen, with the same rounded junctions as the other panels. The search field is at the bottom and the results are above it, the best match closest to the field. Bind the `quickshell-launcher` command, which toggles it, for example to replace rofi in a Lua Hyprland config:

```lua
hl.bind("SUPER + R", hl.dsp.exec_cmd("quickshell-launcher"))
```

Type to search (name, generic name, comment and keywords), `Up`/`Down` or `Ctrl+K`/`Ctrl+J` (also `Ctrl+P`/`Ctrl+N`) to move, `Enter` to launch and `Esc` to close. Clicking outside also closes it. Applications that run in a terminal are started with `launcher.terminal`.

### Session menu

A panel with lock, logout, sleep, reboot and shutdown buttons slides out of the side opposite to the bar, vertically centered, with the same rounded junctions. Open it with the power button at the bottom of the bar or with the `quickshell-session` command, which toggles it on the focused screen:

```lua
hl.bind("SUPER + X", hl.dsp.exec_cmd("quickshell-session"))
```

Use `Up`/`Down` (or `K`/`J`), `Enter` to run and `Esc` to close, or click a button. The commands are options (`session.commands.*`) with absolute paths, because the service has a minimal `PATH`. The lock button runs `quickshell-lock` when `lock.enable` is set, and any button whose command is empty is hidden. The default logout command exits Hyprland through its Lua dispatcher.

### AI usage panel

With `usage.enable = true`, a bot button appears in the bar above the power button. It opens a panel on the bar side, at the same place as the notifications (which are replaced while it is open), with:

- **Claude Code**: the 5 hour and weekly limits as progress bars (red above 90 %) with the time left before each reset.
- **OpenCode Go**: the 5 hour, weekly and monthly limits of your account, with the time left before each reset and a "limit reached" mark. They are computed by the OpenCode server, so they include your other machines.

The Claude numbers come from the official statusline of Claude Code, not from any API, so no credentials are read and nothing goes over the network. They are only provided on claude.ai Pro and Max plans, after the first answer of a session, and they refresh while you use Claude Code. The module installs `quickshell-claude-usage`, a small command that stores the limits in `~/.cache/quickshell-usage/claude.json` and prints a short `5h 23% · 7d 41%` line. Enable it in `~/.claude/settings.json`:

```json
{
  "statusLine": { "type": "command", "command": "quickshell-claude-usage" }
}
```

The OpenCode Go numbers need **OpenCode v2** signed in to the OpenCode console (`opencode auth login`, or the sign-in from the web interface). OpenCode v2 exposes them on its local server (`GET /api/experimental/usage/limits`, an experimental route) and handles the credentials and their renewal itself. The module installs `quickshell-opencode-usage`, run by the widget at most every `usage.interval` while the panel is open. It uses the OpenCode background service registered in `~/.local/state/opencode/service.json` when its process is alive. Otherwise it starts a temporary `opencode serve` on a random local port (the `opencode` command must be in your profile), reads the limits and stops it, which takes about two seconds. Only the percentages and reset times are stored, in `~/.cache/quickshell-usage/opencode.json`; no OpenCode credential is read or copied by the widget. If a refresh fails, the panel keeps the last values and shows the error.

The `quickshell-usage` command toggles the panel on the focused screen. Set `usage.claude = false` or `usage.opencode = false` to hide a section.

### Choosing where the frame and the bar go

`frame.screens` decides which screens get the frame (border, dashboard, notifications). `frame.bar.screens` decides which of those also get the bar, and `frame.bar.position` puts it on the left or on the right. For example, the bar only on the main screen, on the left, while the second one keeps a thin border:

```nix
services.quickshell-widgets.frame = {
  enable = true;
  screens = [ "HDMI-A-1" "HDMI-A-2" ];
  bar = {
    position = "left";
    screens = [ "HDMI-A-1" ];
  };
};
```

To have no frame at all on the second screen, list only the first one in `frame.screens`. Monitor names come from `hyprctl monitors`.

### Notifications

The frame is also a notification daemon (`org.freedesktop.Notifications`). Notifications appear in a panel attached to the right side of the bar, above the clock, with the same rounded junctions as the dashboard. Up to four are shown, newest first, with icon, title, body (markup) and action buttons. Click a notification to dismiss it. They expire after `notifications.timeout` (critical ones stay until dismissed) and the timer pauses while the pointer is over them.

Only one daemon can own the notification name on D-Bus, so disable the previous one (for example `services.mako.enable = false`) or set `frame.notifications.enable = false`.

The `quickshell-dnd` command toggles do-not-disturb, which hides the panel. To dismiss everything: `quickshell ipc -p <config> call frame clearNotifications`.

## Options

Global:
- `enable` - Enable the service
- `screens` - Monitors to show the widgets on, e.g. `[ "DP-1" "HDMI-A-1" ]` (find them with `hyprctl monitors`). Empty (default) means all screens.

Every component also has `enable` and `screens` (empty means the global `screens`).

`clock`:
- `position` - `bottom-right` (default), `bottom-left`, `top-right`, `top-left`, `center`
- `fontSize` - Size of the clock digits (default: 84). The date and day text scale proportionally.

`stats`:
- `position` - Same values as the clock (default: `bottom-left`)
- `fontSize` - Size of the values (default: 20). Everything else scales proportionally.
- `interval` - Refresh interval in milliseconds (default: 2000)
- `gpu` - Show NVIDIA GPU and VRAM usage via `nvidia-smi` (default: false, requires `hardware.nvidia`)

`header`:
- `position` - `top` (default) or `bottom`
- `showTitle` - Show the active window title on the left (default: true)
- `fontSize` - Text size in pixels (default: 12). The header scales with it.
- `rounding` - Corner radius in pixels (default: 10)
- `font` - Font family (default: `JetBrainsMono Nerd Font`)

`lock`:
- `wallpaper` - Image used as the background (default: none, black background)
- `blur` - Blur the wallpaper (default: true)
- `rounding` - Corner radius of the password field in pixels (default: 10)
- `font` - Font family (default: `JetBrainsMono Nerd Font`)

`frame`:
- `fontSize` - Base text size in pixels (default: 14). The whole frame scales with it.
- `thickness` - Border thickness on the top, right and bottom edges (default: 10)
- `rounding` - Radius of the rounded corners (default: 24)
- `font` - Font family (default: `JetBrainsMono Nerd Font`)
- `gpu` - Show NVIDIA GPU and VRAM in the dashboard (default: false)
- `hover` - Open the dashboard when the pointer touches the top edge (default: true)
- `bar.enable` - Show the vertical bar (default: true). Without it the frame keeps a thin uniform border.
- `bar.position` - `left` (default) or `right`
- `bar.logo` - Show the NixOS logo at the top of the bar (default: true)
- `bar.screens` - Monitors that get the bar. Empty (default) means every screen that has the frame. The other screens keep the border without the bar.
- `usage.enable` - AI usage panel and its bot button (default: false)
- `usage.claude` - Show the Claude Code limits (default: true)
- `usage.opencode` - Show the OpenCode Go limits (default: true)
- `usage.interval` - Refresh interval of the OpenCode Go limits in milliseconds, while the panel is open (default: 300000)
- `session.enable` - Session menu (default: true)
- `session.commands.{lock,logout,suspend,reboot,shutdown}` - Commands of the buttons. Empty hides a button. Defaults use absolute paths (`systemctl`, `hyprctl`, `quickshell-lock`).
- `launcher.enable` - Application launcher (default: true)
- `launcher.terminal` - Terminal for applications that run in a terminal, called as `terminal -e command` (default: `kitty`)
- `launcher.rows` - Maximum number of results shown (default: 8)
- `notifications.enable` - Use the frame as the notification daemon (default: true)
- `notifications.timeout` - Display time in milliseconds (default: 5000)

The CPU temperature is read from the first `k10temp`, `coretemp` or `zenpower` sensor. The header is drawn above windows and reserves screen space, so disable any other bar placed on the same edge.

## Sources

https://github.com/caelestia-dots/shell/blob/main/modules/background/DesktopClock.qml
https://raw.githubusercontent.com/caelestia-dots/shell/main/modules/bar/components/Clock.qml
https://raw.githubusercontent.com/caelestia-dots/shell/main/modules/background/DesktopClock.qml
