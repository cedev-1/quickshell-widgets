{
  description = "Quickshell Clock Widget";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    # Quickshell config directory, stored in the nix store
    mkConfig = pkgs: pkgs.runCommand "quickshell-clock-widget-config" { } ''
      mkdir -p $out
      cp ${./shell.qml} $out/shell.qml
      cp ${./DesktopClock.qml} $out/DesktopClock.qml
    '';
  in {
    packages = forAllSystems (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in {
      config = mkConfig pkgs;
      default = pkgs.writeShellScriptBin "quickshell-clock-widget" ''
        exec ${pkgs.quickshell}/bin/quickshell -p ${mkConfig pkgs} "$@"
      '';
    });

    devShells = forAllSystems (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in {
      default = pkgs.mkShell {
        packages = [ pkgs.quickshell ];
      };
    });

    nixosModules.default = { config, pkgs, lib, ... }:
    let
      cfg = config.services.quickshell-clock-widget;
    in {
      options.services.quickshell-clock-widget = with lib; {
        enable = mkEnableOption "Quickshell clock widget";
        position = mkOption {
          type = types.enum [ "bottom-right" "bottom-left" "top-right" "top-left" "center" ];
          default = "bottom-right";
          description = "Widget position on the screen";
        };
        fontSize = mkOption {
          type = types.ints.unsigned;
          default = 84;
          description = "Size of the clock digits (other elements scale proportionally)";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.quickshell ];

        # User service: needs access to the Wayland session (WAYLAND_DISPLAY etc.)
        systemd.user.services.quickshell-clock-widget = {
          description = "Quickshell clock widget";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          environment = {
            CLOCK_POSITION = cfg.position;
            CLOCK_FONT_SIZE = toString cfg.fontSize;
          };
          serviceConfig = {
            ExecStart = "${pkgs.quickshell}/bin/quickshell -p ${mkConfig pkgs}";
            Restart = "on-failure";
            RestartSec = "3";
          };
        };
      };
    };
  };
}
