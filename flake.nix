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
      lock = pkgs.writeShellScriptBin "quickshell-lock" ''
        exec ${pkgs.quickshell}/bin/quickshell ipc -p ${mkConfig pkgs} call lock lock
      '';
      launcher = pkgs.writeShellScriptBin "quickshell-launcher" ''
        exec ${pkgs.quickshell}/bin/quickshell ipc -p ${mkConfig pkgs} call launcher toggle
      '';
      dashboard = pkgs.writeShellScriptBin "quickshell-dashboard" ''
        exec ${pkgs.quickshell}/bin/quickshell ipc -p ${mkConfig pkgs} call frame toggleDashboard
      '';
      dnd = pkgs.writeShellScriptBin "quickshell-dnd" ''
        exec ${pkgs.quickshell}/bin/quickshell ipc -p ${mkConfig pkgs} call frame toggleDoNotDisturb
      '';
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

      enabled = lib.filter (name: cfg.${name}.enable) [ "clock" "stats" "header" "lock" "launcher" "frame" ];
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

        lock = {
          enable = mkEnableOption "the lock screen (trigger it with the quickshell-lock command)";
          wallpaper = mkOption {
            type = types.nullOr types.path;
            default = null;
            example = literalExpression "./wall.png";
            description = "Image used as the lock screen background. Empty means a black background.";
          };
          blur = mkOption {
            type = types.bool;
            default = true;
            description = "Blur the wallpaper";
          };
          rounding = mkOption {
            type = types.ints.unsigned;
            default = 10;
            description = "Corner radius of the password field in pixels";
          };
          font = mkOption {
            type = types.str;
            default = "JetBrainsMono Nerd Font";
            description = "Font family used on the lock screen";
          };
        };

        launcher = {
          enable = mkEnableOption "the application launcher (toggle it with the quickshell-launcher command)";
          fontSize = mkOption {
            type = types.ints.positive;
            default = 14;
            description = "Text size in pixels (the launcher scales with it)";
          };
          rounding = mkOption {
            type = types.ints.unsigned;
            default = 10;
            description = "Corner radius in pixels";
          };
          font = mkOption {
            type = types.str;
            default = "JetBrainsMono Nerd Font";
            description = "Font family used in the launcher";
          };
          terminal = mkOption {
            type = types.str;
            default = "kitty";
            description = "Terminal used for applications that run in a terminal (called as `terminal -e command`)";
          };
          rows = mkOption {
            type = types.ints.positive;
            default = 8;
            description = "Maximum number of results shown";
          };
        };

        frame = {
          enable = mkEnableOption "the screen frame: vertical bar on the left, rounded border and a dashboard that slides from the top";
          fontSize = mkOption {
            type = types.ints.positive;
            default = 14;
            description = "Base text size in pixels (the whole frame scales with it)";
          };
          thickness = mkOption {
            type = types.ints.positive;
            default = 10;
            description = "Thickness of the border on the top, right and bottom edges, in pixels";
          };
          rounding = mkOption {
            type = types.ints.positive;
            default = 24;
            description = "Radius of the rounded corners, in pixels";
          };
          font = mkOption {
            type = types.str;
            default = "JetBrainsMono Nerd Font";
            description = "Font family used in the frame";
          };
          gpu = mkOption {
            type = types.bool;
            default = false;
            description = "Show NVIDIA GPU and VRAM usage in the dashboard (requires hardware.nvidia)";
          };
          hover = mkOption {
            type = types.bool;
            default = true;
            description = "Open the dashboard when the pointer touches the top edge";
          };
          notifications = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Use the frame as the notification daemon. Disable any other daemon (for example mako) first, only one can own the D-Bus name.";
            };
            timeout = mkOption {
              type = types.ints.unsigned;
              default = 5000;
              description = "Display time in milliseconds for notifications that do not set one. Critical notifications stay until dismissed.";
            };
          };
          bar = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Show the vertical bar. Without it the frame keeps a thin uniform border.";
            };
            position = mkOption {
              type = types.enum [ "left" "right" ];
              default = "left";
              description = "Side of the screen the bar is attached to";
            };
            screens = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "HDMI-A-1" ];
              description = "Monitors that get the bar (see `hyprctl monitors`). Empty means every screen that has the frame. The other screens keep the border without the bar.";
            };
          };
          screens = screensOption;
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.quickshell ]
          ++ lib.optional cfg.lock.enable self.packages.${pkgs.stdenv.hostPlatform.system}.lock
          ++ lib.optional cfg.launcher.enable self.packages.${pkgs.stdenv.hostPlatform.system}.launcher
          ++ lib.optional cfg.frame.enable self.packages.${pkgs.stdenv.hostPlatform.system}.dashboard
          ++ lib.optional (cfg.frame.enable && cfg.frame.notifications.enable) self.packages.${pkgs.stdenv.hostPlatform.system}.dnd;

        security.pam.services.quickshell-lock = lib.mkIf cfg.lock.enable { };

        systemd.user.services.quickshell-widgets = {
          description = "Quickshell widgets";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          path = [ pkgs.coreutils pkgs.bash ]
            ++ lib.optional ((cfg.stats.enable && cfg.stats.gpu) || (cfg.frame.enable && cfg.frame.gpu)) config.hardware.nvidia.package.bin;
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

            LOCK_WALLPAPER = lib.optionalString (cfg.lock.wallpaper != null) "${cfg.lock.wallpaper}";
            LOCK_BLUR = if cfg.lock.blur then "1" else "0";
            LOCK_RADIUS = toString cfg.lock.rounding;
            LOCK_FONT = cfg.lock.font;

            LAUNCHER_FONT_SIZE = toString cfg.launcher.fontSize;
            LAUNCHER_RADIUS = toString cfg.launcher.rounding;
            LAUNCHER_FONT = cfg.launcher.font;
            LAUNCHER_TERMINAL = cfg.launcher.terminal;
            LAUNCHER_ROWS = toString cfg.launcher.rows;

            FRAME_FONT_SIZE = toString cfg.frame.fontSize;
            FRAME_THICKNESS = toString cfg.frame.thickness;
            FRAME_ROUNDING = toString cfg.frame.rounding;
            FRAME_FONT = cfg.frame.font;
            FRAME_GPU = if cfg.frame.gpu then "1" else "0";
            FRAME_HOVER = if cfg.frame.hover then "1" else "0";
            FRAME_SCREENS = csv cfg.frame.screens;
            FRAME_BAR = if cfg.frame.bar.enable then "1" else "0";
            FRAME_BAR_POSITION = cfg.frame.bar.position;
            FRAME_BAR_SCREENS = csv cfg.frame.bar.screens;
            FRAME_NOTIFICATIONS = if cfg.frame.notifications.enable then "1" else "0";
            FRAME_NOTIFICATION_TIMEOUT = toString cfg.frame.notifications.timeout;
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
