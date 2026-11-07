# Quickshell Clock Widget

Desktop clock widget using Quickshell. Originally from [Caelestia](https://github.com/caelestia-dots/shell), extracted as a standalone module without extra dependencies.

## Try it

```sh
nix run github:cedev-1/quickshell-clock-widget
```

## NixOS

Add the input to your system `flake.nix` and import the module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    quickshell-clock-widget = {
      url = "github:cedev-1/quickshell-clock-widget";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, quickshell-clock-widget, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        quickshell-clock-widget.nixosModules.default
      ];
    };
  };
}
```

Then enable it in your configuration:

```nix
services.quickshell-clock-widget = {
  enable = true;
  position = "bottom-right";
  fontSize = 84;
};
```

The widget runs as a systemd **user** service bound to `graphical-session.target`, so it starts with your Wayland session. If you start Hyprland without UWSM, that target may not be active: enable `programs.hyprland.withUWSM` or add `exec-once = systemctl --user start quickshell-clock-widget` to your Hyprland config.

Check it with `systemctl --user status quickshell-clock-widget`.

Options:
- `position` - Widget position: `bottom-right` (default), `bottom-left`, `top-right`, `top-left`, `center`
- `fontSize` - Size of the clock digits (default: 84). The date and day text scale proportionally.

<img width="967" height="712" alt="image" src="https://github.com/user-attachments/assets/b4148b26-4af6-4a5b-9150-6787e07e367c" />

## Sources

https://github.com/caelestia-dots/shell/blob/main/modules/background/DesktopClock.qml
https://raw.githubusercontent.com/caelestia-dots/shell/main/modules/bar/components/Clock.qml
https://raw.githubusercontent.com/caelestia-dots/shell/main/modules/background/DesktopClock.qml