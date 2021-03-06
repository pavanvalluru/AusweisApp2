IF(COVERAGE)

	# LCov (http://ltp.sourceforge.net/coverage/lcov.php)
	FIND_PROGRAM(LCOV_BIN lcov CMAKE_FIND_ROOT_PATH_BOTH)
	IF(LCOV_BIN)
		SET(LCOV_FILE "${PROJECT_BINARY_DIR}/coverage.info")
		SET(LCOV_GLOBAL_CMD ${LCOV_BIN} -q -o ${LCOV_FILE})
		SET(LCOV_CMD ${LCOV_GLOBAL_CMD} -c -d ${PROJECT_BINARY_DIR} -b ${PROJECT_SOURCE_DIR})
		SET(LCOV_RM_CMD ${LCOV_GLOBAL_CMD} -r ${LCOV_FILE} "*/test/*" "*/include/*" "*/src/external/*" "moc_*" "*.moc" "qrc_*" "ui_*")

		IF("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
			IF(WIN32)
				SET(CLANG_GCOV py)
			ELSE()
				SET(CLANG_GCOV sh)
			ENDIF()
			SET(LCOV_CMD ${LCOV_CMD} --gcov-tool ${RESOURCES_DIR}/jenkins/clang-gcov.${CLANG_GCOV})
		ENDIF()

		ADD_CUSTOM_COMMAND(OUTPUT ${LCOV_FILE} COMMAND ${LCOV_CMD} COMMAND ${LCOV_RM_CMD})
		ADD_CUSTOM_TARGET(lcov COMMAND ${LCOV_BIN} -l ${LCOV_FILE} DEPENDS ${LCOV_FILE})

		FIND_PROGRAM(GENHTML_BIN genhtml CMAKE_FIND_ROOT_PATH_BOTH)
		IF(GENHTML_BIN)
			SET(REPORT_DIR "${PROJECT_BINARY_DIR}/coverage.report")
			SET(GENHTML_CMD ${GENHTML_BIN} -q -p ${PROJECT_SOURCE_DIR} --num-spaces=4 -o ${REPORT_DIR} ${LCOV_FILE})
			FIND_PROGRAM(FILT_BIN c++filt CMAKE_FIND_ROOT_PATH_BOTH)
			IF(FILT_BIN)
				SET(GENHTML_CMD ${GENHTML_CMD} --demangle-cpp)
			ENDIF()

			ADD_CUSTOM_COMMAND(OUTPUT ${REPORT_DIR} COMMAND ${GENHTML_CMD} DEPENDS ${LCOV_FILE})
			ADD_CUSTOM_TARGET(lcov.report DEPENDS ${REPORT_DIR})
		ENDIF()

		SET(LCOV_XML "${PROJECT_BINARY_DIR}/coverage.xml")
		SET(LCOV_COBERTURA_CMD ${RESOURCES_DIR}/jenkins/lcov_cobertura.py ${LCOV_FILE} -b ${PROJECT_SOURCE_DIR} -o ${LCOV_XML})
		ADD_CUSTOM_COMMAND(OUTPUT ${LCOV_XML} COMMAND ${LCOV_COBERTURA_CMD} DEPENDS ${LCOV_FILE})
		ADD_CUSTOM_TARGET(lcov.xml DEPENDS ${LCOV_XML})
	ENDIF()

	# gcovr (http://gcovr.com/)
	FIND_PROGRAM(GCOVR_BIN gcovr CMAKE_FIND_ROOT_PATH_BOTH)
	IF(GCOVR_BIN)
		SET(GCOVR_FILE "${PROJECT_BINARY_DIR}/gcovr.xml")
		SET(GCOVR_CMD ${GCOVR_BIN} -x -o ${GCOVR_FILE} --exclude="src/external" --exclude="test" -r ${PROJECT_SOURCE_DIR} ${PROJECT_BINARY_DIR})

		ADD_CUSTOM_COMMAND(OUTPUT ${GCOVR_FILE} COMMAND ${GCOVR_CMD})
		ADD_CUSTOM_TARGET(gcovr DEPENDS ${GCOVR_FILE})
	ENDIF()

ENDIF()

# CppCheck (http://cppcheck.sourceforge.net)
FIND_PROGRAM(CPPCHECK_BIN cppcheck CMAKE_FIND_ROOT_PATH_BOTH)
IF(CPPCHECK_BIN)
	SET(XML_FILE "${PROJECT_BINARY_DIR}/cppcheck.xml")
	SET(XML_FILE_TESTS "${PROJECT_BINARY_DIR}/cppcheck.tests.xml")

	SET(CPPCHECK_SUPPRESS --suppress=missingInclude --suppress=unmatchedSuppression --suppress=unusedFunction --suppress=noExplicitConstructor)
	SET(CPPCHECK_SUPPRESS_SRC ${CPPCHECK_SUPPRESS})
	SET(CPPCHECK_SUPPRESS_TESTS ${CPPCHECK_SUPPRESS} --suppress=noConstructor)

	DIRLIST_OF_FILES(CPPCHECK_INCLUDE_DIRS ${SRC_DIR}/*.h)
	FOREACH(dir ${CPPCHECK_INCLUDE_DIRS})
		SET(CPPCHECK_OPTIONS "${CPPCHECK_OPTIONS} -I${dir}")
	ENDFOREACH()

	SET(CPPCHECK_CMD ${CPPCHECK_BIN} ${CPPCHECK_OPTIONS} --relative-paths=${PROJECT_SOURCE_DIR} --enable=all ${SRC_DIR} ${CPPCHECK_SUPPRESS_SRC} --force)
	SET(CPPCHECK_CMD_TESTS ${CPPCHECK_BIN} ${CPPCHECK_OPTIONS} --relative-paths=${PROJECT_SOURCE_DIR} --enable=all ${TEST_DIR} ${CPPCHECK_SUPPRESS_TESTS} --force)

	SET(CPPCHECK_OPTIONS_FILE -q --xml --xml-version=2)
	ADD_CUSTOM_COMMAND(OUTPUT ${XML_FILE} COMMAND ${CPPCHECK_CMD} ${CPPCHECK_OPTIONS_FILE} 2> ${XML_FILE} COMMAND ${CPPCHECK_CMD_TESTS} ${CPPCHECK_OPTIONS_FILE} 2> ${XML_FILE_TESTS})
	ADD_CUSTOM_COMMAND(OUTPUT ${XML_FILE_TESTS} COMMAND ${CPPCHECK_CMD_TESTS} ${CPPCHECK_OPTIONS_FILE} 2> ${XML_FILE_TESTS})
	ADD_CUSTOM_TARGET(cppcheck COMMAND ${CPPCHECK_CMD_TESTS} -v COMMAND ${CPPCHECK_CMD} -v)
	ADD_CUSTOM_TARGET(cppcheck.report DEPENDS ${XML_FILE} ${XML_FILE_TESTS})
ENDIF()

# CppNcss (http://cppncss.sourceforge.net)
FIND_PROGRAM(CPPNCSS_BIN cppncss CMAKE_FIND_ROOT_PATH_BOTH)
IF(CPPNCSS_BIN)
	SET(XML_FILE "${PROJECT_BINARY_DIR}/cppncss.xml")
	SET(CPPNCSS_CMD ${CPPNCSS_BIN} -k -r -p="${PROJECT_SOURCE_DIR}/" ${SRC_DIR} ${TEST_DIR})

	ADD_CUSTOM_COMMAND(OUTPUT ${XML_FILE} COMMAND ${CPPNCSS_CMD} -x -f="${XML_FILE}")
	ADD_CUSTOM_TARGET(cppncss COMMAND ${CPPNCSS_CMD} -m=CCN,NCSS,function)
	ADD_CUSTOM_TARGET(cppncss.report DEPENDS ${XML_FILE})
ENDIF()

# pmccabe (http://parisc-linux.org/~bame/pmccabe/)
FIND_PROGRAM(PMCCABE_BIN pmccabe CMAKE_FIND_ROOT_PATH_BOTH)
IF(PMCCABE_BIN)
	ADD_CUSTOM_TARGET(pmccabe COMMAND ${PMCCABE_BIN} -v ${SRC_DIR}/*.cpp ${TEST_DIR}/*.cpp)
ENDIF()

# Doxygen (http://www.doxygen.org)
# http://www.stack.nl/~dimitri/doxygen/manual/config.html
FIND_PACKAGE(Doxygen)
IF(DOXYGEN_FOUND)
	SET(DOXYGEN_BIN_DIR "${PROJECT_BINARY_DIR}/doxygen")
	SET(DOXYGEN_CMD ${DOXYGEN_EXECUTABLE} ${PROJECT_BINARY_DIR}/Doxyfile)
	SET(DOXYGEN_CFG ${PROJECT_SOURCE_DIR}/Doxyfile.in)
	CONFIGURE_FILE(${DOXYGEN_CFG} ${PROJECT_BINARY_DIR}/Doxyfile @ONLY)

	ADD_CUSTOM_COMMAND(OUTPUT ${DOXYGEN_BIN_DIR} COMMAND ${DOXYGEN_CMD})
	ADD_CUSTOM_TARGET(doxy DEPENDS ${DOXYGEN_BIN_DIR} WORKING_DIRECTORY ${PROJECT_BINARY_DIR} SOURCES ${DOXYGEN_CFG})
ENDIF()

FIND_PROGRAM(CLOC_BIN cloc CMAKE_FIND_ROOT_PATH_BOTH)
IF(CLOC_BIN)
	SET(CLOC_FILE "${PROJECT_BINARY_DIR}/cloc.xml")
	SET(CLOC_CMD ${CLOC_BIN} ${CMAKE_SOURCE_DIR})

	ADD_CUSTOM_COMMAND(OUTPUT ${CLOC_FILE} COMMAND ${CLOC_CMD} --by-file-by-lang --xml --report-file=${CLOC_FILE})
	ADD_CUSTOM_TARGET(cloc COMMAND ${CLOC_CMD})
	ADD_CUSTOM_TARGET(cloc.report DEPENDS ${CLOC_FILE})
ENDIF()

FIND_PROGRAM(UNCRUSTIFY uncrustify CMAKE_FIND_ROOT_PATH_BOTH)
IF(UNCRUSTIFY)
	FILE(GLOB_RECURSE FILES_JAVA ${PROJECT_SOURCE_DIR}/*.java)
	FILE(GLOB_RECURSE FILES_CPP ${PROJECT_SOURCE_DIR}/*.cpp)
	FILE(GLOB_RECURSE FILES_H ${PROJECT_SOURCE_DIR}/*.h)
	FILE(GLOB_RECURSE FILES_MM ${PROJECT_SOURCE_DIR}/*.mm)
	FILE(GLOB_RECURSE FILES_M ${PROJECT_SOURCE_DIR}/*.m)
	SET(FILES ${FILES_JAVA} ${FILES_CPP} ${FILES_H} ${FILES_MM} ${FILES_M})
	SET(FORMATTING_FILE ${PROJECT_BINARY_DIR}/formatting.files)

	FILE(WRITE ${FORMATTING_FILE} "")
	FOREACH(file ${FILES})
		IF(NOT "${file}" MATCHES "/external/")
			FILE(APPEND ${FORMATTING_FILE} ${file})
			FILE(APPEND ${FORMATTING_FILE} "\n")
		ENDIF()
	ENDFOREACH()

	SET(UNCRUSTIFY_CFG ${PROJECT_SOURCE_DIR}/uncrustify.cfg)
	SET(UNCRUSTIFY_CMD ${UNCRUSTIFY} -c ${UNCRUSTIFY_CFG} --replace --no-backup -q -F ${FORMATTING_FILE})

	EXECUTE_PROCESS(COMMAND ${UNCRUSTIFY} --version OUTPUT_VARIABLE UNCRUSTIFY_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
	STRING(REPLACE "uncrustify " "" UNCRUSTIFY_VERSION ${UNCRUSTIFY_VERSION})

	SET(UNCRUSTIFY_NEEDED_VERSION "0.65")
	IF("${UNCRUSTIFY_VERSION}" STRLESS "${UNCRUSTIFY_NEEDED_VERSION}")
		MESSAGE(WARNING "Uncrustify seems to be too old. Use at least ${UNCRUSTIFY_NEEDED_VERSION}... you are using: ${UNCRUSTIFY_VERSION}")
	ELSE()
		ADD_CUSTOM_TARGET(format COMMAND ${UNCRUSTIFY_CMD} SOURCES ${UNCRUSTIFY_CFG} ${FILES})
	ENDIF()
ENDIF()

FIND_PROGRAM(QMLLINT_BIN qmllint CMAKE_FIND_ROOT_PATH_BOTH)
IF(QMLLINT_BIN)
	FILE(GLOB_RECURSE TEST_FILES_QML ${TEST_DIR}/qml/*.qml)
	FILE(GLOB_RECURSE TEST_FILES_QML_STATIONARY ${TEST_DIR}/qml_stationary/*.qml)
	FILE(GLOB_RECURSE FILES_QML ${RESOURCES_DIR}/qml/*.qml)
	FILE(GLOB_RECURSE FILES_QML_STATIONARY ${RESOURCES_DIR}/qml_stationary/*.qml)
	FILE(GLOB_RECURSE FILES_JS ${RESOURCES_DIR}/qml/*.js)
	FILE(GLOB_RECURSE FILES_JS_STATIONARY ${RESOURCES_DIR}/qml_stationary/*.js)
	SET(QMLLINT_CMD ${QMLLINT_BIN} ${FILES_QML} ${FILES_QML_STATIONARY} ${FILES_JS})

	ADD_CUSTOM_TARGET(qmllint COMMAND ${QMLLINT_CMD} SOURCES ${TEST_FILES_QML} ${TEST_FILES_QML_STATIONARY} ${FILES_QML} ${FILES_QML_STATIONARY} ${FILES_JS} ${FILES_JS_STATIONARY})
ENDIF()

# doc8 (https://pypi.python.org/pypi/doc8)
FIND_PROGRAM(DOC8_BIN doc8 CMAKE_FIND_ROOT_PATH_BOTH)
FUNCTION(CREATE_DOC8_TARGET _dir _name)
	IF(DOC8_BIN)
		ADD_CUSTOM_TARGET(doc8.${_name} COMMAND ${DOC8_BIN} --config ${PROJECT_SOURCE_DIR}/docs/doc8.ini WORKING_DIRECTORY ${_dir})
		IF(NOT TARGET doc8)
			ADD_CUSTOM_TARGET(doc8)
		ENDIF()
		ADD_DEPENDENCIES(doc8 doc8.${_name})
	ENDIF()
ENDFUNCTION()

FIND_PROGRAM(CONVERT convert CMAKE_FIND_ROOT_PATH_BOTH)
IF(CONVERT)
	SET(CONVERT_CMD convert -background transparent)
	ADD_CUSTOM_TARGET(npaicons
		COMMAND ${CONVERT_CMD} npa.svg -define icon:auto-resize=256,96,64,48,40,32,24,20,16 npa.ico
		COMMAND ${CONVERT_CMD} npa.svg -resize 16x16 autentapp2.iconset/icon_16x16.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 32x32 autentapp2.iconset/icon_16x16@2x.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 32x32 autentapp2.iconset/icon_32x32.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 64x64 autentapp2.iconset/icon_32x32@2x.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 128x128 autentapp2.iconset/icon_128x128.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 256x256 autentapp2.iconset/icon_128x128@2x.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 256x256 autentapp2.iconset/icon_256x256.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 512x512 autentapp2.iconset/icon_256x256@2x.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 512x512 autentapp2.iconset/icon_512x512.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 1024x1024 autentapp2.iconset/icon_512x512@2x.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 36x36 android/ldpi/npa.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 48x48 android/mdpi/npa.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 72x72 android/hdpi/npa.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 96x96 android/xhdpi/npa.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 144x144 android/xxhdpi/npa.png
		COMMAND ${CONVERT_CMD} npa.svg -resize 192x192 android/xxxhdpi/npa.png
		COMMAND ${CONVERT_CMD} npa_beta.svg -resize 36x36 android/ldpi/npa_beta.png
		COMMAND ${CONVERT_CMD} npa_beta.svg -resize 48x48 android/mdpi/npa_beta.png
		COMMAND ${CONVERT_CMD} npa_beta.svg -resize 72x72 android/hdpi/npa_beta.png
		COMMAND ${CONVERT_CMD} npa_beta.svg -resize 96x96 android/xhdpi/npa_beta.png
		COMMAND ${CONVERT_CMD} npa_beta.svg -resize 144x144 android/xxhdpi/npa_beta.png
		COMMAND ${CONVERT_CMD} npa_beta.svg -resize 192x192 android/xxxhdpi/npa_beta.png
		COMMAND ${CONVERT_CMD} npa_preview.svg -resize 36x36 android/ldpi/npa_preview.png
		COMMAND ${CONVERT_CMD} npa_preview.svg -resize 48x48 android/mdpi/npa_preview.png
		COMMAND ${CONVERT_CMD} npa_preview.svg -resize 72x72 android/hdpi/npa_preview.png
		COMMAND ${CONVERT_CMD} npa_preview.svg -resize 96x96 android/xhdpi/npa_preview.png
		COMMAND ${CONVERT_CMD} npa_preview.svg -resize 144x144 android/xxhdpi/npa_preview.png
		COMMAND ${CONVERT_CMD} npa_preview.svg -resize 192x192 android/xxxhdpi/npa_preview.png
		WORKING_DIRECTORY ${RESOURCES_DIR}/images)
ENDIF()

FIND_PROGRAM(PNGQUANT pngquant CMAKE_FIND_ROOT_PATH_BOTH)
IF(PNGQUANT)
SET(PNGQUANT_CMD pngquant -f -o)
	ADD_CUSTOM_TARGET(pngquant
		COMMAND ${PNGQUANT_CMD} autentapp2.iconset/icon_16x16.png -- autentapp2.iconset/icon_16x16.png
		COMMAND ${PNGQUANT_CMD} autentapp2.iconset/icon_16x16@2x.png -- autentapp2.iconset/icon_16x16@2x.png
		COMMAND ${PNGQUANT_CMD} autentapp2.iconset/icon_32x32.png -- autentapp2.iconset/icon_32x32.png
		COMMAND ${PNGQUANT_CMD} autentapp2.iconset/icon_32x32@2x.png -- autentapp2.iconset/icon_32x32@2x.png
		COMMAND ${PNGQUANT_CMD} autentapp2.iconset/icon_128x128.png -- autentapp2.iconset/icon_128x128.png
		COMMAND ${PNGQUANT_CMD} autentapp2.iconset/icon_128x128@2x.png -- autentapp2.iconset/icon_128x128@2x.png
		COMMAND ${PNGQUANT_CMD} autentapp2.iconset/icon_256x256.png -- autentapp2.iconset/icon_256x256.png
		COMMAND ${PNGQUANT_CMD} autentapp2.iconset/icon_256x256@2x.png -- autentapp2.iconset/icon_256x256@2x.png
		COMMAND ${PNGQUANT_CMD} autentapp2.iconset/icon_512x512.png -- autentapp2.iconset/icon_512x512.png
		COMMAND ${PNGQUANT_CMD} autentapp2.iconset/icon_512x512@2x.png -- autentapp2.iconset/icon_512x512@2x.png
		COMMAND ${PNGQUANT_CMD} android/ldpi/npa.png -- android/ldpi/npa.png
		COMMAND ${PNGQUANT_CMD} android/mdpi/npa.png -- android/mdpi/npa.png
		COMMAND ${PNGQUANT_CMD} android/hdpi/npa.png -- android/hdpi/npa.png
		COMMAND ${PNGQUANT_CMD} android/xhdpi/npa.png -- android/xhdpi/npa.png
		COMMAND ${PNGQUANT_CMD} android/xxhdpi/npa.png -- android/xxhdpi/npa.png
		COMMAND ${PNGQUANT_CMD} android/xxxhdpi/npa.png -- android/xxxhdpi/npa.png
		COMMAND ${PNGQUANT_CMD} android/ldpi/npa_beta.png -- android/ldpi/npa_beta.png
		COMMAND ${PNGQUANT_CMD} android/mdpi/npa_beta.png -- android/mdpi/npa_beta.png
		COMMAND ${PNGQUANT_CMD} android/hdpi/npa_beta.png -- android/hdpi/npa_beta.png
		COMMAND ${PNGQUANT_CMD} android/xhdpi/npa_beta.png -- android/xhdpi/npa_beta.png
		COMMAND ${PNGQUANT_CMD} android/xxhdpi/npa_beta.png -- android/xxhdpi/npa_beta.png
		COMMAND ${PNGQUANT_CMD} android/xxxhdpi/npa_beta.png -- android/xxxhdpi/npa_beta.png
		COMMAND ${PNGQUANT_CMD} android/ldpi/npa_preview.png -- android/ldpi/npa_preview.png
		COMMAND ${PNGQUANT_CMD} android/mdpi/npa_preview.png -- android/mdpi/npa_preview.png
		COMMAND ${PNGQUANT_CMD} android/hdpi/npa_preview.png -- android/hdpi/npa_preview.png
		COMMAND ${PNGQUANT_CMD} android/xhdpi/npa_preview.png -- android/xhdpi/npa_preview.png
		COMMAND ${PNGQUANT_CMD} android/xxhdpi/npa_preview.png -- android/xxhdpi/npa_preview.png
		COMMAND ${PNGQUANT_CMD} android/xxxhdpi/npa_preview.png -- android/xxxhdpi/npa_preview.png
		WORKING_DIRECTORY ${RESOURCES_DIR}/images)
ENDIF()

INCLUDE(Sphinx)
