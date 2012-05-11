#!/bin/bash

# Get input parameters from Taverna
CONFIGFILE=$1
YOUSEENAME=$2
LOCALNAME=$3

### Example input-parameters
#CONFIGFILE='./example-configfile.sh'
#YOUSEENAME='DR_20111123_212500_20111123_214500.mux'
#LOCALNAME='dr1_20111123212500_20111123214500.mux'
#
# Output goes to stdout


source $CONFIGFILE
URL_TO_YOUSEE=${URL_TO_YOUSEE%/}  # remove trailing slash if there is one
LOCALPATH=${LOCALPATH%/}  # remove trailing slash if there is one
YOUSEE_URL_TO_FILE="${URL_TO_YOUSEE}/${YOUSEENAME}"

# Relevant curl options:
# -f  To make HTTP errors turn into a curl error 22, mentioning the HTTP error number
# -s  Silent mode
# -S  Show errors when in silent mode

# Any errors of md5sum go temporarily to &3 in order to not overwrite errors from curl
# All errors are collected in ERRORS
exec 3>&1  # Set up extra file descriptor
ERRORS=$( { curl -f -s -S "$YOUSEE_URL_TO_FILE" | tee "${LOCALPATH}/${LOCALNAME}" | md5sum 2>&3 1>"${LOCALPATH}/${LOCALNAME}.md5"; } 2>&1 3>&1 )
exec 3>&-  # Release the extra file descriptor

ERRORS_LENGTH=${#ERRORS}

if [ "$ERRORS_LENGTH" -gt "0" ]; then
	echo 'YouSee-downloader failed:' >&2
	echo "$ERRORS" >&2
	echo "URL: $YOUSEE_URL_TO_FILE" >&2
	rm "${LOCALPATH}/${LOCALNAME}" >/dev/null 2>/dev/null
	rm "${LOCALPATH}/${LOCALNAME}.md5" >/dev/null 2>/dev/null
	exit 13
else
	FILESIZE=$(stat -c%s "${LOCALPATH}/${LOCALNAME}")
	echo '{'
	echo "   \"localFileUrl\" : \"file://${LOCALPATH}/${LOCALNAME}\","
	echo "   \"checksum\" : \"`cat ${LOCALPATH}/${LOCALNAME}.md5 | sed 's| .*||'`\","
	echo "   \"fileSize\" : $FILESIZE"
	echo '}'
	rm "${LOCALPATH}/${LOCALNAME}.md5" >/dev/null 2>/dev/null
	exit 0
fi

