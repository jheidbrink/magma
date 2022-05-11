# I'm currently invoking shell.nix like this: pkill --full 'bazel.*workspace_directory=/home/heidbrij/repositories/github.com/jheidbrink/magma'; while pgrep --full 'bazel.*workspace_directory=/home/heidbrij/repositories/github.com/jheidbrink/magma'; do sleep 0.03; done; echo 'bazel build --sandbox_debug --define=folly_so=1 //orc8r/gateway/python/magma/magmad:magmad' | nix-shell --pure
{ pkgs ? import <nixpkgs> {} }:
let
  bazel = pkgs.writers.writeDashBin "bazel" ''
    export GIT_SSL_CAINFO="/etc/ssl/certs/ca-bundle.crt"
    ${pkgs.bazel_4}/bin/bazel $@
  '';  # ca-bundle.crt is provided by cacert package and put into place by buildFHSUserEnv. It's needed by git in order to clone/fetch.
in
(pkgs.buildFHSUserEnv {
  name = "magma";
  targetPkgs = pkgs: [
    bazel
    pkgs.systemd.dev  # found via `nix-locate sd-daemon.h`, required for build Python wheel systemd
    pkgs.gcc
    pkgs.python38
    pkgs.git
    pkgs.cacert
    pkgs.zlib  # required by jdk
    pkgs.jdk11_headless
    # Debug tools
    pkgs.which
    pkgs.glibc.bin  # for ldd
    pkgs.binutils  # for readelf
    pkgs.cmake  # for cc_binary targets
    pkgs.folly  # C++ library (still) used by Magma
  ];
}).env
