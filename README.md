# Quickshell Widgets

Quickshell components for Hyprland on NixOS, all in one flake. Enable only the ones you want.

- **clock**: desktop clock. Originally from [Caelestia](https://github.com/caelestia-dots/shell), extracted without extra dependencies.
- **stats**: CPU (with temperature), RAM, disk and optional NVIDIA GPU/VRAM, read from `/proc`, `df`, `/sys/class/hwmon` and `nvidia-smi`.
- **header**: floating header with three rounded islands: active window title, workspaces and date/time. Requires the Lua dispatch syntax (Hyprland >= 0.55).

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

The CPU temperature is read from the first `k10temp`, `coretemp` or `zenpower` sensor. The header is drawn above windows and reserves screen space, so disable any other bar placed on the same edge.

## Sources

https://github.com/caelestia-dots/shell/blob/main/modules/background/DesktopClock.qml
https://raw.githubusercontent.com/caelestia-dots/shell/main/modules/bar/components/Clock.qml
https://raw.githubusercontent.com/caelestia-dots/shell/main/modules/background/DesktopClock.qml
