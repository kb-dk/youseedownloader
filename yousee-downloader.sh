#!/bin/bash

### Example input-parameters
# CONFIGFILE='./example-configfile.sh'
YOUSEENAME='DR1_20111123_212500_20111123_214500.mux'
LOCALNAME='dr1_20111123212500_20111123214500.mux'
#
### Output goes to stdout

# mockup config
LOCALPATH='/home/jeppe/projects/yousee-file-downloader'
#...fjern evt / i slutning af path

YOUSEE_URL_TO_FILE="http://canopus/yousee/${YOUSEENAME}"


# Relevant curl options:
# -f  To make HTTP errors turn into a curl error 22, mentioning the HTTP error number
# -s  Silent mode
# -S  Show errors when in silent mode

# Any errors of md5sum go to &4 (and fizzle)
# Any remaining errors go to $error
exec 3>&1 4>&2  # Set up extra file descriptors
error=$( { curl -f -s -S $YOUSEE_URL_TO_FILE | tee "${LOCALPATH}/${LOCALNAME}" | md5sum 2>&4 1>"${LOCALNAME}.md5"; } 2>&1 )
exec 3>&- 4>&-  # Release the extra file descriptors

FILESIZE=$(stat -c%s "${LOCALPATH}/${LOCALNAME}")

echo '{'
echo "   \"localFileUrl\" : \"file://${LOCALPATH}/${LOCALNAME}\","
echo "   \"checksum\" : \"`cat ${LOCALPATH}/${LOCALNAME}.md5 | sed 's| .*||'`\","
echo "   \"fileSize\" : $FILESIZE"
echo '}'

rm "${LOCALPATH}/${LOCALNAME}.md5"

#echo "The error message is \"${error}\"."
#echo "The checksum is \"${checksum}\"."



