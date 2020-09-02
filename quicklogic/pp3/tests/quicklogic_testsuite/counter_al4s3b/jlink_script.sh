jlink_file="top.jlink"
sed  -i '1s/^/r\
sleep 100\
/' $jlink_file
cat "jlink_cmds.txt" >>$jlink_file
