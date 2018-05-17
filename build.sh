#!/usr/bin/env bash

set -x

P="laugh-grow-fat"
T="Laugh and Grow Fat"
U="https://github.com/premek/$P"
E="premysl.vyhnal+debian@gmail.com"
A="premek"
PACKAGE="com.github.premek.${P//-/}"

LVU="11.1"
LZ="https://bitbucket.org/rude/love/downloads/love-${LVU}-win32.zip"
APK="https://bitbucket.org/rude/love/downloads/love-${LVU}-android.apk"
APKSIGNER="https://github.com/patrickfav/uber-apk-signer/releases/download/v0.8.4/uber-apk-signer-0.8.4.jar"
APKTOOL="https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.3.3.jar"

LV=$LVU".0"

#version from git - first char has to be number
V="`git describe --tags`"
until [ "${V:0:1}" -eq "${V:0:1}" ] 2>/dev/null; do V="${V:1}"; done
if test -z "$V"; then V="snapshot"; fi;

APKVersionCode=`echo "$V" | sed -e 's/\([0-9]\+\)[.-]\([0-9]\+\)[.-]\([0-9]\+\)[.-].*/\1 \2 \3/g' | xargs printf "%02d%03d%04d"`
[[ 1"$APKVersionCode" -eq 1"$APKVersionCode" ]] || { echo "APKVersionCode Not a number"; exit 1; }


### test

find . -iname "*.lua" | xargs luac -p || { echo 'luac parse test failed' ; exit 1; }

#unused variables has to start with _
luacheck . --codes --globals love --ignore "_.*" || { echo 'luacheck failed' ; exit 2; }



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

#git diff -s --exit-code && git diff -s --cached --exit-code || { echo 'uncommited changes' ; exit 1; }

mkdir "target"

### .love
love-release -t "$P" target/ src/ || { echo '.love failed' ; exit 1; }

### .deb
love-release -D -p "$P" -t "$T" -u "$U" -v "$V" -d "$T" -a "$A" -e "$E" target/ src/ || { echo '.deb failed' ; exit 1; }

### MacOS
love-release -M -t "$P" --uti "$PACKAGE" target/ src/ || { echo 'macos failed' ; exit 1; }

### .exe
wget -c "$LZ" -O "target/love-win.zip" || exit 1
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

### android
wget -c "$APKTOOL" -O "target/apktool.jar" &
wget -c "$APK" -O "target/love-android.apk" &
wget -c "$APKSIGNER" -O target/uber-apk-signer.jar &
wait
java -jar target/apktool.jar d -s -o target/love_apk_decoded target/love-android.apk
mkdir target/love_apk_decoded/assets
cp "target/${P}.love" target/love_apk_decoded/assets/game.love
#TODO icon
cat <<EOF > target/love_apk_decoded/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8" standalone="no"?> <manifest package="${PACKAGE}" android:versionCode="${APKVersionCode}" android:versionName="${V}" android:installLocation="auto" xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-feature android:glEsVersion="0x00020000"/>
    <application android:allowBackup="true" android:icon="@drawable/love" android:label="${T}" android:theme="@android:style/Theme.NoTitleBar.Fullscreen" >
        <activity android:configChanges="orientation|screenSize" android:label="${T}" android:launchMode="singleTop" android:name="org.love2d.android.GameActivity" android:screenOrientation="sensorLandscape" > <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
                <category android:name="tv.ouya.intent.category.GAME"/>
            </intent-filter> </activity> </application> </manifest>
EOF
sed -ie "s/minSdkVersion.*/minSdkVersion: '16'/" target/love_apk_decoded/apktool.yml 
sed -ie "s/targetSdkVersion.*/targetSdkVersion: '26'/" target/love_apk_decoded/apktool.yml 
java -jar target/apktool.jar b -o "target/$P.apk" target/love_apk_decoded
java -jar target/uber-apk-signer.jar --apks "target/$P.apk"
rm "target/$P.apk" # not installable, do not dist
#TODO prod sign
fi #dist




##### install android apk #####

if [ "$1" == "installapk" ]; then
	adb install -r "target/$P-aligned-debugSigned.apk"
	adb shell monkey -p "$PACKAGE" 1
fi #installapk



### web

if [ "$1" == "web" ]; then
mkdir "target"	
cd target
rm -rf love.js *-web*
git clone https://github.com/TannerRogalsky/love.js.git
cd love.js
git checkout a74d9c862e9d9671a100a5565f6eb40411706843
git submodule update --init --recursive
cd ..
#todo custom template/theme
cp -r love.js/src/release/ "$P-web"
cd "$P-web"
sed -ie 's/{{memory}}/16777216/' index.html
sed -ie "s/{{title}}/$T/" index.html
sed -ie "s/arguments:.*{{arguments}}/\/\/arguments/" index.html

python ../love.js/emscripten/tools/file_packager.py game.data --preload ../../src/@/ --js-output=game.js
python ../love.js/emscripten/tools/file_packager.py game.data --preload ../../src/@/ --js-output=game.js

sed -ie "s/  t.version = \"11.1\"/--t.version = \"11.1\"/" game.data # oh no!

#yes, two times!
# python -m SimpleHTTPServer 8000
cd ..
zip -9 -r - "$P-web" > "${P}-web.zip"
# target/$P-web/ goes to webserver
fi
