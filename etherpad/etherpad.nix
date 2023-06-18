{ pkgs, ... }:

{
  users.users.etherpad = {
    isNormalUser = true;
  };

  environment.systemPackages = with pkgs; [
    podman podman-compose
  ];
  environment.etc."containers/registries.conf".text = ''
    unqualified-search-registries = [ "docker.io" ]
  '';
  environment.etc."containers/policy.json".text = ''
    {"default":[{"type":"insecureAcceptAnything"}]}
  '';

  # virtualisation.podman.enable = true;

  systemd.user.services.etherpad = {
    # requires = [ "podman.socket" ];
    # environment = {
    #   # TODO: make XDG_RUNTIME_DIR work instead of /run/user/1001
    #   DOCKER_HOST = "unix:///run/user/1001/podman/podman.sock";
    # };
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = ./.;
      ExecStart = [
        "${pkgs.podman-compose}/bin/podman-compose build --pull"
        "${pkgs.podman-compose}/bin/podman-compose up -d"
      ];
      ExecStop = "${pkgs.podman-compose}/bin/podman-compose down";
    };
    wantedBy = [ "default.target" ];
  };

  systemd.user.services.etherpad-clean-up = {
    # requires = [ "podman.socket" ];
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
