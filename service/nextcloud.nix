{ config, pkgs, ...}:

let vars = import ../vars.nix;

in
{
  services.prometheus.exporters.nextcloud = {
    enable = true;
    user = "nextcloud";
    url = "https://nextcloud.${vars.tld}";
    username = "root";
    passwordFile = "/var/nextcloud.auth";
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "nextcloud";
      static_configs = [{
        targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.nextcloud.port}" ];
      }];
    }
  ];

  services.nextcloud = {
    enable = true;
    https = true;
    package = pkgs.nextcloud30;
    hostName = "nextcloud.${vars.tld}";
    config.adminpassFile = "/var/nextcloud.auth";

  };

  services.nginx.enable = true;
  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };
}
