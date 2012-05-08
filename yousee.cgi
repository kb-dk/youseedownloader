#!/bin/bash

MUX=DR1_20111123_212500_20111123_214500.mux

case "$PATH_INFO" in
    /DR1_*)
	case $(date +%S) in
	    0*)
		echo "Status: 410 Content is not available on any archive server"
		echo
		;;
	    1*)
		echo "Status: 404 Content is on secondary archive server, please wait"
		echo
		;;
	    *)
		echo "Content-type: application/octet-stream"
		echo
		cat $MUX
		;;
	esac
	;;
    *)
	echo "Status: 400 Bad info in url, for instance unknown channel id"
	echo ""
	;;
esac
