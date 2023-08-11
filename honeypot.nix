{ config, pkgs, ... }:

# see: https://gehirn-mag.net/fail2ban-honeypot-fuer-arme/
# status: fail2ban-client status honeypot
# common ports: https://de.wikipedia.org/wiki/Liste_der_standardisierten_Ports

let vars = import ./vars.nix;

in
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = vars.honeypotPorts;
  };

  systemd.sockets.fail2ban-honeypot = {
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = vars.honeypotPorts;
      Accept = true;
    };
  };

  systemd.services."fail2ban-honeypot@" = {
    serviceConfig = {
      ExecStart = "/bin/sh -c '${pkgs.util-linux}/bin/logger -t fail2ban-honeypot \"Connection from $REMOTE_ADDR $(${pkgs.lsof}/bin/lsof -Fn -P -w -i -a -p \$$\$$ | sed \"/^n/! d; s/^n//\" | tr \"\\n\" \" \")\"'";
    };
  };

  # debugging: fail2ban-regex -v -m SYSLOG_IDENTIFIER=fail2ban-honeypot systemd-journal "fail2ban-honeypot.*: Connection from <HOST>.*"
  # journalmatch fields: https://man.archlinux.org/man/systemd.journal-fields.7
  environment.etc."fail2ban/filter.d/honeypot.conf".text = ''
    [Definition]
    failregex = fail2ban-honeypot.*: Connection from <HOST>.*
    journalmatch = SYSLOG_IDENTIFIER=fail2ban-honeypot
  '';

  services.fail2ban = {
    enable = true;
    jails = {
      honeypot = ''
        enabled = true
        filter = honeypot
        maxretry = 1
      '';
    };
  };
}
