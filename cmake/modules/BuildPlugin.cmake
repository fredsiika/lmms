# BuildPlugin.cmake - Copyright (c) 2008 Tobias Doerffel
#
# description: build LMMS-plugin
# usage: BUILD_PLUGIN(<PLUGIN_NAME> <PLUGIN_SOURCES> MOCFILES <HEADERS_FOR_MOC> EMBEDDED_RESOURCES <LIST_OF_FILES_TO_EMBED> UICFILES <UI_FILES_TO_COMPILE> LINK <SHARED|MODULE>)

MACRO(BUILD_PLUGIN PLUGIN_NAME)
	CMAKE_PARSE_ARGUMENTS(PLUGIN "" "" "MOCFILES;EMBEDDED_RESOURCES;UICFILES;LINK" ${ARGN})
	SET(PLUGIN_SOURCES ${PLUGIN_UNPARSED_ARGUMENTS})

	INCLUDE_DIRECTORIES("${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_BINARY_DIR}" "${CMAKE_SOURCE_DIR}/include" "${CMAKE_SOURCE_DIR}/src/gui")

	ADD_DEFINITIONS(-DPLUGIN_NAME=${PLUGIN_NAME})

	LIST(LENGTH PLUGIN_EMBEDDED_RESOURCES ER_LEN)
	IF(ER_LEN)
		# Expand and sort arguments to avoid locale dependent sorting in
		# shell
		SET(NEW_ARGS)
		FOREACH(ARG ${PLUGIN_EMBEDDED_RESOURCES})
			FILE(GLOB EXPANDED "${ARG}")
			LIST(SORT EXPANDED)
			FOREACH(ITEM ${EXPANDED})
				LIST(APPEND NEW_ARGS "${ITEM}")
			ENDFOREACH()
		ENDFOREACH()
		SET(PLUGIN_EMBEDDED_RESOURCES ${NEW_ARGS})

		SET(ER_H "${CMAKE_CURRENT_BINARY_DIR}/embedded_resources.h")
		ADD_CUSTOM_COMMAND(OUTPUT ${ER_H}
			COMMAND ${BIN2RES}
			ARGS ${PLUGIN_EMBEDDED_RESOURCES} > "${ER_H}"
			DEPENDS bin2res)
	ENDIF(ER_LEN)

	IF(QT5)
		QT5_WRAP_CPP(plugin_MOC_out ${PLUGIN_MOCFILES})
		QT5_WRAP_UI(plugin_UIC_out ${PLUGIN_UICFILES})
	ELSE()
		QT4_WRAP_CPP(plugin_MOC_out ${PLUGIN_MOCFILES})
		QT4_WRAP_UI(plugin_UIC_out ${PLUGIN_UICFILES})
	ENDIF()

	FOREACH(f ${PLUGIN_SOURCES})
		ADD_FILE_DEPENDENCIES(${f} ${ER_H} ${plugin_UIC_out})
	ENDFOREACH(f)

	IF(LMMS_BUILD_APPLE)
		LINK_DIRECTORIES("${CMAKE_BINARY_DIR}")
		LINK_LIBRARIES(${QT_LIBRARIES})
	ENDIF(LMMS_BUILD_APPLE)
	IF(LMMS_BUILD_WIN32)
		LINK_DIRECTORIES("${CMAKE_BINARY_DIR}" "${CMAKE_SOURCE_DIR}")
		LINK_LIBRARIES(${QT_LIBRARIES})
	ENDIF(LMMS_BUILD_WIN32)
	IF(LMMS_BUILD_MSYS AND CMAKE_BUILD_TYPE STREQUAL "Debug")
		# Override Qt debug libraries with release versions
		SET(QT_LIBRARIES "${QT_OVERRIDE_LIBRARIES}")
	ENDIF()

	IF ("${PLUGIN_LINK}" STREQUAL "SHARED")
	  ADD_LIBRARY(${PLUGIN_NAME} SHARED ${PLUGIN_SOURCES} ${plugin_MOC_out})
	ELSE ()
	  ADD_LIBRARY(${PLUGIN_NAME} MODULE ${PLUGIN_SOURCES} ${plugin_MOC_out})
	ENDIF ()
	
	IF(QT5)
		TARGET_LINK_LIBRARIES(${PLUGIN_NAME} Qt5::Widgets Qt5::Xml)
	ENDIF()
	IF(LMMS_BUILD_WIN32)
		TARGET_LINK_LIBRARIES(${PLUGIN_NAME} lmms)
	ENDIF(LMMS_BUILD_WIN32)

	INSTALL(TARGETS ${PLUGIN_NAME} LIBRARY DESTINATION "${PLUGIN_DIR}")

	IF(LMMS_BUILD_APPLE)
		SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES LINK_FLAGS "-bundle_loader \"${CMAKE_BINARY_DIR}/lmms\"")
		ADD_DEPENDENCIES(${PLUGIN_NAME} lmms)
	ENDIF(LMMS_BUILD_APPLE)
	IF(LMMS_BUILD_WIN32)
		SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES PREFIX "")
		ADD_CUSTOM_COMMAND(TARGET ${PLUGIN_NAME} POST_BUILD COMMAND ${STRIP} "$<TARGET_FILE:${PLUGIN_NAME}>")
	ENDIF(LMMS_BUILD_WIN32)

	SET_DIRECTORY_PROPERTIES(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${ER_H} ${plugin_MOC_out}")
ENDMACRO(BUILD_PLUGIN)

