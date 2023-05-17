{ pkgs, ... }:

# see: https://discourse.nixos.org/t/how-can-i-improve-the-podman-user-service/27925

let
  my-podman = pkgs.podman.overrideAttrs (finalAttrs: previousAttrs: {
    postPatch = ''
      cat contrib/systemd/user/podman.service.in
      substituteInPlace contrib/systemd/user/podman.service.in --replace KillMode=process KillMode=control-group
      cat contrib/systemd/user/podman.service.in
    '';
  });
in
{
  virtualisation.podman.package = my-podman;
}
