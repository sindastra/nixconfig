{
  description = "etu/nixconfig";

  inputs = {
    # Emacs Overlay
    emacs-overlay.url = "github:nix-community/emacs-overlay";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS hardware quirks
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Main nixpkgs channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Wayland overlay
    wayland.url = "github:colemickens/nixpkgs-wayland";
    wayland.inputs.nixpkgs.follows = "nixpkgs";

    # Persistance things
    impermanence.url = "https://github.com/nix-community/impermanence/archive/8fc761e8c34.tar.gz";
    impermanence.flake = false;
  };

  outputs = inputs:
    let
      mkSystem = system: pkgs': hostname:
        pkgs'.lib.nixosSystem {
          inherit system;
          modules = [ (./. + "/hosts/${hostname}/configuration.nix") ];
          specialArgs = { inherit inputs; };
        };
    in
    {
      nixosConfigurations.agrajag = mkSystem "x86_64-linux" inputs.nixpkgs "agrajag";
      nixosConfigurations.fenchurch = mkSystem "x86_64-linux" inputs.nixpkgs "fenchurch";

      devShell.x86_64-linux = import ./shell.nix { pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux; };
      devShell.aarch64-linux = import ./shell.nix { pkgs = inputs.nixpkgs.legacyPackages.aarch64-linux; };
    };
}
