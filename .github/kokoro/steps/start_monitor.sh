(
    while :
    do
        date
        uptime
        free -h
        df -h
        sleep 300
    done
) &
MONITOR=$!
trap "kill $MONITOR" EXIT
