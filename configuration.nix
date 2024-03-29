# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let vars = import ./vars.nix;
# VPS: https://contabo.com/de (200GB HDD, 8 GB RAM, 5,99€/m)

in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./honeypot.nix
      ./fix-podman-rootless.nix
      ./nginx-settings.nix
      ./service/etherpad.nix
      ./service/prometheus.nix
      ./service/nextcloud.nix
      ./service/keeweb.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/xvda"; # or "nodev" for efi only

  zramSwap = {
    enable = true;
    memoryPercent = 200;
  };

  swapDevices = [{
    device = "/.swapfile";
    size = 2048;
  }];

  networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking.useDHCP = false;
  networking.nameservers = vars.nameservers;
  networking.interfaces.enX0.ipv4 = {
    addresses = [{
      address = vars.ipv4;
      prefixLength = vars.ipv4-cidr;
    }];
    routes = [{
      address = "0";
      prefixLength = 0;
      via = vars.ipv4-gw;
    }];
  };
  networking.firewall.allowedTCPPorts = vars.allowedTCPPorts;

  # Let's encrypt
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "admin+acme@${vars.tld}";

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  services.fail2ban = {
    enable = true;
    ignoreIP = [
      (vars.ipv4-gw + "/" + toString vars.ipv4-cidr)
    ];
    maxretry = 5;
    bantime = "1d";
  };

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "de";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=200M
    SystemMaxFileSize=5M
  '';
  

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = {
  #   "eurosign:e";
  #   "caps:escape" # map caps to escape.
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.stefan = {
    isNormalUser = true;
    initialPassword = "pwd123";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    (neovim.override {
      vimAlias = true;
      configure = {
        packages.myPlugins = with pkgs.vimPlugins; {
          start = [ vim-lastplace vim-nix ];
        };
        customRC = ''
          set background=light
          set hidden
          set autoindent
          set expandtab tabstop=2
          set list
          set listchars="tab:| ,trail:?,eof:."
          set mouse=
        '';
        };
      }
    )
    tmux
    wget
    git
    fzf ripgrep
  ];

  environment.variables.VISUAL = "vim";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "Mon *-*-* 04:00";
  };

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 60d";
  };

  systemd = {
    timers.weekly-reboot = {
      timerConfig = {
        OnCalendar = "Mon *-*-* 04:45";
        Unit = "reboot.target";
      };
      wantedBy = [ "timers.target" ];
    };
  };
  
  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}

