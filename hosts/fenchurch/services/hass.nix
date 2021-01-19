{ config, pkgs, ... }:

let
  hpkgs = import
    (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/0734f95e256632273f8e0220c64351fb43ec0a3e.tar.gz";
      sha256 = "1pjmjpblhkxw2gkfrph53s3460xqxxamqcfqb2rxjrnpkck3rlcf";
    }) { };

in
{
  # Make sure to have NGiNX enabled
  services.nginx.enable = true;
  services.nginx.virtualHosts."hass.elis.nu" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyWebsockets = true;
    locations."/".proxyPass = "http://127.0.0.1:8123/";
  };

  # Enable Home Assistant, open port and add the hass user to the dialout group
  services.home-assistant = {
    enable = true;
    package = hpkgs.home-assistant;
    config = {
      # Basic settings
      homeassistant = {
        name = "Home";
        latitude = "!secret lat_coord";
        longitude = "!secret lon_coord";
        elevation = 22;
        unit_system = "metric";
        time_zone = "Europe/Stockholm";
      };

      # Discover some devices automatically
      discovery = { };

      # Show some system health data
      system_health = { };

      # Http settings
      http = {
        server_host = "127.0.0.1";
        base_url = "https://hass.elis.nu";
        use_x_forwarded_for = true;
        trusted_proxies = "127.0.0.1";
        server_port = 8123;
      };

      # Enables a map showing the location of tracked devies
      map = { };

      # Track the sun
      sun = { };

      # Include automations
      automation = [
        # Turn on the LED strip in the evening
        {
          id = "turn-on-evening-lights";
          alias = "Turn on evening lights";
          trigger = [
            {
              platform = "sun";
              event = "sunset";
              offset = "-00:45:00";
            }
          ];
          action.data.entity_id = [ "light.tv_wall_strip" ];
          action.service = "light.turn_on";
        }

        # Turn on the floor lamps in the evening
        {
          id = "turn-on-evening-switches";
          alias = "Turn on evening switches";
          trigger = [
            {
              platform = "sun";
              event = "sunset";
              offset = "-00:45:00";
            }
          ];
          action.data.entity_id = [ "switch.floorlamp_office" "switch.floorlamp_livingroom" ];
          action.service = "switch.turn_on";
        }

        # Turn off the floor lamps in the evening
        {
          id = "turn-off-evening-switches";
          alias = "Turn off evening switches";
          trigger = [
            { platform = "time"; at = "00:00:00"; }
            {
              platform = "state";
              entity_id = "switch.floorlamp_livingroom";
              to = "on";
              for.minutes = 30;
            }
            {
              platform = "state";
              entity_id = "switch.floorlamp_office";
              to = "on";
              for.minutes = 30;
            }
          ];
          condition = [
            {
              condition = "time";
              after = "00:00:00";
              before = "10:00:00";
            }
          ];
          action.data.entity_id = [ "switch.floorlamp_office" "switch.floorlamp_livingroom" ];
          action.service = "switch.turn_off";
        }

        # Turn off the LED strip in the evening
        {
          id = "turn-off-tv-wall-strip";
          alias = "Turn off TV Wall Strip";
          trigger = [
            { platform = "time"; at = "01:30:00"; }
          ];
          action.data.entity_id = [ "light.tv_wall_strip" ];
          action.service = "light.turn_off";
        }

        # Turn off hallway ceiling lamps timers
        {
          id = "turn-off-hallway-ceilinglamp-1-timer";
          alias = "Turn off hallway ceilinglamp 1 timer";
          trigger = [
            {
              platform = "state";
              entity_id = "light.ceilinglamp_hallway_1";
              for.minutes = 20;
              to = "on";
            }
          ];
          action.data.entity_id = [ "light.ceilinglamp_hallway_1" ];
          action.service = "light.turn_off";
        }
        {
          id = "turn-off-hallway-ceilinglamp-2-timer";
          alias = "Turn off hallway ceilinglamp 2 timer";
          trigger = [
            {
              platform = "state";
              entity_id = "light.ceilinglamp_hallway_2";
              for.minutes = 15;
              to = "on";
            }
          ];
          action.data.entity_id = [ "light.ceilinglamp_hallway_2" ];
          action.service = "light.turn_off";
        }

        # Turn on the other hallway lamp
        {
          id = "turn-on-other-hallway-ceilinglamp-1";
          alias = "Turn on other hallway ceilinglamp 1";
          trigger = [
            {
              platform = "state";
              entity_id = "light.ceilinglamp_hallway_1";
              to = "on";
            }
          ];
          action.data.entity_id = [ "light.ceilinglamp_hallway_2" ];
          action.service = "light.turn_on";
        }
        {
          id = "turn-on-other-hallway-ceilinglamp-2";
          alias = "Turn on other hallway ceilinglamp 2";
          trigger = [
            {
              platform = "state";
              entity_id = "light.ceilinglamp_hallway_2";
              to = "on";
            }
          ];
          action.data.entity_id = [ "light.ceilinglamp_hallway_1" ];
          action.service = "light.turn_on";
        }

        # Turn on media center power for updates in the evening
        {
          id = "turn-on-media-center-power-for-updates";
          alias = "Turn on media center power for updates";
          trigger = [
            { platform = "time"; at = "00:55:00"; }
          ];
          action.data.entity_id = [ "switch.media_center_power" ];
          action.service = "switch.turn_on";
        }
        {
          id = "turn-off-media-center-power";
          alias = "Turn off media center power";
          trigger = [
            { platform = "time"; at = "02:30:00"; }
          ];
          action.data.entity_id = [ "switch.media_center_power" ];
          action.service = "switch.turn_off";
        }
      ];

      # Include scripts
      script = "!include scripts.yaml";

      # ZWave
      zwave = {
        usb_path = "/dev/serial/by-id/usb-0658_0200-if00";
        network_key = "!secret zwave_network_key";
      };

      # ZHA
      zha = {
        # usb_path = "/dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2124653-if00";
        # radio_type = "deconz";
        database_path = "/var/lib/hass/zigbee.db";
        enable_quirks = false;
      };

      # Enable mobile app
      mobile_app = { };

      # Enable configuration UI
      config = { };

      # Make the ui configurable through ui-lovelace.yaml
      lovelace.mode = "yaml";
      lovelace.resources = [
        { url = "/local/vacuum-card.js";  type = "module"; }
      ];

      # Enable support for tracking state changes over time
      history = { };

      # Purge tracked history after 10 days
      recorder.purge_keep_days = 10;

      # View all events in o logbook
      logbook = { };

      # Automatic chromecast detection
      cast = [
        { media_player = { }; }
      ];

      # Media players
      media_player = [
        { platform = "kodi"; host = "kodi.lan"; }
      ];

      # Enable logging
      logger.default = "info";

      # Enable vacuum cleaner
      vacuum = [
        {
          name = "Jean-Luc";
          platform = "xiaomi_miio";
          host = "!secret vacuum_host";
          token = "!secret vacuum_token";
        }
      ];

      # Pull in weather data
      weather = [
        {
          platform = "openweathermap";
          api_key = "!secret openweathermap_api_key";
        }
      ];
    };
  };

  users.users.hass.extraGroups = [ "dialout" ];

  # Bind mount home assistants files to have persistence of hass configs
  fileSystems."/var/lib/hass" = {
    device = "/persistent/var/lib/hass";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };
}
