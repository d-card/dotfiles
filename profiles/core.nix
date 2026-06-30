{
  pkgs,
  inputs,
  ...
}: {
  nix = {
    # Improve nix store disk usage
    gc = {
      automatic = true;
      randomizedDelaySec = "30min";
      dates = "03:15";
    };

    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      unstable.flake = inputs.unstable;
    };

    # Generally useful nix option defaults
    settings = {
      keep-outputs = true;
      keep-derivations = true;
      fallback = true;
      experimental-features = ["nix-command" "flakes"];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      # Editors
      neovim

      # Networking
      whois

      # Misc
      tmux
      curl
      git
      lsof
      ripgrep
      tree
      fastfetch
    ];
  };
  boot.supportedFilesystems = [];
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.editor = false;
    efi.canTouchEfiVariables = true;
  };


  time.timeZone = "Europe/Lisbon";
  nix.settings.trusted-users = ["root" "@wheel"];
  programs.zsh.enable = true;
  security.sudo.wheelNeedsPassword = false;
  users = {
    mutableUsers = true;
    users.dcard = {
      isNormalUser = true;
      initialPassword = "hunter2";
      createHome = true;
      shell = pkgs.zsh;
      extraGroups = ["wheel"];
    };
  };
}
