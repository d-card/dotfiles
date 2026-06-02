{pkgs, ...}: {
  services.xserver = {
    enable = true;
    xkb.layout = "us-intl";
    displayManager = {
      defaultSession = "user-xsession";
      session = [
        {
          name = "user-xsession";
          manage = "desktop";
          start = ''
            exec i3
          '';
        }
      ];
      lightdm = {
        enable = true;
        extraConfig = ''
          set logind-check-graphical=true
        '';
        greeters.slick = {
          enable = true;
          theme = {
            package = pkgs.solarc-gtk-theme;
            name = "SolArc";
          };
          iconTheme = {
            package = pkgs.papirus-icon-theme;
            name = "Papirus-Dark";
          };
        };
      };
    };
    windowManager.i3 = {
      enable = true;
    };
  };

  # Required for gtk
  services.dbus.packages = [pkgs.dconf];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  # rtkit is optional but recommended
  security.rtkit.enable = true;

  services = {
    #picom = {
    #  enable = true;
    #  vSync = true;
    #};
    redshift = {
      enable = true;
      temperature = {
        day = 4000;
        night = 2500;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    alacritty
    arandr
    brave
    vscode-fhs
    (discord.override {
      withOpenASAR = true; # less tracking and faster loading
    })
    dunst
    feh
    flameshot
    lf
    libreoffice
    pavucontrol
    spotify
    thunderbird
    vlc
    zathura
  ];

  services.gnome.gnome-keyring.enable = true;
  users.users.dcard.extraGroups = ["video"];
}
