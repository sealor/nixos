{config, pkgs, ...}:

{
  # http://45.91.101.202:9090/graph?g0.expr=sum%20by(state)(node_systemd_unit_state)&g0.range_input=4w
  services.prometheus = {
    enable = true;

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

  # networking.firewall.allowedTCPPorts = [ 9090 ];
}
