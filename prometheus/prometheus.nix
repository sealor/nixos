{config, pkgs, ...}:

{
  services.prometheus = {
    enable = true;
    webExternalUrl = "/prometheus";

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
  };
}
