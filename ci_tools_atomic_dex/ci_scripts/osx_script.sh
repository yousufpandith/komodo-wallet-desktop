#!/bin/bash

# Workaround for https://github.com/actions/setup-python/issues/577
brew update
brew install autoconf \
            automake \
            pkgconfig \
            wget \
            nim \
            ninja \
            gnu-sed \
            coreutils \
            libtool \
            gnu-getopt \
            cmake \
            llvm

brew unlink python@3.12
brew link --overwrite python@3.12

# macOS 14 blocks global pip installs. Use --break-system-packages for CI environments.
pip3 install yq --break-system-packages

# Set up architecture and compiler variables for Apple Silicon (M-Series)
export CC="/opt/homebrew/opt/llvm/bin/clang"
export CXX="/opt/homebrew/opt/llvm/bin/clang++"
export MACOSX_DEPLOYMENT_TARGET=14.0

# FORCE CMake and vcpkg to target Apple Silicon instead of Intel
export CMAKE_OSX_ARCHITECTURES="arm64"
export VCPKG_DEFAULT_TRIPLET="arm64-osx"
export CFLAGS="-arch arm64"
export CXXFLAGS="-arch arm64"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

# If running in GitHub Actions, persist these variables to the next steps
if [ -n "$GITHUB_ENV" ]; then
  echo "CC=/opt/homebrew/opt/llvm/bin/clang" >> $GITHUB_ENV
  echo "CXX=/opt/homebrew/opt/llvm/bin/clang++" >> $GITHUB_ENV
  echo "MACOSX_DEPLOYMENT_TARGET=14.0" >> $GITHUB_ENV
  echo "CMAKE_OSX_ARCHITECTURES=arm64" >> $GITHUB_ENV
  echo "VCPKG_DEFAULT_TRIPLET=arm64-osx" >> $GITHUB_ENV
  echo "CFLAGS=-arch arm64" >> $GITHUB_ENV
  echo "CXXFLAGS=-arch arm64" >> $GITHUB_ENV
  echo "LDFLAGS=-L/opt/homebrew/opt/llvm/lib" >> $GITHUB_ENV
  echo "CPPFLAGS=-I/opt/homebrew/opt/llvm/include" >> $GITHUB_ENV
fi

# Build libwally-core (Now compiling for ARM64)
git clone -b v0.8.5 https://github.com/KomodoPlatform/libwally-core.git --recurse-submodules
cd libwally-core
./tools/autogen.sh
./configure --host=aarch64-apple-darwin --disable-shared
sudo make -j3 install
cd ..

# get SDKs
git clone https://github.com/KomodoPlatform/MacOSX-SDKs $HOME/sdk
