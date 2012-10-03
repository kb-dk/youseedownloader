#!/bin/bash

#MUX=dr1_20111123212500_20111123214500.mux
MUX=DRtest_20111123_212500_20111123_214500.mux
#MUX=test.mux
SIZE=`ls -l $MUX | cut -d' ' -f5`
MD5=`md5sum $MUX | cut -d' ' -f1 | base64`

PATH_INFO=`echo "$PATH_INFO" | tr '[:lower:]' '[:upper:]'`

case "$PATH_INFO" in
    /DR*)
	echo "Content-type: application/octet-stream"
	echo "Transfer-Encoding: chunked"
	echo "Trailer: Content-MD5"
	printf '\r\n%x\r\n' $SIZE
	cat $MUX
	printf '\r\n%x\r\n' 0
	echo -n "Content-MD5: $MD5"
	printf '\r\n'

	printf '\r\n'
	;;
    /TV2_*)
        echo "Status: 410 Content is not available on any archive server"
        echo
        ;;
    /TV3_*)
        echo "Status: 404 Content is on secondary archive server, please wait"
        echo
        ;;
    *)
	echo "Status: 400 Bad info in url, for instance unknown channel id"
	echo ""
	;;
esac