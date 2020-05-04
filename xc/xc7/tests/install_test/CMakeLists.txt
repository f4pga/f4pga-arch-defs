set(INSTALLATION_DIR_BIN "${CMAKE_INSTALL_PREFIX}/bin")
get_target_property_required(CONDA_DIR env CONDA_DIR)

add_test(NAME binary_toolchain_test
	COMMAND ${CMAKE_COMMAND} -E env
	PATH=${INSTALLATION_DIR_BIN}:${CONDA_DIR}/bin:$ENV{PATH}
	${CMAKE_COMMAND} -E env
	LD_LIBRARY_PATH=${CONDA_DIR}/lib:$ENV{LD_LIBRARY_PATH}
	${CMAKE_COMMAND} -E env
	PYTHONPATH=${CONDA_DIR}/lib/python3.7/site-packages:${PRJXRAY_DIR}:${PRJXRAY_DIR}/third_party/fasm
	XRAY_FASM2FRAMES=${PRJXRAY_DIR}/utils/fasm2frames.py
	XRAY_TOOLS_DIR=${symbiflow-arch-defs_SOURCE_DIR}/build/third_party/prjxray/tools
	XRAY_DATABASE_DIR=${PRJXRAY_DB_DIR}
	make
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
