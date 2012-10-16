#!/bin/bash

#MUX=dr1_20111123212500_20111123214500.mux
[ -z "$MUX" ] && MUX=DRtest_20111123_212500_20111123_214500.mux

PATH_INFO=`echo "$PATH_INFO" | tr '[:lower:]' '[:upper:]'`

QUERY_STRING=`echo "$QUERY_STRING" | tr '[:upper:]' '[:lower:]'`

RESPONSE="200"

if [ -e "${PATH_INFO:1}" ]; then
    MUX="${PATH_INFO:1}"
else
    case "$PATH_INFO" in
        /KANAL6_*)
            MUX="KANAL6_20121008_140000_20121008_150000.mux"
            ;;
        /LORRY_*)
            MUX="LORRY_20121008_140000_20121008_150000.mux"
            ;;
        /RADIO100_*)
            MUX="RADIO100_20121008_140000_20121008_150000.mux"
            ;;
        /DRP8_*)
            MUX="DRP8_20121008_140000_20121008_150000.mux"
            ;;
        /DR1_*)
            MUX="DR1_20121008_120000_20121008_130000.mux"
            ;;
        /CANAL9_*)
            MUX="CANAL9_20121008_140000_20121008_150000.mux"
            ;;
        /ANIMAL_*)
            MUX="ANIMAL_20121008_140000_20121008_150000.mux"
            ;;
        *)
            MUX="/dev/null"
            RESPONSE="400"
            ;;
    esac
fi

if [ $QUERY_STRING == "md5=yes" -o $QUERY_STRING == "md5=true" -o $QUERY_STRING == "md5=1" -o $QUERY_STRING == "md5=on" ];
then
    MD5=`md5sum $MUX | cut -d' ' -f1 | base64`
fi

SIZE=`ls -lL $MUX | cut -d' ' -f5`

case "$RESPONSE" in
    200)
        echo "Content-type: application/octet-stream"
        [ -n "$MD5" ] && echo "Transfer-Encoding: chunked"
        [ -n "$MD5" ] && echo "Trailer: Content-MD5"
        [ -n "$MD5" ] && printf '\r\n%x' "$SIZE"
        printf '\r\n'
        cat $MUX
        [ -n "$MD5" ] && printf '\r\n%x\r\n' 0
        [ -n "$MD5" ] && echo -n "Content-MD5: $MD5"
        [ -n "$MD5" ] && printf '\r\n'
        printf '\r\n'
        ;;
    410)
        echo "Status: 410 Content is not available on any archive server"
        echo
        ;;
    404)
        echo "Status: 404 Content is on secondary archive server, please wait"
        echo
        ;;
    *)
        echo "Status: 400 Bad info in url, for instance unknown channel id"
        echo ""
        ;;
esac


