set(INSTALLATION_DIR_BIN "${CMAKE_INSTALL_PREFIX}/bin")

function(add_binary_test target_name test_name family)
	add_test(NAME ${target_name}
		COMMAND ${CMAKE_COMMAND} -E env
		PATH=${INSTALLATION_DIR_BIN}:$ENV{PATH}
		${CMAKE_COMMAND} -E env
		make TEST=${test_name} FAMILY=${family}
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
endfunction()

add_binary_test(binary_toolchain_test_counter counter_16bit qlf_k4n8)
