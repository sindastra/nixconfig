{ config, lib, pkgs, ... }:
let
  cfg = config.my.home-manager;

  # Load sources
  sources = import ../nix/sources.nix;
in
{
  # Import the home-manager module
  imports = [ "${sources.home-manager}/nixos" ];

  config = lib.mkIf cfg.enable {
    # Make sure to start the home-manager activation before I log it.
    systemd.services."home-manager-${config.my.user.username}" = {
      before = [ "display-manager.service" ];
      wantedBy = [ "multi-user.target" ];
    };

    home-manager.users.${config.my.user.username} = { pkgs, ... }:
      let
        isX11 = config.my.emacs.enableExwm;
        isWayland = config.my.sway.enable;
        isGraphical = isX11 || isWayland;
      in
      {
        # Import a persistance module for home-manager.
        imports = [
          "${sources.impermanence}/home-manager.nix"
          ./home-manager/weechat.nix
        ];

        programs.home-manager.enable = true;

        home.persistence.${config.my.user.persistent.homeDir} = {
          files = [ ] ++ config.my.user.persistent.extraFiles;
          directories = [ ] ++ config.my.user.persistent.extraDirectories;
          allowOther = config.programs.fuse.userAllowOther;
        };

        home.file = {
          # Home nix config.
          ".config/nixpkgs/config.nix".text = "{ allowUnfree = true; }";

          # Nano config
          ".nanorc".text = "set constantshow # Show linenumbers -c as default";

          # Tmux config
          ".tmux.conf".source = ./dotfiles/tmux.conf;

          # Fish config
          ".config/fish/config.fish".source = ./dotfiles/fish/config.fish;

          # Fish functions
          ".config/fish/functions".source = ./dotfiles/fish/functions;

          # Lorrirc
          ".direnvrc".text = ''
            use_nix() {
              eval "$(lorri direnv)"
            }
          '';

          # Some extra scripts
          "bin/git-branchclean".source = ./dotfiles/bin/git-branchclean;
          "bin/git-git".source = ./dotfiles/bin/git-git;
          "bin/git-lol".source = ./dotfiles/bin/git-lol;
          "bin/git-refetch-tags".source = ./dotfiles/bin/git-refetch-tags;
          "bin/restow".source = ./dotfiles/bin/restow;
          "bin/spacecolors".source = ./dotfiles/bin/spacecolors;

          "bin/keep".source = pkgs.runCommandNoCC "keep" { } ''
            cp ${./dotfiles/bin/keep} $out
            substituteInPlace $out --replace /bin/zsh ${pkgs.zsh}/bin/zsh
          '';
        } // lib.optionalAttrs config.my.emacs.enable {
          # Emacs inhibit startup screen
          ".emacs".text = "(custom-set-variables '(inhibit-startup-screen t))";
        } // lib.optionalAttrs isGraphical {
          # Mpv config file - Don't show images embedded in music files
          ".config/mpv/mpv.conf".text = "no-audio-display";

          # .XCompose
          ".XCompose".text = ''
            include "%L"

            # Default already
            # <Multi_key> <a> <a>: "å"
            # <Multi_key> <A> <A>: "Å"

            # Some nice binds
            <Multi_key> <a> <e>: "ä"
            <Multi_key> <A> <E>: "Ä"
            <Multi_key> <o> <e>: "ö"
            <Multi_key> <O> <E>: "Ö"

            # Table flip multi key
            <Multi_key> <t> <f>: "(ノಠ益ಠ)ノ彡┻━┻"

            # Shruggie
            <Multi_key> <s> <h>: "¯\\_(ツ)_/¯"
          '';
        };

        programs.alacritty.enable = isGraphical;
        programs.alacritty.settings = {
          env.TERM = "xterm-256color";
          font.size = config.my.fonts.size;
          font.normal.family = config.my.fonts.monospace;
          bell = {
            duration = 250;
            color = "#441111";
            animation = "EaseOut";
          };
          colors = {
            primary = { background = "#000000"; foreground = "#dddddd"; };
            normal = {
              black = "#000000";
              red = "#cc0403";
              green = "#19cb00";
              yellow = "#cecb00";
              blue = "#0d73cc";
              magenta = "#cb1ed1";
              cyan = "#0dcdcd";
              white = "#dddddd";
            };
            bright = {
              black = "#767676";
              red = "#f2201f";
              green = "#23fd00";
              yellow = "#fffd00";
              blue = "#1a8fff";
              magenta = "#fd28ff";
              cyan = "#14ffff";
              white = "#ffffff";
            };
          };
        };

        programs.git = {
          enable = true;

          # Default configs
          extraConfig = {
            commit.gpgSign = isGraphical;

            user.name = config.my.user.realname;
            user.email = config.my.user.email;
            user.signingKey = config.my.user.signingKey;

            # Set default "git pull" behaviour so it doesn't try to default to
            # either "git fetch; git merge" (default) or "git fetch; git rebase".
            pull.ff = "only";
          };

          # Global ignores
          ignores = [ ".ac-php-conf.json" ];

          # Conditonally included configs
          includes = [{
            condition = "gitdir:/home/${config.my.user.username}/tvnu/";
            contents = {
              commit.gpgSign = false;
              user.email = config.my.user.workEmail;
              user.signingKey = "";
            };
          }];
        };

        programs.browserpass.enable = isGraphical;

        xdg.mimeApps = {
          enable = isGraphical;
          defaultApplications = {
            "text/html" = [ "firefox.desktop" ];
            "x-scheme-handler/http" = [ "firefox.desktop" ];
            "x-scheme-handler/https" = [ "firefox.desktop" ];
            "x-scheme-handler/about" = [ "firefox.desktop" ];
            "x-scheme-handler/unknown" = [ "firefox.desktop" ];
            "x-scheme-handler/mailto" = [ "org.gnome.Evolution.desktop" ];
          };

          associations.added = {
            "x-scheme-handler/mailto" = [ "org.gnome.Evolution.desktop" ];
          };
        };

        # Htop configurations
        programs.htop = {
          enable = true;
          settings = {
            hide_userland_threads = true;
            hide_kernel_threads = true;
            highlight_base_name = true;
            shadow_other_users = true;
            show_program_path = true;
            tree_view = true;

            left_meters = [ "LeftCPUs" "Memory" "Swap" "ZFSARC" "ZFSCARC" ];
            left_meter_modes = [ 1 1 1 2 2 ];

            right_meters = [ "RightCPUs" "Tasks" "LoadAverage" "Uptime" "Battery" ];
            right_meter_modes = [ 1 2 2 2 2 ];
          };
        };

        # GTK theme configs
        gtk.enable = isGraphical;
        gtk.font.name = config.my.fonts.normal;
        gtk.font.size = config.my.fonts.size;
        gtk.gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;

        # Set up qt theme as well
        qt = {
          enable = isGraphical;
          platformTheme = "gtk";
        };

        # Set the rofi font
        programs.rofi.font = "${config.my.fonts.monospace} ${toString config.my.fonts.size}";

        # Enable syncthing.
        services.syncthing.enable = isGraphical;

        # Enable the dunst notification deamon
        services.dunst.enable = isX11;
        services.dunst.settings = {
          global = {
            # font = "";

            # Allow a small subset of html markup
            markup = "yes";
            plain_text = "no";

            # The format of the message
            format = "<b>%s</b>\\n%b";

            # Alignment of message text
            alignment = "center";

            # Split notifications into multiple lines
            word_wrap = "yes";

            # Ignore newlines '\n' in notifications.
            ignore_newline = "no";

            # Hide duplicate's count and stack them
            stack_duplicates = "yes";
            hide_duplicates_count = "yes";

            # The geometry of the window
            geometry = "420x50-15+49";

            # Shrink window if it's smaller than the width
            shrink = "no";

            # Don't remove messages, if the user is idle
            idle_threshold = 0;

            # Which monitor should the notifications be displayed on.
            monitor = 0;

            # The height of a single line. If the notification is one line it will be
            # filled out to be three lines.
            line_height = 3;

            # Draw a line of "separatpr_height" pixel height between two notifications
            separator_height = 2;

            # Padding between text and separator
            padding = 6;
            horizontal_padding = 6;

            # Define a color for the separator
            separator_color = "frame";

            # dmenu path
            dmenu = "${pkgs.rofi}/bin/rofi -dmenu -p dunst -theme glue_pro_blue";

            # Browser for opening urls in context menu.
            browser = "/run/current-system/sw/bin/firefox -new-tab";

            # Align icons left/right/off
            icon_position = "left";
            max_icon_size = 80;

            # Define frame size and color
            frame_width = 3;
            frame_color = "#8EC07C";
          };

          shortcuts = {
            close = "ctrl+space";
            close_all = "ctrl+shift+space";
          };

          urgency_low = {
            frame_color = "#3B7C87";
            foreground = "#3B7C87";
            background = "#191311";
            timeout = 4;
          };
          urgency_normal = {
            frame_color = "#5B8234";
            foreground = "#5B8234";
            background = "#191311";
            timeout = 6;
          };

          urgency_critical = {
            frame_color = "#B7472A";
            foreground = "#B7472A";
            background = "#191311";
            timeout = 8;
          };
        };

        # Set up mako, a notification deamon for wayland
        programs.mako.enable = isWayland;
        programs.mako.backgroundColor = "#191311";
        programs.mako.borderColor = "#3B7C87";
        programs.mako.borderSize = 3;
        programs.mako.defaultTimeout = 6000;
        programs.mako.font = "${config.my.fonts.monospace} ${toString config.my.fonts.size}";

        # Set up autorandr service to trigger on saved configurations
        programs.autorandr.enable = isX11;

        services.picom.enable = isX11;
        services.picom.vSync = (config.networking.hostName == "agrajag");

        services.flameshot.enable = isX11;
        services.pasystray.enable = isX11;
        services.network-manager-applet.enable = isX11;

        home.stateVersion = "20.09";
      };
  };
}
