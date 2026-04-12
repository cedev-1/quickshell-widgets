# Quickshell Clock Widget

Desktop clock widget using Quickshell. Originally from [Caelestia](https://github.com/caelestia-dots/shell), extracted as a standalone module without extra dependencies.

## NixOS

```nix
{
  inputs.quickshell-clock-widget.url = "github:cedev/quickshell-clock-widget";
  
  imports = [ inputs.quickshell-clock-widget.nixosModules.default ];
  
  services.quickshell-clock-widget.enable = true;
}
```

Options:
- `position` - Widget position: `bottom-right` (default), `bottom-left`, `top-right`, `top-left`, `center`
- `fontSize` - Font size in pixels (default: 84)