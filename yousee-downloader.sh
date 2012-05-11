#!/bin/bash

# Get input parameters from Taverna
CONFIGFILE=$1
YOUSEENAME=$2
LOCALNAME=$3

### Example input-parameters
#CONFIGFILE='./example-configfile.sh'
#YOUSEENAME='DT_20111123_212500_20111123_214500.mux'
#LOCALNAME='dr1_20111123212500_20111123214500.mux'
#
# Output goes to stdout


source $CONFIGFILE
URL_TO_YOUSEE=${URL_TO_YOUSEE%/}  # remove trailing slash if there is one
LOCALPATH=${LOCALPATH%/}          # remove trailing slash if there is one
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

if [ "$ERRORS_LENGTH" -eq "0" ]; then
	FILESIZE=$(stat -c%s "${LOCALPATH}/${LOCALNAME}")
	echo '{'
	echo '   "downloaded":'
	echo '   {'
	echo "      \"localFileUrl\" : \"file://${LOCALPATH}/${LOCALNAME}\","
	echo "      \"checksum\" : \"`cat ${LOCALPATH}/${LOCALNAME}.md5 | sed 's| .*||'`\","
	echo "      \"fileSize\" : $FILESIZE"
	echo '   }'
	echo '}'
	rm "${LOCALPATH}/${LOCALNAME}.md5" >/dev/null 2>/dev/null
	exit 0
fi

# So... there are errors. Pick out the error code and act on it
ERROR_CODE_LINE=`echo $ERRORS || grep 'The requested URL returned error' `
ERROR_CODE=${ERROR_CODE_LINE:(-3)}

if [ "$ERROR_CODE" -eq "404" ]; then
	# Content is not on primary server, but is on secondary. Try again later.
	echo '{'
	echo "   \"queued\":"
	echo '   {'
	echo "      \"youseeName\" : $YOUSEENAME"
	echo "      \"localName\" : $LOCALNAME"
	echo '   }'
	echo '}'
	rm "${LOCALPATH}/${LOCALNAME}" >/dev/null 2>/dev/null
	rm "${LOCALPATH}/${LOCALNAME}.md5" >/dev/null 2>/dev/null
	exit 0
fi

# Ok, now we know it's actually a real error
echo 'YouSee-downloader failed:' >&2
echo "$ERRORS" >&2
echo "URL: $YOUSEE_URL_TO_FILE" >&2
echo
echo "Guide to YouSee error codes: (you got ${ERROR_CODE})"
echo '400 = Bad information in URL (for instance, unknown channel id)'
echo '410 = Content is not available on any archive server'
rm "${LOCALPATH}/${LOCALNAME}" >/dev/null 2>/dev/null
rm "${LOCALPATH}/${LOCALNAME}.md5" >/dev/null 2>/dev/null
exit 13

