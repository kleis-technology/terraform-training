let
  pkgs = import <nixpkgs> { };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    opentofu
    awscli2
    tofu-ls
  ];
}
