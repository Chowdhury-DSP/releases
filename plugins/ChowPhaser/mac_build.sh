#!/bin/bash

set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
SDK_PATH="$(pwd)/SDKs"

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
sed -i -e "s~# juce_set_vst2_sdk_path.*~juce_set_vst2_sdk_path(${SDK_PATH}/VST2_SDK)~" CMakeLists.txt
sed -i -e 's/#.*VST/VST/' CMakeLists.txt

# build Win64
cmake -Bbuild -GXcode -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="Developer ID Application" \
    -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM="$TEAM_ID" \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_STYLE="Manual" \
    -D"CMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    -DCMAKE_XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS="--timestamp" \
    -DMACOS_RELEASE=ON
cmake --build build --config Release --parallel 4 | xcpretty

# copy builds to bin
echo "Copying builds..."
mkdir -p bin/Mac

declare -a plugins=("ChowPhaserMono" "ChowPhaserStereo")
for plugin in "${plugins[@]}"; do
    cp -R "build/${plugin}_artefacts/Release/Standalone/${plugin}.app" "bin/Mac/${plugin}.app"
    cp -R "build/${plugin}_artefacts/Release/VST/${plugin}.vst" "bin/Mac/${plugin}.vst"
    cp -R "build/${plugin}_artefacts/Release/VST3/${plugin}.vst3" "bin/Mac/${plugin}.vst3"
    cp -R "build/${plugin}_artefacts/Release/AU/${plugin}.component" "bin/Mac/${plugin}.component"
done

# create installer
echo "Creating installer..."
script_file=installers/mac/ChowPhaser.pkgproj

version=$(cut -f 2 -d '=' <<< "$(grep 'CMAKE_PROJECT_VERSION:STATIC' build/CMakeCache.txt)")
echo "Setting app version: $version..."
sed -i '' "s/##APPVERSION##/${version}/g" $script_file
sed -i '' "s/##APPVERSION##/${version}/g" installers/mac/Intro.txt

echo "Copying License..."
cp LICENSE Installers/mac/LICENSE.txt

# build installer
echo Building...
packagesbuild $script_file

# sign the installer package
echo "Signing installer package..."
pkg_dir=ChowPhaser_Installer_Packaged
mkdir $pkg_dir
productsign -s "$TEAM_ID" build/ChowPhaser.pkg $pkg_dir/ChowPhaser-signed.pkg

echo "Notarizing installer package..."
npx notarize-cli --file $pkg_dir/ChowPhaser-signed.pkg \
    --bundle-id com.chowdsp.ChowPhaser \
    --username chowdsp@gmail.com \
    --password "$INSTALLER_PASS" \
    --asc-provider "$TEAM_ID"

echo "Building disk image..."
vol_name=ChowPhaser-Mac-$version
hdiutil create "$vol_name.dmg" -fs HFS+ -srcfolder $pkg_dir -format UDZO -volname "$vol_name"

# copy installer to products
cp "$vol_name.dmg" ../products/
