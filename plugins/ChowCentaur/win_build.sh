#!/bin/bash

set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
SDK_PATH="$(pwd)/SDKs"

# clone git repo
name=$(jq -r '.namerepo' "$DIR/metadata.json")
repo=$(jq -r '.repo' "$DIR/metadata.json")
hash=$(jq -r '.hash' "$DIR/metadata.json")
git clone "$repo" "$name"
cd "$name"
git checkout "$hash"
git submodule update --init --recursive

# set up SDK paths
sed -i -e "19s~.*~juce_set_vst2_sdk_path(${SDK_PATH}/VST2_SDK)~" CMakeLists.txt
sed -i -e "20s~.*~include_directories(${SDK_PATH}/ASIO_SDK/common)~" CMakeLists.txt
sed -i -e '5s/#//' ChowCentaur/CMakeLists.txt
sed -i -e '42s/#//' ChowCentaur/CMakeLists.txt

# build Win64
cmake -Bbuild -G"Visual Studio 16 2019 -A x64"
cmake --build build --config Release --parallel

# build Win32
cmake -Bbuild32 -G"Visual Studio 16 2019 -A Win32"
cmake --build build32 --config Release --parallel

# copy builds to bin
echo "Copying builds..."
mkdir -p bin/Win64
mkdir -p bin/Win32

cp -R "build/${name}/${name}_artefacts/Release/Standalone/${name}.exe" "bin/Win64/${name}.exe"
cp -R "build/${name}/${name}_artefacts/Release/VST/${name}.dll" "bin/Win64/${name}.dll"
cp -R "build/${name}/${name}_artefacts/Release/VST3/${name}.vst3" "bin/Win64/${name}.vst3"

cp -R "build32/${name}/${name}_artefacts/Release/Standalone/${name}.exe" "bin/Win32/${name}.exe"
cp -R "build32/${name}/${name}_artefacts/Release/VST/${name}.dll" "bin/Win32/${name}.dll"
cp -R "build32/${name}/${name}_artefacts/Release/VST3/${name}.vst3" "bin/Win32/${name}.vst3"

# create installer
echo "Creating installer..."
script_file=Installer/windows/ChowCentaur_Install_Script.iss

version=$(cut -f 2 -d '=' <<< "$(grep 'CMAKE_PROJECT_VERSION:STATIC' build/CMakeCache.txt)")
echo "Setting app version: $version..."
sed -i "s/##APPVERSION##/${version}/g" $script_file

# build installer
echo "Building..."
iscc $script_file

# copy installer to products
cp Installer/windows/exec="ChowCentaur-Win-$version.exe" ../products/
