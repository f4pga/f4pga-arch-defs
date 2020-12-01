# Clear trap on EXIT to kill the monitor.
trap - EXIT
kill $MONITOR
