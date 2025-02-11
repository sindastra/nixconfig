{ config, lib, pkgs, ... }:
let
  isX11 = config.my.emacs.enableExwm;
  isWayland = config.my.sway.enable;
  isGraphical = isX11 || isWayland;

in
{
  config = lib.mkIf isGraphical {
    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    environment.systemPackages = with pkgs; [
      dino
      feh

      pavucontrol

      chromium
      firefox-bin

      mpv
      stupidterm
      tdesktop

      pulseeffects-pw
    ] ++ lib.optionals isX11 [
      # Add a command to run the compose xmodmap again
      (writeScriptBin "fixcompose" ''
        #!${stdenv.shell}
        ${xorg.xmodmap}/bin/xmodmap -e 'keycode 78 = Multi_key' -e 'keycode 94 = Multi_key'
      '')
    ];

    # Set up Pipewire for audio
    services.pipewire.enable = true;
    services.pipewire.alsa.enable = true;
    services.pipewire.pulse.enable = true;
    services.pipewire.jack.enable = true;

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Don't have xterm as a session manager.
    services.xserver.desktopManager.xterm.enable = false;

    # Keyboard layout.
    services.xserver.layout = "us";
    services.xserver.xkbOptions = "eurosign:e,ctrl:nocaps,numpad:mac,kpdl:dot";
    services.xserver.xkbVariant = "dvorak";

    # Enable networkmanager.
    networking.networkmanager.enable = true;
    networking.networkmanager.wifi.backend = "iwd";

    # 8000 is for random web sharing things.
    networking.firewall.allowedTCPPorts = [ 8000 ];

    # Define extra groups for user.
    my.user.extraGroups = [ "networkmanager" "dialout" ];
  };
}
