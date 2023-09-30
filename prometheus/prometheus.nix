{config, pkgs, ...}:

let vars = import ../vars.nix;

in
{
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

  services.nginx.enable = true;
  services.nginx.virtualHosts."prometheus.${vars.tld}" = {
    forceSSL = true;
    enableACME = true;

    locations = {
      "~ ^/$".return = "302 '/graph?"
      + "g0.expr=sum_over_time(node_systemd_unit_state{state%3D\"active\"%2Cname%3D~\".*service\"}[20m])&g0.tab=0&g0.stacked=0&g0.show_exemplars=0&g0.range_input=3h&"
      + "g1.expr=100 - (avg by (instance) (rate(node_cpu_seconds_total{job%3D\"node\"%2Cmode%3D\"idle\"}[2m])) * 100)&g1.tab=1&g1.stacked=0&g1.show_exemplars=0&g1.range_input=6h'";

      "~ ^/.+$" = {
        proxyPass = "http://127.0.0.1:9090";
        basicAuthFile = "/var/prometheus.auth";
      };
    };
  };
}
