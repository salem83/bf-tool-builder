#!/bin/bash

# ToDo: Wine64/32 problem

# variables ------------------------------------------------------

NW_URL="https://dl.nwjs.io/v0.83.0/"
NW_REL="nwjs-v0.83.0-win-x64"
NW_ZIP="${NW_REL}.zip"

RH_URL="https://www.angusj.com/resourcehacker/resource_hacker.zip" 

WINE_DIR=~/.wine/drive_c/nw_temp/

WINE_NW="c:\\nw_temp\\nwjs-v0.83.0-win-x64\\"

CDIR=$(pwd)

BFC_DIR="betaflight-configurator"
BFC_URL="https://github.com/betaflight/betaflight-configurator.git"
BFC_ICO=""

BBL_DIR="blackbox-log-viewer"
BBL_URL="https://github.com/betaflight/blackbox-log-viewer.git"


# functions -----------------------------------------------------

# log message
function _L() {
  # before nl
  if [ -n "$2" ] && [ "$2" == "1" ]; then MSG="\n"; fi;
  MSG="${MSG}${1}"
  # after nl  
  if [ -n "$3" ] && [ "$3" == "1" ]; then MSG="${MSG}\n"; fi;
  echo -e $MSG
}


# ----------------------------------------------------

# set node version ----------------------------------------------
_L "--- NODE VERSION ---" 1
# enable nwm command
export NVM_DIR=$HOME/.nvm
source $NVM_DIR/nvm.sh
# set lts version
nvm install --lts

# check yarn ----------------------------------------------------
npm list --depth 1 --global packagename > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERR: please install yarn (npm install yarn -g)"
fi


# check if repo exists -> update or clone -----------------------
_L "--- CHECK REPOS ---" 1

_L " - betaflight configurator" 1
if [ -d "$BFC_DIR/.git" ]; then
  git -C $BFC_DIR pull  
else
  git clone $BFC_URL
fi;
yarn --cwd $BFC_DIR install

_L " - blackbox-log-viewer" 1
if [ -d "$BBL_DIR/.git" ]; then
  git -C $BBL_DIR pull  
else
  git clone $BBL_URL
fi;

yarn --cwd $BBL_DIR install

# build ---------------------------------------------------------
_L " --- BUILD ---" 1

_L " - betaflight-configurator" 1
yarn --cwd betaflight-configurator gulp dist

_L " - blackbox-log-viewer" 1
yarn --cwd blackbox-log-viewer gulp dist


# get tools / resources -----------------------------------------
_L " --- GET TOOLS ----" 1
rm -rf $WINE_DIR
mkdir -p $WINE_DIR
ls $WINE_DIR

_L " - resource hacker" 1
rm -rf resource_hacker.zip*
wget $RH_URL
unzip -o -d $WINE_DIR ./resource_hacker.zip "*.exe"

_L " - nw.js" 1
rm -rf nwjs-*
wget "${NW_URL}${NW_ZIP}"
unzip -o -d $WINE_DIR $NW_ZIP



# pack it -------------------------------------------------------
_L " --- PACK IT ---" 1

pushd .

# bf
_L $BFC_DIR 1
cd betaflight-configurator/dist
zip -r "${WINE_DIR}/${NW_REL}/bfc.nw" *
popd

# black box
_L " - blackbox log viewer" 1
pushd .
cd blackbox-log-viewer/dist
zip -r "${WINE_DIR}/${NW_REL}/bfbbv.nw" *
popd


# create exe ----------------------------------------------------
_L "--- CREATE EXE ---" 1

_L " - betaflight-configurator" 1
wine64 cmd "/c copy /b ${WINE_NW}nw.exe+${WINE_NW}bfc.nw ${WINE_NW}bfc.exe"

_L " - blackbox-log-viewer" 1
wine64 cmd "/c copy /b ${WINE_NW}nw.exe+${WINE_NW}bfbbv.nw ${WINE_NW}bfbbv.exe"


## change icons --------------------------------------------------
echo " - change icons"
cp ./bf.ico $WINE_DIR$NW_REL/bf.ico
cp ./bb.ico $WINE_DIR$NW_REL/bb.ico


# merge icons
_L " --- ICONS ---"
pushd .

cd $WINE_DIR
wine64 ResourceHacker.exe -open "${WINE_NW}bfc.exe" -save "${WINE_NW}bfc.exe" -action addoverwrite -resource "${WINE_NW}bf.ico" -mask ICONGROUP,IDR_MAINFRAME
wine64 ResourceHacker.exe -open "${WINE_NW}bfbbv.exe" -save "${WINE_NW}bfbbv.exe" -action addoverwrite -resource "${WINE_NW}bb.ico" -mask ICONGROUP,IDR_MAINFRAME

popd

# release
_L " --- ZIP ---"
rm -rf release.zip
pushd .

cd ${WINE_DIR}/${NW_REL}

rm -rf *.nw
rm -rf nw.exe
rm -rf *.ico

zip -r $CDIR/release.zip * 

popd


## clean up
_L "--- clean up ---"
pwd
rm -rf $WINE_DIR
rm -rf $NW_ZIP
rm -rf resource_hacker.zip


# --- EOF ---
