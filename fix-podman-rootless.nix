{ pkgs, ... }:

{
  # see: https://discourse.nixos.org/t/how-can-i-improve-the-podman-user-service/27925
  systemd.packages = [
    (pkgs.runCommandNoCC "toplevel-overrides.conf" {
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      mkdir -p $out/etc/systemd/user/podman.service.d/
      echo -e "[Service]\nKillMode=control-group" > $out/etc/systemd/user/podman.service.d/overrides.conf
    '')
  ];
}
