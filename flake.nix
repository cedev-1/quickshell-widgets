{
  description = "Quickshell widgets: desktop clock, system stats and floating header";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    mkConfig = pkgs: pkgs.runCommand "quickshell-widgets-config" { } ''
      mkdir -p $out
      cp ${./qml}/*.qml $out/
    '';
  in {
    packages = forAllSystems (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in {
      config = mkConfig pkgs;
      default = pkgs.writeShellScriptBin "quickshell-widgets" ''
        export PATH=${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.bash ]}:$PATH
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
      cfg = config.services.quickshell-widgets;

      positionOption = default: lib.mkOption {
        type = lib.types.enum [ "bottom-right" "bottom-left" "top-right" "top-left" "center" ];
        inherit default;
        description = "Position on the screen";
      };

      screensOption = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "DP-1" "HDMI-A-1" ];
        description = "Monitors for this component (see `hyprctl monitors`). Empty means the global `screens` option.";
      };

      enabled = lib.filter (name: cfg.${name}.enable) [ "clock" "stats" "header" ];
      csv = lib.concatStringsSep ",";
    in {
      options.services.quickshell-widgets = with lib; {
        enable = mkEnableOption "Quickshell widgets";

        screens = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "DP-1" "HDMI-A-1" ];
          description = "Monitors to show the widgets on (see `hyprctl monitors`). Empty means all screens.";
        };

        clock = {
          enable = mkEnableOption "the desktop clock";
          position = positionOption "bottom-right";
          fontSize = mkOption {
            type = types.ints.positive;
            default = 84;
            description = "Size of the clock digits (other elements scale proportionally)";
          };
          screens = screensOption;
        };

        stats = {
          enable = mkEnableOption "the system stats widget";
          position = positionOption "bottom-left";
          fontSize = mkOption {
            type = types.ints.positive;
            default = 20;
            description = "Size of the values (other elements scale proportionally)";
          };
          interval = mkOption {
            type = types.ints.positive;
            default = 2000;
            description = "Refresh interval in milliseconds";
          };
          gpu = mkOption {
            type = types.bool;
            default = false;
            description = "Show NVIDIA GPU and VRAM usage (requires hardware.nvidia)";
          };
          screens = screensOption;
        };

        header = {
          enable = mkEnableOption "the floating header";
          position = mkOption {
            type = types.enum [ "top" "bottom" ];
            default = "top";
            description = "Edge of the screen the header is attached to";
          };
          showTitle = mkOption {
            type = types.bool;
            default = true;
            description = "Show the active window title on the left";
          };
          fontSize = mkOption {
            type = types.ints.positive;
            default = 12;
            description = "Text size in pixels (the header scales with it)";
          };
          rounding = mkOption {
            type = types.ints.unsigned;
            default = 10;
            description = "Corner radius in pixels";
          };
          font = mkOption {
            type = types.str;
            default = "JetBrainsMono Nerd Font";
            description = "Font family used in the header";
          };
          screens = screensOption;
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.quickshell ];

        systemd.user.services.quickshell-widgets = {
          description = "Quickshell widgets";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          path = [ pkgs.coreutils pkgs.bash ]
            ++ lib.optional (cfg.stats.enable && cfg.stats.gpu) config.hardware.nvidia.package.bin;
          environment = {
            QS_COMPONENTS = csv enabled;
            QS_SCREENS = csv cfg.screens;

            CLOCK_POSITION = cfg.clock.position;
            CLOCK_FONT_SIZE = toString cfg.clock.fontSize;
            CLOCK_SCREENS = csv cfg.clock.screens;

            STATS_POSITION = cfg.stats.position;
            STATS_FONT_SIZE = toString cfg.stats.fontSize;
            STATS_INTERVAL = toString cfg.stats.interval;
            STATS_GPU = if cfg.stats.gpu then "1" else "0";
            STATS_SCREENS = csv cfg.stats.screens;

            HEADER_POSITION = cfg.header.position;
            HEADER_SHOW_TITLE = if cfg.header.showTitle then "1" else "0";
            HEADER_FONT_SIZE = toString cfg.header.fontSize;
            HEADER_RADIUS = toString cfg.header.rounding;
            HEADER_FONT = cfg.header.font;
            HEADER_SCREENS = csv cfg.header.screens;
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
