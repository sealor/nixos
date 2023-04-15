{ pkgs, ... }:

{
  users.users.etherpad = {
    isNormalUser = true;
  };

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  virtualisation.podman.enable = true;

  systemd.user.services.etherpad = {
    requires = [ "podman.socket" ];
    environment = {
      # TODO: make XDG_RUNTIME_DIR work instead of /run/user/1001
      DOCKER_HOST = "unix:///run/user/1001/podman/podman.sock";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = ./.;
      ExecStart = [
        "${pkgs.docker-compose}/bin/docker-compose build --pull"
        "${pkgs.docker-compose}/bin/docker-compose up -d"
      ];
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
    };
    wantedBy = [ "default.target" ];
  };

  systemd.user.services.etherpad-clean-up = {
    requires = [ "podman.socket" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.podman}/bin/podman system prune --force";
    };
  };

  systemd.user.timers.etherpad-clean-up = {
    timerConfig = {
      OnCalendar = "Fri 04:00:00";
      Unit = "etherpad-clean-up.service";
    };
    wantedBy = [ "default.target" ];
  };

  system.activationScripts = {
    enableEtherpadLingering = "touch /var/lib/systemd/linger/etherpad";
  };
}
