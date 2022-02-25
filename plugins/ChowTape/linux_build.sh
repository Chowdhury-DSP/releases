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
cd Plugin
# sed -i -e "9s~.*~juce_set_vst2_sdk_path(${SDK_PATH}/VST2_SDK)~" CMakeLists.txt
# sed -i -e '16s/#//' CMakeLists.txt

# build Win64
cmake -Bbuild -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --parallel 4

# create installer
echo "Creating installer..."
version=$(cut -f 2 -d '=' <<< "$(grep 'CMAKE_PROJECT_VERSION:STATIC' build/CMakeCache.txt)")
echo "Version: ${version}"

mkdir -p "${name}/usr/lib/vst3"
# mkdir -p "${name}/usr/lib/vst"
mkdir -p "${name}/usr/lib/lv2"
mkdir -p "${name}/usr/lib/clap"
mkdir -p "${name}/usr/bin"
mkdir -p "${name}/usr/share/${name}/doc"
mkdir -p "${name}/DEBIAN"
chmod -R 0755 "${name}"

touch "${name}/DEBIAN/control"
cat <<EOT >> "${name}/DEBIAN/control"
Source: ${name}
Package: ${name}
Version: $version
Architecture: amd64
Maintainer: Chowdhury DSP <chowdsp@gmail.com>
Depends: libjack0 | libjack-jackd2-0, libasound2 (>= 1.0.16), libc6 (>= 2.29), libfreetype6 (>= 2.2.1), libgcc-s1 (>= 4.0), libstdc++6 (>= 7)
Provides: vst-plugin
Section: sound
Priority: optional
Description: Virtual audio effect using physical modelling to emulate the sound of analog reel-to-reel tape machines.
 ChowTapeModel includes VST3, CLAP, LV2, and Standalone formats.
EOT

touch "${name}/usr/share/${name}/doc/changelog.Debian"
DATE=$(date --rfc-email)
MSG=$(git log -n 1 --pretty="%s (git hash %H)")
cat <<EOT > "${name}/usr/share/${name}/doc/changelog.Debian"
${name} (${version}) stable; urgency=medium

  * ${MSG}
  * For more details see https://github.com/jatinchowdhury18/AnalogTapeModel
  
 -- Chowdhury DSP <chowdsp@gmail.com>  ${DATE}
EOT
gzip -9 -n "${name}/usr/share/${name}/doc/changelog.Debian"

# copy license
cp ../LICENSE "${name}/usr/share/${name}/doc/copyright"

# copy plugins bundles
# cp -R build/CHOWTapeModel_artefacts/Release/VST/CHOWTapeModel.so "${name}/usr/lib/vst/"
cp -R build/CHOWTapeModel_artefacts/Release/VST3/CHOWTapeModel.vst3 "${name}/usr/lib/vst3/"
cp -R build/CHOWTapeModel_artefacts/Release/LV2/CHOWTapeModel.lv2 "${name}/usr/lib/lv2/"
cp -R build/CHOWTapeModel_artefacts/Release/CLAP/CHOWTapeModel.clap "${name}/usr/lib/clap/"
cp -R build/CHOWTapeModel_artefacts/Release/Standalone/CHOWTapeModel "${name}/usr/bin/"

# set permissions
# find "${name}/usr/lib/vst/" -type f -iname "*.so" | xargs chmod 0644
find "${name}/usr/lib/vst3/" -type f -iname "*.so" | xargs chmod 0644
find "${name}/usr/lib/lv2/" -type f -iname "*.so" | xargs chmod 0644
find "${name}/usr/lib/clap/" -type f -iname "*.so" | xargs chmod 0644
chmod -R 0755 "${name}/usr/bin/CHOWTapeModel"

echo "----- LIBRARY CONTENTS -----"
find ${name}/usr/{bin,lib} -print

# build package
deb_name=ChowTapeModel-Linux-x64-${version}
dpkg-deb --build "${name}" "${deb_name}.deb"

echo "Built DEB Package"

# copy installer to products
cp "${deb_name}.deb" ../../products/
