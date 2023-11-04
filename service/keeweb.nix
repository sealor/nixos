{config, pkgs, ...}:

let vars = import ../vars.nix;

in
{
  # https://keeweb.info/
  # https://github.com/keeweb/keeweb/tree/gh-pages v1.18.7
  services.nginx.enable = true;
  services.nginx.virtualHosts."keeweb.${vars.tld}" = {
    forceSSL = true;
    enableACME = true;

    locations = {
      "/" = {
        root = "/run/keeweb/";
        basicAuthFile = "/var/keeweb.auth";
        extraConfig = ''
          dav_methods PUT DELETE MKCOL COPY MOVE;
          dav_ext_methods PROPFIND OPTIONS;
          dav_access user:rw group:rw all:r;
          client_body_temp_path /var/cache/nginx;
          create_full_put_path on;
        '';
      };
    };
  };
}
