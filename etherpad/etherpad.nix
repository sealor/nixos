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

  systemd.services.etherpad = {
    path = with pkgs; [ podman podman-compose "/run/wrappers" ];
    serviceConfig = {
      User = "etherpad";
      WorkingDirectory = ./.;
    };
    script = ''
      podman system prune --all --force --filter until=$((4*7*24))h
      podman-compose build --pull
      podman-compose up
    '';
    wantedBy = [ "default.target" ];
  };

  systemd.services.etherpad-clean-up = {
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      systemctl restart etherpad
    '';
  };

  systemd.timers.etherpad-clean-up = {
    timerConfig = {
      OnCalendar = "Fri 04:00:00";
      Unit = "etherpad-clean-up.service";
    };
    wantedBy = [ "default.target" ];
  };
}
