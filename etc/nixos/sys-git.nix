{ pkgs, ... }:

let sys-git = pkgs.writeScriptBin "sys-git" ''
  #!${pkgs.stdenv.shell}
  git --git-dir=/etc/nixos/sys.git --work-tree=/ -c core.excludesFile=/etc/sys-git-global-ignore "$@"
'';

in {
  environment.systemPackages = with pkgs; [ git sys-git ];
  environment.etc."sys-git-global-ignore".text = "*\n";
}
