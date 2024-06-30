{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  libselinux,
  cargo,
  rustc,
  makeWrapper,
  crun,
}:
stdenv.mkDerivation rec {
  pname = "crun-vm";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "containers";
    repo = pname;
    rev = version;
    hash = "sha256-49JS3Sy5CQM8qe4WdHiI3GZqsutB3AtGn+4cYPZYgIU=";
  };

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    name = "${pname}-${version}";
    hash = "sha256-qror+6VO/amafpjOH2A4y8VrVOlrpvoIAHZUwEkFD2Y=";
  };

  buildInputs = [ libselinux ];

  nativeBuildInputs = [
    cargo
    rustPlatform.cargoSetupHook
    rustc
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out
    cp -r bin $out/bin
    wrapProgram $out/bin/crun-vm --prefix PATH : ${lib.makeBinPath [ crun ]}
  '';

  meta = {
    mainProgram = "crun-vm";
  };
}
