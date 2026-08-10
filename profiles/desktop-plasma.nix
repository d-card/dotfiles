{pkgs, ...}: {
  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.variant = "intl";
    };

    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;

    dbus.packages = [pkgs.dconf];
    gnome.gnome-keyring.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  security.rtkit.enable = true;

  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    wqy_zenhei
  ];

  programs = {
    dconf.enable = true;
    firefox.enable = true;
    steam.enable = true;
  };

  environment.systemPackages = with pkgs; [
    alacritty
    brave
    discord
    libreoffice
    mattermost-desktop
    obs-studio
    pavucontrol
    spotify
    stremio-linux-shell
    thunderbird
    vlc
    vscode-fhs
    zathura
  ];
}
