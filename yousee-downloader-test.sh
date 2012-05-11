#!/bin/bash

# Unit tests for yousee-downloader.sh

source ./"example-configfile.sh"

# Test that correct "error" output is given in case "TV3"
OUTPUT=$(  ./yousee-downloader.sh "example-configfile.sh" "TV3_20111123_212500_20111123_214500.mux" "dr1_20111123212500_20111123214500.mux" 2>&1 )
OCCURRENCE=`echo $OUTPUT || grep 'queued' `
OCCURRENCE_LENGTH=${#OCCURRENCE}
if [ "$OCCURRENCE_LENGTH" -eq "0" ]; then
	echo "yousee-downloader.sh failed unit test for case \"TV3\""
	exit 13
fi

# Test that correct error-output is given in case "TV2"
OUTPUT=$( ./yousee-downloader.sh "example-configfile.sh" "TV2_20111123_212500_20111123_214500.mux" "dr1_20111123212500_20111123214500.mux" 2>&1 )
OCCURRENCE=`echo $OUTPUT | grep 'failed' `
OCCURRENCE_LENGTH=${#OCCURRENCE}
if [ "$OCCURRENCE_LENGTH" -eq "0" ]; then
	echo "yousee-downloader.sh failed unit test for case \"TV2\""
	exit 13
fi

# Test that correct error-output is given in case "XYZ"
OUTPUT=$( ./yousee-downloader.sh "example-configfile.sh" "XYZ_20111123_212500_20111123_214500.mux" "dr1_20111123212500_20111123214500.mux" 2>&1 )
OCCURRENCE=`echo $OUTPUT || grep 'failed' `
OCCURRENCE_LENGTH=${#OCCURRENCE}
if [ "$OCCURRENCE_LENGTH" -eq "0" ]; then
	echo "yousee-downloader.sh failed unit test for case \"XYZ\""
	exit 13
fi


# Test that correct successful output is given in case "DR"
LOCALNAME='dr1_20111123212500_20111123214500.mux'
OUTPUT=$( ./yousee-downloader.sh "example-configfile.sh" "DR1_20111123_212500_20111123_214500.mux" "dr1_20111123212500_20111123214500.mux" 2>&1 )
OCCURRENCE=`echo $OUTPUT || grep 'downloaded' `
OCCURRENCE_LENGTH=${#OCCURRENCE}
if [ "$OCCURRENCE_LENGTH" -eq "0" ]; then
	echo "yousee-downloader.sh failed unit test for case \"DR\""
	exit 13
else
	FILESIZE=$(stat -c%s "${LOCALPATH}/${LOCALNAME}")
	if [ "$FILESIZE" -ne "0" ]; then
		echo "yousee-downloader.sh passed all unit tests"
		exit 0
	else
		echo "yousee-downloader.sh failed unit test for case \"DR\" due to file size"
		exit 13
	fi
fi

