{
  description = "Quickshell Clock Widget";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
  in {
    packages = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.quickshell;
    });

    devShells = forAllSystems (system: {
      default = (nixpkgs.legacyPackages.${system}.mkShell {
        packages = [ nixpkgs.legacyPackages.${system}.quickshell ];
      }).overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs or [];
      });
    });

    nixosModules.default = { config, pkgs, lib, ... }:
    let
      cfg = config.services.quickshell-clock-widget;
    in {
      options.services.quickshell-clock-widget = with lib; {
        enable = mkEnableOption "Quickshell clock widget (displayed in the bottom-right corner)";
        position = mkOption {
          type = types.enum [ "bottom-right" "bottom-left" "top-right" "top-left" "center" ];
          default = "bottom-right";
          description = "Widget position on the screen";
        };
        fontSize = mkOption {
          type = types.ints.unsigned;
          default = 84;
          description = "Font size of the clock (in pixels)";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.quickshell ];

        environment.etc = {
          "quickshell/shell.qml".source = ./shell.qml;
          "quickshell/DesktopClock.qml".source = ./DesktopClock.qml;
        };

        systemd.services.quickshell-clock-widget = {
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.quickshell}/bin/quickshell";
            Restart = "on-failure";
            RestartSec = "3";
          };
        };
      };
    };
  };
}
