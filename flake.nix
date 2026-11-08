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
      usage = pkgs.writeShellScriptBin "quickshell-usage" ''
        exec ${pkgs.quickshell}/bin/quickshell ipc -p ${mkConfig pkgs} call frame toggleUsage
      '';
      session = pkgs.writeShellScriptBin "quickshell-session" ''
        exec ${pkgs.quickshell}/bin/quickshell ipc -p ${mkConfig pkgs} call frame toggleSession
      '';
      opencode-usage-fetch = pkgs.writeShellApplication {
        name = "quickshell-opencode-usage";
        runtimeInputs = [ pkgs.jq pkgs.curl pkgs.coreutils pkgs.gnugrep pkgs.gawk ];
        text = ''
          registration="''${OPENCODE_SERVICE_FILE:-''${XDG_STATE_HOME:-$HOME/.local/state}/opencode/service.json}"
          dir="''${XDG_CACHE_HOME:-$HOME/.cache}/quickshell-usage"
          out="$dir/opencode.json"
          mkdir -p "$dir"
          now="$(date +%s)"
          export PATH="$PATH:/etc/profiles/per-user/''${USER:-$(id -un)}/bin:/run/current-system/sw/bin:$HOME/.nix-profile/bin"

          save() {
            tmp="$(mktemp "$dir/.opencode.XXXXXX")"
            cat > "$tmp"
            mv "$tmp" "$out"
          }

          fail() {
            if [ -f "$out" ] && jq -e '.weekly' "$out" >/dev/null 2>&1; then
              jq -c --arg e "$1" '. + {error: $e}' "$out" | save
            else
              jq -cn --argjson now "$now" --arg e "$1" '{updated: $now, error: $e}' | save
            fi
          }

          work="$(mktemp -d "$dir/.opencode-work.XXXXXX")"
          server_pid=""
          cleanup() {
            if [ -n "$server_pid" ]; then
              kill "$server_pid" 2>/dev/null || true
              for _ in $(seq 1 20); do
                if ! kill -0 "$server_pid" 2>/dev/null; then
                  break
                fi
                sleep 0.25
              done
              kill -9 "$server_pid" 2>/dev/null || true
            fi
            rm -rf "$work"
          }
          trap cleanup EXIT

          url=""
          password=""
          if [ -f "$registration" ]; then
            service_pid="$(jq -r '.pid // empty' "$registration" 2>/dev/null || true)"
            if [ -n "$service_pid" ] && kill -0 "$service_pid" 2>/dev/null; then
              url="$(jq -r '.url // empty' "$registration" 2>/dev/null || true)"
              password="$(jq -r '.password // empty' "$registration" 2>/dev/null || true)"
            fi
          fi

          if [ -z "$url" ]; then
            if ! command -v opencode >/dev/null 2>&1; then
              fail "OpenCode is not running and the opencode command was not found"
              exit 0
            fi
            port="$(shuf -i 20000-60000 -n 1)"
            opencode serve --hostname 127.0.0.1 --port "$port" > "$work/server.log" 2>&1 &
            server_pid=$!
            for _ in $(seq 1 60); do
              if grep -q 'server listening' "$work/server.log" 2>/dev/null; then
                break
              fi
              if ! kill -0 "$server_pid" 2>/dev/null; then
                break
              fi
              sleep 0.5
            done
            if ! grep -q 'server listening' "$work/server.log" 2>/dev/null; then
              fail "could not start a temporary OpenCode server"
              exit 0
            fi
            password="$(grep -o 'server password .*' "$work/server.log" | awk '{print $3}' | head -n 1 || true)"
            url="http://127.0.0.1:$port"
          fi

          body="$work/body"
          code="$(
            {
              if [ -n "$password" ]; then
                printf 'user = "opencode:%s"\n' "$password"
              fi
            } | curl -sS -m 20 -K - -o "$body" -w '%{http_code}' "$url/api/experimental/usage/limits" 2>/dev/null || true
          )"

          if [ "$code" != 200 ]; then
            message="$(jq -r '.message // ._tag // empty' "$body" 2>/dev/null || true)"
            fail "request failed (HTTP ''${code:-none}''${message:+: $message})"
            exit 0
          fi

          if jq -e '.data.go' "$body" >/dev/null 2>&1; then
            jq -c --argjson now "$now" '{updated: $now, rolling: .data.go.rolling, weekly: .data.go.weekly, monthly: .data.go.monthly}' "$body" | save
          elif jq -e '.data == null' "$body" >/dev/null 2>&1; then
            fail "not signed in to the OpenCode console (run opencode auth login)"
          else
            fail "no OpenCode Go plan in this workspace"
          fi
        '';
      };
      claude-usage-hook = pkgs.writeShellApplication {
        name = "quickshell-claude-usage";
        runtimeInputs = [ pkgs.jq pkgs.coreutils ];
        text = ''
          dir="''${XDG_CACHE_HOME:-$HOME/.cache}/quickshell-usage"
          input="$(cat)"

          if printf '%s' "$input" | jq -e '.rate_limits.five_hour // .rate_limits.seven_day' >/dev/null 2>&1; then
            mkdir -p "$dir"
            tmp="$(mktemp "$dir/.claude.XXXXXX")"
            printf '%s' "$input" | jq -c --argjson now "$(date +%s)" '{updated: $now, five_hour: (.rate_limits.five_hour // null), seven_day: (.rate_limits.seven_day // null)}' > "$tmp"
            mv "$tmp" "$dir/claude.json"
          fi

          printf '%s' "$input" | jq -r '[(.rate_limits.five_hour.used_percentage // empty | "5h \(floor)%"), (.rate_limits.seven_day.used_percentage // empty | "7d \(floor)%")] | join(" · ")'
        '';
      };
      launcher = pkgs.writeShellScriptBin "quickshell-launcher" ''
        exec ${pkgs.quickshell}/bin/quickshell ipc -p ${mkConfig pkgs} call frame toggleLauncher
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

      enabled = lib.filter (name: cfg.${name}.enable) [ "clock" "stats" "header" "lock" "frame" ];
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
            logo = mkOption {
              type = types.bool;
              default = true;
              description = "Show the NixOS logo at the top of the bar";
            };
            screens = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "HDMI-A-1" ];
              description = "Monitors that get the bar (see `hyprctl monitors`). Empty means every screen that has the frame. The other screens keep the border without the bar.";
            };
          };
          launcher = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Application launcher that slides from the bottom edge (toggle it with the quickshell-launcher command)";
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
          session = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Session menu (lock, logout, sleep, reboot, shutdown) that slides out of the side opposite to the bar. Open it with the power button of the bar or the quickshell-session command.";
            };
            commands = {
              lock = mkOption {
                type = types.str;
                default = lib.optionalString cfg.lock.enable "${self.packages.${pkgs.stdenv.hostPlatform.system}.lock}/bin/quickshell-lock";
                defaultText = literalExpression "the quickshell-lock command when `lock.enable` is set, empty otherwise";
                description = "Command run by the lock button. Empty hides the button.";
              };
              logout = mkOption {
                type = types.str;
                default = "/run/current-system/sw/bin/hyprctl dispatch 'hl.dsp.exit()'";
                description = "Command run by the logout button. Empty hides the button.";
              };
              suspend = mkOption {
                type = types.str;
                default = "${config.systemd.package}/bin/systemctl suspend";
                defaultText = literalExpression "systemctl suspend";
                description = "Command run by the sleep button. Empty hides the button.";
              };
              reboot = mkOption {
                type = types.str;
                default = "${config.systemd.package}/bin/systemctl reboot";
                defaultText = literalExpression "systemctl reboot";
                description = "Command run by the reboot button. Empty hides the button.";
              };
              shutdown = mkOption {
                type = types.str;
                default = "${config.systemd.package}/bin/systemctl poweroff";
                defaultText = literalExpression "systemctl poweroff";
                description = "Command run by the shutdown button. Empty hides the button.";
              };
            };
          };
          usage = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "AI usage panel: a bot button above the clock opens a panel with the Claude Code limits and the OpenCode Go limits (5 hours, week and month). Open it with the button or the quickshell-usage command.";
            };
            claude = mkOption {
              type = types.bool;
              default = true;
              description = "Show the Claude Code limits. They come from the statusline of Claude Code (Pro/Max plans only): add `statusLine = { type = \"command\"; command = \"quickshell-claude-usage\"; }` to ~/.claude/settings.json.";
            };
            opencode = mkOption {
              type = types.bool;
              default = true;
              description = "Show the OpenCode Go limits (5 hours, week, month) of your account. They come from the local OpenCode service (OpenCode v2, signed in to the OpenCode console), which asks the OpenCode server and handles the credentials itself.";
            };
            interval = mkOption {
              type = types.ints.positive;
              default = 300000;
              description = "Refresh interval of the OpenCode Go limits in milliseconds, while the panel is open";
            };
          };
          screens = screensOption;
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.quickshell ]
          ++ lib.optional cfg.lock.enable self.packages.${pkgs.stdenv.hostPlatform.system}.lock
          ++ lib.optional (cfg.frame.enable && cfg.frame.launcher.enable) self.packages.${pkgs.stdenv.hostPlatform.system}.launcher
          ++ lib.optional (cfg.frame.enable && cfg.frame.session.enable) self.packages.${pkgs.stdenv.hostPlatform.system}.session
          ++ lib.optional (cfg.frame.enable && cfg.frame.usage.enable) self.packages.${pkgs.stdenv.hostPlatform.system}.usage
          ++ lib.optional (cfg.frame.enable && cfg.frame.usage.enable && cfg.frame.usage.claude) self.packages.${pkgs.stdenv.hostPlatform.system}.claude-usage-hook
          ++ lib.optional (cfg.frame.enable && cfg.frame.usage.enable && cfg.frame.usage.opencode) self.packages.${pkgs.stdenv.hostPlatform.system}.opencode-usage-fetch
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


            FRAME_FONT_SIZE = toString cfg.frame.fontSize;
            FRAME_THICKNESS = toString cfg.frame.thickness;
            FRAME_ROUNDING = toString cfg.frame.rounding;
            FRAME_FONT = cfg.frame.font;
            FRAME_GPU = if cfg.frame.gpu then "1" else "0";
            FRAME_HOVER = if cfg.frame.hover then "1" else "0";
            FRAME_SCREENS = csv cfg.frame.screens;
            FRAME_BAR = if cfg.frame.bar.enable then "1" else "0";
            FRAME_BAR_POSITION = cfg.frame.bar.position;
            FRAME_BAR_LOGO = if cfg.frame.bar.logo then "1" else "0";
            FRAME_BAR_SCREENS = csv cfg.frame.bar.screens;
            FRAME_USAGE = if cfg.frame.enable && cfg.frame.usage.enable then "1" else "0";
            FRAME_USAGE_CLAUDE = if cfg.frame.usage.claude then "1" else "0";
            FRAME_USAGE_OPENCODE = if cfg.frame.usage.opencode then "1" else "0";
            FRAME_USAGE_INTERVAL = toString cfg.frame.usage.interval;
            FRAME_USAGE_OPENCODE_COMMAND = "${self.packages.${pkgs.stdenv.hostPlatform.system}.opencode-usage-fetch}/bin/quickshell-opencode-usage";
            FRAME_SESSION = if cfg.frame.session.enable then "1" else "0";
            FRAME_SESSION_LOCK = cfg.frame.session.commands.lock;
            FRAME_SESSION_LOGOUT = cfg.frame.session.commands.logout;
            FRAME_SESSION_SUSPEND = cfg.frame.session.commands.suspend;
            FRAME_SESSION_REBOOT = cfg.frame.session.commands.reboot;
            FRAME_SESSION_SHUTDOWN = cfg.frame.session.commands.shutdown;
            FRAME_LAUNCHER = if cfg.frame.launcher.enable then "1" else "0";
            FRAME_LAUNCHER_TERMINAL = cfg.frame.launcher.terminal;
            FRAME_LAUNCHER_ROWS = toString cfg.frame.launcher.rows;
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
