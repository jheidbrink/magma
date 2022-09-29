let pkgs = import <nixpkgs> {};

magma_root_path = ../..;
orc8r_protos = import (magma_root_path + "/orc8r/protos/default.nix");

mconfigs_proto_path = ./mconfig/mconfigs.proto;

lte_protos = {

  "mconfigs_proto" = pkgs.runCommand "mconfigs_proto" {} ''
    # dependencies:
    mkdir -p $out
    cp -r ${orc8r_protos.common_proto}/* $out/

    # and the actual proto:
    mkdir -p $out/lte/protos/mconfig
    cp ${mconfigs_proto_path} $out/lte/protos/mconfig/mconfigs.proto
  '';

  "mconfigs_py_proto" = pkgs.runCommand "mconfigs_pb2_py" {} ''
    mkdir -p $out
    cp ${mconfigs_proto_path} mconfigs.proto

    echo ${orc8r_protos.common_proto}
    ${pkgs.tree}/bin/tree ${orc8r_protos.common_proto}
    cp -r ${orc8r_protos.common_proto}/* ./
    mkdir -p $out/lte/protos/mconfig
    ${pkgs.grpc-tools}/bin/protoc --python_out=$out/lte/protos/mconfig mconfigs.proto


    echo "heelo"
    ls -l $out

    echo ${orc8r_protos.common_proto_py}
    cp -r ${orc8r_protos.common_proto_py}/* $out/


    # the lte folder in $out is writeable, but the protos folder isn't. Why not?
    #   - with cp -r, permissions shouldn't be copied

    echo I think we also need the proto files themselves:
    echo ${lte_protos.mconfigs_proto}
    ${pkgs.tree}/bin/tree ${lte_protos.mconfigs_proto}
    echo "Out folder ($out)"
    ${pkgs.tree}/bin/tree $out
    ls -l $out/
    ls -l $out/lte
    ls -l $out/orc8r
    ls -l $out/orc8r/protos
    cp -r ${lte_protos.mconfigs_proto}/* $out/
  '';
};

in

lte_protos
