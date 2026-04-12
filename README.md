# Quickshell Clock Widget

Desktop clock widget using Quickshell. Originally from [Caelestia](https://github.com/caelestia-dots/shell), extracted as a standalone module without extra dependencies.

## NixOS

```nix
{
  inputs.quickshell-clock-widget.url = "github:cedev-1/quickshell-clock-widget";
  
  imports = [ inputs.quickshell-clock-widget.nixosModules.default ];
  
  services.quickshell-clock-widget.enable = true;
}
```

Options:
- `position` - Widget position: `bottom-right` (default), `bottom-left`, `top-right`, `top-left`, `center`
- `fontSize` - Font size in pixels (default: 84)

<img width="967" height="712" alt="image" src="https://github.com/user-attachments/assets/b4148b26-4af6-4a5b-9150-6787e07e367c" />

## Sources

https://github.com/caelestia-dots/shell/blob/main/modules/background/DesktopClock.qml
https://raw.githubusercontent.com/caelestia-dots/shell/main/modules/bar/components/Clock.qml
https://raw.githubusercontent.com/caelestia-dots/shell/main/modules/background/DesktopClock.qml