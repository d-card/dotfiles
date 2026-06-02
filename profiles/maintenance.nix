{pkgs, ...}: let
  maxwellDeploy = pkgs.writeShellScriptBin "maxwell-deploy" ''
    set -euo pipefail

    cd "''${1:-$HOME/git/dotfiles}"
    git pull --ff-only
    nixos-rebuild switch --flake .#maxwell --target-host maxwell --use-remote-sudo
  '';
in {
  environment.systemPackages = [maxwellDeploy];

  nix = {
    optimise = {
      automatic = true;
      dates = ["04:15"];
    };

    gc = {
      automatic = true;
      dates = "03:15";
      options = "--delete-older-than 14d";
      randomizedDelaySec = "30min";
    };
  };

  virtualisation.docker.autoPrune = {
    enable = true;
    dates = "weekly";
    flags = [
      "--all"
      "--filter=until=168h"
    ];
    randomizedDelaySec = "30min";
  };
}
