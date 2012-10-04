#!/bin/bash

#MUX=dr1_20111123212500_20111123214500.mux

[ -z "$MUX" ] && MUX=DRtest_20111123_212500_20111123_214500.mux


SIZE=`ls -l $MUX | cut -d' ' -f5`

PATH_INFO=`echo "$PATH_INFO" | tr '[:lower:]' '[:upper:]'`

QUERY_STRING=`echo "$QUERY_STRING" | tr '[:upper:]' '[:lower:]'`

if [ $QUERY_STRING == "md5=yes" -o $QUERY_STRING == "md5=true" -o $QUERY_STRING == "md5=1" -o $QUERY_STRING == "md5=on" ];
then
    MD5=`md5sum $MUX | cut -d' ' -f1 | base64`
fi

case "$PATH_INFO" in
    /*)
        echo "Content-type: application/octet-stream"
        [ -n "$MD5" ] && echo "Transfer-Encoding: chunked"
        [ -n "$MD5" ] && echo "Trailer: Content-MD5"
        [ -n "$MD5" ] && printf '\r\n%x' $SIZE
        printf '\r\n'
        cat $MUX
        [ -n "$MD5" ] && printf '\r\n%x\r\n' 0
        [ -n "$MD5" ] && echo -n "Content-MD5: $MD5"
        [ -n "$MD5" ] && printf '\r\n'
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


