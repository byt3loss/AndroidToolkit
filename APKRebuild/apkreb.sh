#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <decompiled_apk_dir>"
    exit 1
fi

# args
APK_DIR=$1

# cli colors
R="\e[31m"
B="\e[34m"
G="\e[32m"
RES="\e[0m"

# prefix
INFO="$B[+]$RES"
OK="$G[!]$RES"
ERR="$R[-]$RES"

OUTDIR="out_patch_${APK_DIR}"
KEYSTORE="apkrebuild.keystore"
KEYSTORE_ALIAS="apkrebuild.alias"
KEYSTORE_PWD="autosignme"
APK_BUILD="${OUTDIR}/unsigned.apk"
APK_ALIGN="${OUTDIR}/aligned.apk"
APK_SIGNED="${OUTDIR}/signed.apk"

if [ ! -d $OUTDIR ]; then
        mkdir $OUTDIR
else
        echo -e "$INFO Output directory already found. Performing a cleanup..."
        rm ${APK_BUILD} ${APK_ALIGN} ${APK_SIGNED} ${APK_SIGNED}.idsig
fi

# create keystore
if [ ! -f ${KEYSTORE} ]; then
        echo -e "$INFO Keystore ${KEYSTORE} not found. Creating a new one."
        keytool -genkey -v \
                -keystore $KEYSTORE \
                -keyalg RSA \
                -keysize 2048 \
                -validity 10000 \
                -alias ${KEYSTORE_ALIAS} \
                -storepass ${KEYSTORE_PWD} \
                -dname "CN=Android,O=Android,C=US"
        echo -e "$OK Keystore created."
else
        echo -e "$INFO Keystore ${KEYSTORE} already present. Skipping creation."
fi

# APK build
echo -e "$INFO Building the APK..."
output=$(apktool b ${APK_DIR} -o ${APK_BUILD} 2>&1)

# apktool common error
if [[ $output == *"!!brut.androlib.meta.MetaInfo"* ]]; then
        echo -e "$ERR Before continuing, comment out the first line from the ${APK_DIR}/apktool.yml file (!!brut.androlib.meta.MetaInfo)"
        exit
else
        echo "$output"

fi

if [ -f ${APK_BUILD} ]; then
        echo -e "$OK APK built successfully: ${APK_BUILD}"
else
        echo -e "$ERR Failed to build APK. Quitting..."
        exit
fi

# zipalign apk
echo -e "$INFO Aligning APK files..."
zipalign -p 4 ${APK_BUILD} ${APK_ALIGN}

if [ -f ${APK_ALIGN} ]; then
        echo -e "$OK APK aligned successfully: ${APK_ALIGN}"
else
        echo -e "$ERR Failed to zipalign the APK. Quitting..."
        exit
fi

# sign apk
echo -e "$INFO Signing the APK..."
apksigner sign --ks-key-alias ${KEYSTORE_ALIAS} --ks ${KEYSTORE} --ks-pass pass:${KEYSTORE_PWD} --out ${APK_SIGNED} ${APK_ALIGN}

if [ -f ${APK_SIGNED} ]; then
        echo -e "$OK APK signed successfully: ${APK_SIGNED}"
else
        echo -e "$ERR Failed to sign the APK. Quitting..."
        exit
fi