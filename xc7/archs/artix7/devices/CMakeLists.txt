add_xc7_device_define(
  ARCH artix7
  USE_ROI
  DEVICES xc7a50t-basys3 xc7a50t-arty-uart xc7a50t-arty-swbut
  PARTS xc7a35tcpg236-1 xc7a35tcsg324-1 xc7a35tcsg324-1
  SEARCH_LOCATIONS
    25,23
    23,25
    1,1
    76,1
    25,25
    25,27
    75,26
)
add_xc7_device_define(
  ARCH artix7
  DEVICES xc7a50t
  PARTS xc7a35tcpg236-1
  GRAPH_LIMIT 0,105,114,155
  SEARCH_LOCATIONS
    109,125
    83,108
    100,138
    61,130
    109,133
    79,133
    79,121
    77,108
    145,133
)
