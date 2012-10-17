#!/bin/bash

# Get input parameters from Taverna
CONFIGFILE=$1
YOUSEENAME=$2
LOCALNAME=$3

### Example input-parameters
#CONFIGFILE='./example-configfile.sh'
#YOUSEENAME='WX_20111123_212500_20111123_214500.mux'
#LOCALNAME='dr1_20111123212500_20111123214500.mux'
#
# Output goes to stdout


source $CONFIGFILE

if [ -z "$URL_TO_YOUSEE" ]; then
	echo "Error: Config parameter URL_TO_YOUSEE is empty!"
	exit 666
fi
if [ -z "$LOCALPATH" ]; then
	echo "Error: Config parameter LOCALPATH is empty!"
	exit 666
fi
if [ -z "$CONFIGFILE" ]; then
	echo "Error: Config parameter CONFIGFILE is empty!"
	exit 666
fi
if [ -z "$YOUSEENAME" ]; then
	echo "Error: Config parameter YOUSEENAME is empty!"
	exit 666
fi
if [ -z "$LOCALNAME" ]; then
	echo "Error: Config parameter LOCALNAME is empty!"
	exit 666
fi

URL_TO_YOUSEE=${URL_TO_YOUSEE%/}  # remove trailing slash if there is one
LOCALPATH=${LOCALPATH%/}          # remove trailing slash if there is one
YOUSEE_URL_TO_FILE="${URL_TO_YOUSEE}/${YOUSEENAME}?md5=yes"



THEIRCHECKSUM=""
STREAMCHECKSUM=""
FILECHECKSUM=""



function checkExistingFile(){
    STREAMCHECKSUM=`cat ${LOCALPATH}/${LOCALNAME}.md5 | cut -d' ' -f1` 2>/dev/null
    THEIRCHECKSUM=`cat ${LOCALPATH}/${LOCALNAME}.headers  | grep -i "content-md5:" | cut -d' ' -f2 |  sed 's/\s*$//g' | base64 -d` 2>/dev/null
    FILECHECKSUM=`md5sum ${LOCALPATH}/${LOCALNAME} | cut -d' ' -f1` 2>/dev/null
    if [ -z "$THEIRCHECKSUM" ]; then
        #yousee failed to provide a checksum, ignore warning for now
        THEIRCHECKSUM=$STREAMCHECKSUM
    fi
    if [  "$STREAMCHECKSUM" -a "$STREAMCHECKSUM" == "$THEIRCHECKSUM" -a "$STREAMCHECKSUM" == "$FILECHECKSUM" -a "$THEIRCHECKSUM" == "$FILECHECKSUM" ];
    then
        return 0
    else
        return 1
    fi
}

function verifyDownload(){
    STREAMCHECKSUM=`cat ${LOCALPATH}/${LOCALNAME}.md5 | cut -d' ' -f1` 2>/dev/null
    THEIRCHECKSUM=`cat ${LOCALPATH}/${LOCALNAME}.headers  | grep -i "content-md5:" | cut -d' ' -f2 |  sed 's/\s*$//g' | base64 -d` 2>/dev/null
    if [ -z "$THEIRCHECKSUM" ]; then
        #yousee failed to provide a checksum, ignore warning for now
        THEIRCHECKSUM=$STREAMCHECKSUM
    fi
    if [  "$STREAMCHECKSUM" -a "$STREAMCHECKSUM" == "$THEIRCHECKSUM" ];
    then
        return 0
    else
        return 1
    fi
}

DOWNLOAD="yes"
if [ -e ${LOCALPATH}/${LOCALNAME} ]; then
    if ! checkExistingFile ; then
        echo "File was found locally, but checksums do not match. File will be redownloaded" >&2
        echo "checksum on stream: $STREAMCHECKSUM" >&2
        echo "checksum from yousee: $THEIRCHECKSUM" >&2
        echo "checksum calculated on disk: $FILECHECKSUM" >&2
    else
        DOWNLOAD=""
    fi
fi

failed=0
if [ $DOWNLOAD ]; then

    # Relevant curl options:
    # -f  To make HTTP errors turn into a curl error 22, mentioning the HTTP error number
    # -s  Silent mode
    # -S  Show errors when in silent mode
    # -D write header dump to this file
    # --header Send this header

    curl -D ${LOCALPATH}/${LOCALNAME}.headers -f -s -S --header "\"TE: trailers\"" "$YOUSEE_URL_TO_FILE" | tee "${LOCALPATH}/${LOCALNAME}" | md5sum -b >"${LOCALPATH}/${LOCALNAME}.md5";
    failed=$(echo ${PIPESTATUS[@]}  | awk -v RS=" " '1' | sort -nr | head -1)
fi

if [ $failed -eq 0 ]; then
    if ! verifyDownload; then
        echo "File was downloaded but checksums do not match. \n The file will not be redownloaded, so this error will
        not go away. \n Get an administrator to delete the file, and schedule this download again." >&2
        echo "checksum on stream: $STREAMCHECKSUM" >&2
        echo "checksum from yousee: $THEIRCHECKSUM" >&2
        exit 1
    else
        # No errors, so content was downloadable
        FILESIZE=$(stat -c%s "${LOCALPATH}/${LOCALNAME}")

        echo '{'
        echo '   "downloaded":'
        echo '   {'
        echo "      \"localFileUrl\" : \"file://${LOCALPATH}/${LOCALNAME}\","
        echo "      \"checksum\" : \"$STREAMCHECKSUM\","
        echo "      \"fileSize\" : $FILESIZE"
        echo '   }'
        echo '}'
        exit 0
    fi
fi

# So we have failed to download


if [ -r "${LOCALPATH}/${LOCALNAME}.headers" ]; then
    # So... there are errors. Pick out the error code and act on it
    ERROR_CODE="$(head -1 \"${LOCALPATH}/${LOCALNAME}.headers\" | cut -d' ' -f2)"
else
    ERROR_CODE=$failed
fi

# No more use for these
rm -f "${LOCALPATH}/${LOCALNAME}" >/dev/null 2>/dev/null
rm -f "${LOCALPATH}/${LOCALNAME}.md5" >/dev/null 2>/dev/null
rm -f "${LOCALPATH}/${LOCALNAME}.headers" >/dev/null 2>/dev/null


if [ $ERROR_CODE -eq 404 ]; then
	# Content is not on primary server, but is on secondary. Try again later.
	echo '{'
	echo "   \"queued\":"
	echo '   {'
	echo "      \"youseeName\" : \"${YOUSEENAME}\","
	echo "      \"localName\" : \"$LOCALNAME\""
	echo '   }'
	echo '}'
	exit 42
else
    # Ok, now we know it's actually a real error
    echo 'YouSee-downloader failed:' >&2
    echo "URL: $YOUSEE_URL_TO_FILE" >&2
    echo ""  >&2
    echo "Guide to YouSee error codes: (you got ${ERROR_CODE})" >&2
    echo '400 = Bad information in URL (for instance, unknown channel id)' >&2
    echo '410 = Content is not available on any archive server' >&2
    exit 13
fi


