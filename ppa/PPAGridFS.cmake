# Before execute, please check if the following variables are set correctly in the first lines of the script:
# - PPA_MAINTAINER: master of ppa generation, can be passed via -D cmake option
# - PPA_NAME: name of ppa acount, can be passed via -D cmake option
# - PPA_REVISION: Debian revision number of the generated package, can be chaged via -D cmake option
# - PPA_HOMEPAGE: homepage set in generated package
# - PPA_DISTROS: ubuntu distributions for which a package is generated and uploaded

IF (NOT PPA_MAINTAINER)
  SET(PPA_MAINTAINER "David Graf <davidagraf@gmail.com>")
ENDIF()
IF (NOT PPA_NAME)
  SET(PPA_NAME "28msec-cmake")
ENDIF()
IF (NOT PPA_REVISION)
  SET(PPA_REVISION "0")
ENDIF()

SET(PPA_HOMEPAGE "http://www.28msec.com/")
SET(PPA_DISTROS "lucid" "maverick" "natty" "oneiric" "precise")
SET(PPA_VERSION "2.8.8")

SET(PPA_DEPENDENCIES "build-essential, debhelper, cmake")
SET(PPA_HOST "ppa:28msec/cmake")
EXECUTE_PROCESS(COMMAND date -R OUTPUT_VARIABLE PPA_DATE_TIME)

SET(PPA_DIR "@CMAKE_CURRENT_BINARY_DIR@/ppaingCMake")
SET(PPA_SOURCE_DIR "${PPA_DIR}/cmake-${PPA_VERSION}")
SET(PPA_DEBIAN_DIR "${PPA_SOURCE_DIR}/debian")
SET(PPA_DEBIAN_TEMPL_DIR "@CMAKE_CURRENT_SOURCE_DIR@/debianCMake")

FILE(REMOVE_RECURSE ${PPA_DIR})
FILE(MAKE_DIRECTORY ${PPA_SOURCE_DIR})

MESSAGE(STATUS "Preparing CMake sources for PPA.")
EXECUTE_PROCESS(
  COMMAND wget http://www.cmake.org/files/v2.8/cmake-2.8.8.tar.gz
  WORKING_DIRECTORY ${PPA_DIR})

EXECUTE_PROCESS(
  COMMAND tar xvfz cmake-${PPA_VERSION}.tar.gz
  WORKING_DIRECTORY ${PPA_DIR})

MESSAGE(STATUS "Packing CMake sources for PPA.")
EXECUTE_PROCESS(
  COMMAND tar czf 28msec-cmake_${PPA_VERSION}.orig.tar.gz  cmake-${PPA_VERSION}
  WORKING_DIRECTORY ${PPA_DIR})

FOREACH(PPA_DISTRO ${PPA_DISTROS})
  EXECUTE_PROCESS(
    COMMAND cp 28msec-cmake_${PPA_VERSION}.orig.tar.gz 28msec-cmake_${PPA_VERSION}~${PPA_DISTRO}${PPA_REVISION}.orig.tar.gz
    WORKING_DIRECTORY ${PPA_DIR})

  MESSAGE(STATUS "Creating configration files for ${PPA_DISTRO}.")
  CONFIGURE_FILE(${PPA_DEBIAN_TEMPL_DIR}/changelog.in "${PPA_DEBIAN_DIR}/changelog" @ONLY)
  CONFIGURE_FILE(${PPA_DEBIAN_TEMPL_DIR}/copyright.in "${PPA_DEBIAN_DIR}/copyright" @ONLY)
  CONFIGURE_FILE(${PPA_DEBIAN_TEMPL_DIR}/control.in "${PPA_DEBIAN_DIR}/control" @ONLY)
  CONFIGURE_FILE(${PPA_DEBIAN_TEMPL_DIR}/rules.in "${PPA_DEBIAN_DIR}/rules" @ONLY)

  FILE(WRITE ${PPA_DEBIAN_DIR}/compat "7")
  FILE(WRITE ${PPA_DEBIAN_DIR}/source/format "3.0 (quilt)")

  MESSAGE(STATUS "Debian source package generation for ${PPA_DISTRO}.")
  EXECUTE_PROCESS(
    COMMAND debuild -S
    RESULT_VARIABLE RETURN_CODE
    WORKING_DIRECTORY ${PPA_SOURCE_DIR})
  IF (NOT RETURN_CODE EQUAL 0)
    MESSAGE(FATAL_ERROR "Debian package generation failed")
  ENDIF (NOT RETURN_CODE EQUAL 0)

  SET(DEBIAN_CHANGES_FILE "${PPA_NAME}_${PPA_VERSION}~${PPA_DISTRO}${PPA_REVISION}_source.changes")
  MESSAGE(STATUS "dputting ${DEBIAN_CHANGES_FILE}.")
  EXECUTE_PROCESS(
    COMMAND dput ${PPA_HOST} ${DEBIAN_CHANGES_FILE}
    RESULT_VARIABLE RETURN_CODE
    WORKING_DIRECTORY ${PPA_DIR})
  IF (NOT RETURN_CODE EQUAL 0)
    MESSAGE(FATAL_ERROR "dputting failed")
  ENDIF (NOT RETURN_CODE EQUAL 0)

ENDFOREACH()
