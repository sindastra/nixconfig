{ pkgs, ... }:

let
  # Load sources
  sources = import ../nix/sources.nix;
in {
  imports = [
    "${sources.agenix}/modules/age.nix"
    "${sources.impermanence}/nixos.nix"
    "${sources.ip-failar-nu}/nixos.nix"
    "${sources.flummbot}/nixos.nix"
    ./my-allow-unfree.nix
    ./my-backup.nix
    ./my-common-cli.nix
    ./my-common-graphical.nix
    ./my-deploy-user.nix
    ./my-emacs.nix
    ./my-fonts.nix
    ./my-gaming.nix
    ./my-gpg-utils.nix
    ./my-home-manager.nix
    ./my-nfsd.nix
    ./my-options.nix
    ./my-spell.nix
    ./my-sway.nix
    ./my-user.nix
    ./my-vbox.nix
  ];
}
