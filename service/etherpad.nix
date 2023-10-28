{ pkgs, ... }:

let vars = import ../vars.nix;

in
{
  users.users.etherpad = {
    isNormalUser = true;
    uid = 1001;
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
    bindsTo = [ "user@1001.service" ];
    after = [ "user@1001.service" ];
    serviceConfig = {
      User = "etherpad";
      WorkingDirectory = ./etherpad;
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
    wantedBy = [ "timers.target" ];
  };

  services.nginx.enable = true;
  services.nginx.virtualHosts."etherpad.${vars.tld}" = {
    forceSSL = true;
    enableACME = true;

    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:9001";
        proxyWebsockets = true;
        basicAuthFile = "/var/etherpad.auth";
      };
    };
  };
}
