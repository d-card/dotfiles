{
  description = "My NixOS personal config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
      inputs.home-manager.follows = "";
    };
  };

  outputs = {
    nixpkgs,
    unstable,
    disko,
    agenix,
    ...
  } @ inputs: let
    lib = nixpkgs.lib.extend (self: super:
      import ./lib {
        inherit inputs profiles pkgs nixosConfigurations secrets;
        lib = self;
      });

    overlays = lib.personal.mkOverlays ./overlays;
    pkgs = lib.personal.mkPkgs overlays;
    nixosConfigurations = lib.personal.mkHosts ./hosts;
    profiles = lib.personal.mkProfiles ./profiles;
    secrets = lib.personal.mkSecrets ./secrets;
  in {
    inherit nixosConfigurations overlays;

    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        agenix.packages.x86_64-linux.default
        disko.packages.x86_64-linux.disko
        nixos-anywhere
      ];
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
