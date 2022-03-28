{ pkgs ? import <nixpkgs> {} }:
(pkgs.buildFHSUserEnv {
  name = "magma";
  targetPkgs = pkgs: [
    pkgs.bazel_4
  ];
}).env
