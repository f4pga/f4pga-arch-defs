(
    while :
    do
        date
        uptime
        free -h
        sleep 300
    done
) &
MONITOR=$!
trap "kill $MONITOR" EXIT
