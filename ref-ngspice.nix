# Copyright 2024 Efabless Corporation
#
{
  lib,
  clangStdenv,
  fetchurl,
  flex,
  bison,
  fftw,
  withNgshared ? true,
  xorg,
  autoconf269,
  automake,
  libtool,
  readline,
  llvmPackages,
  version ? "44",
  sha256 ? "sha256-OGXROrRPHwH2jHrA4HFphORdzlqG0SZgPCbY3zAWHps=",
}:
clangStdenv.mkDerivation {
  pname = "ngspice";
  inherit version;

  src = fetchurl {
    url = "mirror://sourceforge/ngspice/ngspice-${version}.tar.gz";
    inherit sha256;
  };

  nativeBuildInputs = [
    flex
    bison
    autoconf269
    automake
    libtool
  ];

  buildInputs = [
    fftw
    xorg.libXaw
    xorg.libXext
    readline
    llvmPackages.openmp
  ];

  configureFlags = [
    "--with-x"
    "--enable-xspice"
    "--enable-cider"
    "--enable-predictor"
    "--enable-osdi"
    "--enable-klu"
    "--with-readline=${readline.dev}"
    "--enable-openmp"
  ];

  # This adds a dummy cpp file to ngspice_SOURCES, which forces automake to use
  # CXXLD as `-lstdc++` doesn't work on macOS -- feel free to replace this with
  # a more proper solution.
  preConfigure = ''
    set -x
    echo "" > src/dummy.cpp
    sed -i "s@\tngspice.c@\tngspice.c \\\\\n\tdummy.cpp@" ./src/Makefile.am
    autoreconf -i
    set +x
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "The Next Generation Spice (Electronic Circuit Simulator)";
    homepage = "http://ngspice.sourceforge.net";
    license = with licenses; [bsd3 gpl2Plus lgpl2Plus]; # See https://sourceforge.net/p/ngspice/ngspice/ci/master/tree/COPYING
    platforms = platforms.linux ++ platforms.darwin;
  };
}
