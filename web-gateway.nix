{config, ...}:

{
  services.nginx.enable = true;
  services.nginx.virtualHosts._.locations = {
    "= /prometheus".return = "302 '/prometheus/graph?"
      + "g0.expr=sum by(state)(node_systemd_unit_state)&g0.tab=1&g0.stacked=0&g0.show_exemplars=0&g0.range_input=4w&"
      + "g1.expr=100 - (avg by (instance) (rate(node_cpu_seconds_total{job%3D\"node\"%2Cmode%3D\"idle\"}[2m])) * 100)&g1.tab=1&g1.stacked=0&g1.show_exemplars=0&g1.range_input=6h'";

    "/prometheus/" = {
      proxyPass = "http://127.0.0.1:9090/prometheus/";
      basicAuthFile = "/var/prometheus.auth";
    };

    "/etherpad/" = {
      proxyPass = "http://127.0.0.1:9001/";
      proxyWebsockets = true;
      basicAuthFile = "/var/etherpad.auth";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
