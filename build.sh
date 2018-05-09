#!/usr/bin/env bash

set -x

P="laugh-grow-fat"
T="Laugh and Grow Fat"
U="https://github.com/premek/$P"
E="premysl.vyhnal+debian@gmail.com"
A="premek"
UTI="com.github.premek.$P"

LVU="11.1"
LZ="https://bitbucket.org/rude/love/downloads/love-${LVU}-win32.zip"

LV=$LVU".0"

#version from git - first char has to be number
V="`git describe --tags`"
until [ "${V:0:1}" -eq "${V:0:1}" ] 2>/dev/null; do V="${V:1}"; done
if test -z "$V"; then V="snapshot"; fi;



### test

find . -iname "*.lua" | xargs luac -p || { echo 'luac parse test failed' ; exit 1; }



### clean

if [ "$1" == "clean" ]; then
 rm -rf "target"
 exit;
fi



### deploy web version to github pages

if [ "$1" == "deploy" ]; then
 cd "target/${P}-web"
 git init
 git config user.name "autodeploy"
 git config user.email "autodeploy"
 touch .
 git add .
 git commit -m "deploy to github pages"
 git push --force --quiet "https://${GH_TOKEN}@github.com/${2}.git" master:gh-pages

 exit;
fi



##### build binary/dist packages #####

if [ "$1" == "dist" ]; then


mkdir "target"

### .love
love-release -t "$P" target/ src/ || { echo '.love failed' ; exit 1; }

### .deb
love-release -D -p "$P" -t "$T" -u "$U" -v "$V" -d "$T" -a "$A" -e "$E" target/ src/ || { echo '.deb failed' ; exit 1; }

### MacOS
love-release -M -t "$P" --uti "$UTI" target/ src/ || { echo 'macos failed' ; exit 1; }

### .exe
if [ ! -f "target/love-win.zip" ]; then wget "$LZ" -O "target/love-win.zip" || exit 1; fi
unzip -o "target/love-win.zip" -d "target"
tmp="target/tmp/"
mkdir -p "$tmp/$P"
cat "target/love-${LV}-win32/love.exe" "target/${P}.love" > "$tmp/${P}/${P}.exe"
cp  target/love-"${LV}"-win32/*dll target/love-"${LV}"-win32/license* "$tmp/$P"
cd "$tmp"
zip -9 -r - "$P" > "${P}-win.zip"
cd -
mv "$tmp/${P}-win.zip" "target/"
rm -r "$tmp"

fi #dist



### web

if [ "$1" == "web" ]; then

cd target
rm -rf love.js *-web*
git clone https://github.com/TannerRogalsky/love.js.git
cd love.js
git checkout a74d9c862e9d9671a100a5565f6eb40411706843
git submodule update --init --recursive
cd ..

cp -r love.js/src/release/ "$P-web"
cd "$P-web"
sed -ie 's/{{memory}}/16777216/' index.html
sed -ie "s/{{title}}/$T/" index.html
sed -ie "s/arguments:.*{{arguments}}/\/\/arguments/" index.html
sed -ie "s/  t.version = \"11.1\"/--t.version = \"11.1\"/" game.data

python ../love.js/emscripten/tools/file_packager.py game.data --preload ../../src/@/ --js-output=game.js
python ../love.js/emscripten/tools/file_packager.py game.data --preload ../../src/@/ --js-output=game.js
#yes, two times!
# python -m SimpleHTTPServer 8000
cd ..
zip -9 -r - "$P-web" > "${P}-web.zip"
# target/$P-web/ goes to webserver
fi
