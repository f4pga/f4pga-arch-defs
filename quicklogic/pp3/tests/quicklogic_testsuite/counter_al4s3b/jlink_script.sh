jlink_file="top.jlink"
sed  -i '1s/^/r\
sleep 100\
/' $jlink_file
echo "exit" >>$jlink_file
