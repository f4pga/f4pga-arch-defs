set(INSTALLATION_DIR_BIN "${CMAKE_INSTALL_PREFIX}/bin")

get_target_property_required(XC7FRAMES2BIT env XC7FRAMES2BIT)

function(add_binary_test test_name part_name device board)
	add_test(NAME ${test_name}
		COMMAND ${CMAKE_COMMAND} -E env
		PATH=${INSTALLATION_DIR_BIN}:$ENV{PATH}
		${CMAKE_COMMAND} -E env
		PYTHONPATH=${PRJXRAY_DIR}:${PRJXRAY_DIR}/third_party/fasm
		DATABASE_DIR=${PRJXRAY_DB_DIR}
		FRAMES2BIT=${XC7FRAMES2BIT}
		make PARTNAME=${part_name} DEVICE=${device} BOARD=${board}
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
endfunction()


add_binary_test(binary_toolchain_test_50t xc7a35tcpg236-1 xc7a50t_test basys3)
add_binary_test(binary_toolchain_test_100t xc7a100tcsg324-1 xc7a100t_test arty-100t)
add_binary_test(binary_toolchain_test_200t xc7a200tsbg484-1 xc7a200t_test nexys_video)
