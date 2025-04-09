#!/bin/bash

set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
SDK_PATH="$(pwd)/SDKs"
VST_SDK="D:${SDK_PATH:2}/VST2_SDK"
AAX_BUILDS_PATH="$(pwd)/aax_builds"

# clone git repo
name=$(jq -r '.name' "$DIR/metadata.json")
repo=$(jq -r '.repo' "$DIR/metadata.json")
hash=$(jq -r '.hash' "$DIR/metadata.json")
echo "Pulling $name from $repo at commit $hash"

git clone "$repo" "$name"
cd "$name"
git checkout "$hash"
git submodule update --init --recursive

# set up SDK paths
cd Plugin
sed -i -e "s~# juce_set_vst2_sdk_path.*~juce_set_vst2_sdk_path(${VST_SDK})~" CMakeLists.txt

# build Win64
cmake -Bbuild -G"Visual Studio 17 2022" -A x64
cmake --build build --config Release --parallel 4

# build Win32
cmake -Bbuild32 -G"Visual Studio 17 2022" -A Win32
cmake --build build32 --config Release --parallel 4

# copy builds to bin
echo "Copying builds..."
mkdir -p bin/Win64
mkdir -p bin/Win32

plugin=CHOWTapeModel
cp -R "build/${plugin}_artefacts/Release/Standalone/${plugin}.exe" "bin/Win64/${plugin}.exe"
cp -R "build/${plugin}_artefacts/Release/VST/${plugin}.dll" "bin/Win64/${plugin}.dll"
cp -R "build/${plugin}_artefacts/Release/VST3/${plugin}.vst3" "bin/Win64/${plugin}.vst3"
cp -R "build/${plugin}_artefacts/Release/CLAP/${plugin}.clap" "bin/Win64/${plugin}.clap"

# @FIXME
cp -R "build/${plugin}_artefacts/Release/VST3/${plugin}.vst3" "bin/Win64/${plugin}.aaxplugin"
# cp -R "${AAX_BUILDS_PATH}/${name}.aaxplugin" "bin/Win64/${name}.aaxplugin"

cp -R "build32/${plugin}_artefacts/Release/Standalone/${plugin}.exe" "bin/Win32/${plugin}.exe"
cp -R "build32/${plugin}_artefacts/Release/VST/${plugin}.dll" "bin/Win32/${plugin}.dll"
cp -R "build32/${plugin}_artefacts/Release/VST3/${plugin}.vst3" "bin/Win32/${plugin}.vst3"
cp -R "build32/${plugin}_artefacts/Release/CLAP/${plugin}.clap" "bin/Win32/${plugin}.clap"

# extract version for installer
version=$(cut -f 2 -d '=' <<< "$(grep 'CMAKE_PROJECT_VERSION:STATIC' build/CMakeCache.txt)")
echo "Setting app version: $version..."

# create installer
echo "Creating 64-bit installer..."
script_file=Installers/windows/ChowTapeModel_Install_Script.iss
sed -i "s/##APPVERSION##/${version}/g" $script_file
iscc $script_file

# create installer (32-bit)
echo "Creating 32-bit installer..."
script_file=Installers/windows/ChowTapeModel_Install_Script_32bit.iss
sed -i "s/##APPVERSION##/${version}/g" $script_file
iscc $script_file

AzureSignTool sign \
    -kvu "$AZURE_KEY_VAULT_URI" \
    -kvi "$AZURE_CLIENT_ID" \
    -kvt "$AZURE_TENANT_ID" \
    -kvs "$AZURE_CLIENT_SECRET" \
    -kvc "$AZURE_CERT_NAME" \
    -tr http://timestamp.digicert.com \
    -v "Installers/windows/ChowTapeModel-Win-${version}.exe"

AzureSignTool sign \
    -kvu "$AZURE_KEY_VAULT_URI" \
    -kvi "$AZURE_CLIENT_ID" \
    -kvt "$AZURE_TENANT_ID" \
    -kvs "$AZURE_CLIENT_SECRET" \
    -kvc "$AZURE_CERT_NAME" \
    -tr http://timestamp.digicert.com \
    -v "Installers/windows/ChowTapeModel-Win-32bit-${version}.exe"

# copy installer to products
cp Installers/windows/"ChowTapeModel-Win-$version.exe" ../../products/"ChowTapeModel-Win-64bit-$version.exe" 
cp Installers/windows/"ChowTapeModel-Win-32bit-$version.exe" ../../products/"ChowTapeModel-Win-32bit-$version.exe"
