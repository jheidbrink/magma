# Inspired by https://nixos.wiki/wiki/Python#mkShell

{ pkgs ? import <nixpkgs> {} }:
let
  my-python = pkgs.python39;
  python-with-my-packages = my-python.withPackages (p: with p; [
    boto3
  ]);
in
pkgs.mkShell {
  buildInputs = [
    pkgs.aws-vault
    pkgs.ansible
    python-with-my-packages
  ];
  shellHook = ''
    PYTHONPATH=${python-with-my-packages}/${python-with-my-packages.sitePackages}
  '';
}
