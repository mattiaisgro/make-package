#!/bin/sh

# MIT License

# Copyright (c) 2017 Mattia Isgrò

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This script is based on the work of Stefano Belli in erebos-api

if [ $# -lt 6 ]; then
	echo " * Usage: $0 <project_name> <version_major> <version_minor> <version_patch> <target_os> <target_arch> [ignored...]"
	exit 1
fi

# The project's main directory
TREE_MAIN_DIRECTORY="."

PACKAGE_NAME=$1
VERSION_MAJOR=$2
VERSION_MINOR=$3
VERSION_PATCH=$4
TARGET_OS=$5
TARGET_ARCH=$6

# Configuration

# Where are header files
INCLUDE_DIRECTORY="include"
# Where are library files
LIBRARY_DIRECTORY="lib"
# Where are binaries
BINARY_DIRECTORY="bin"
# Where is source code
SOURCE_DIRECTORY="src"
# Where is the version header
HEADER_VERSION_H="${SOURCE_DIRECTORY}/version.h"
# Which header files should be included
HEADER_PATTERN="${SOURCE_DIRECTORY}/*.h"
# Path to executable
EXECUTABLE="${BINARY_DIRECTORY}/${PROJECT_NAME}"
# Path to static library
STATIC_LIBRARY="${LIBRARY_DIRECTORY}/lib${PROJECT_NAME}.a"
# Path to shared library
SHARED_LIBRARY="${LIBRARY_DIRECTORY}/lib${PROJECT_NAME}.so"
# Path to readme file
README_FILE="README.md"
# Path to license file
LICENSE_FILE="LICENSE"

# Change these settings to configure the script

# Should include the readme?
PLACE_README=true
# Should include the license?
PLACE_LICENSE=true
# Should include executable?
PLACE_EXECUTABLE=false
# Should include the static library?
PLACE_STATIC_LIBRARY=true
# Should include the shared library?
PLACE_SHARED_LIBRARY=true
# Should place the header files?
PLACE_HEADERS=true

# The final name of the package
PACKAGE_NAME_PATTERN="${PACKAGE_NAME}-${VERSION_MAJOR}-${VERSION_MINOR}-${VERSION_PATCH}-${TARGET_OS}-${TARGET_ARCH}"

check_depends() {
	if $PLACE_README; then
		echo "--- README selected"
		if [ -f $TREE_MAIN_DIRECTORY/$README_FILE ]; then
			echo ">>> README.md... found"
		else
			echo "!!! README.md... not found"
			exit 1
		fi
	fi

	if $PLACE_LICENSE; then
		echo "--- LICENSE selected"
		if [ -f $TREE_MAIN_DIRECTORY/$LICENSE_FILE ]; then
			echo ">>> LICENSE... found"
		else
			echo "!!! LICENSE... not found"
			exit 1
		fi
	fi

	if $PLACE_EXECUTABLE; then
		echo "--- Executable selected"
		if [ -f $TREE_MAIN_DIRECTORY/$EXECUTABLE ]; then
			echo ">>> Executable... found"
		else
			echo "!!! Executable... not found"
			exit 1
		fi
	fi

	if $PLACE_STATIC_LIBRARY; then
		echo "--- Static library selected"
		if [ -f $TREE_MAIN_DIRECTORY/$STATIC_LIBRARY ]; then
			echo ">>> Static library... found"
		else
			echo "!!! Static library... not found"
			exit 1
		fi
	fi

	if $PACKAGE_PLACE_SHARED; then
		echo "--- Shared library selected"
		if [ -f $TREE_MAIN_DIRECTORY/$SHARED_LIBRARY ]; then
			echo ">>> Shared library... found"
		else
			echo "!!! Shared library... not found"
			exit 1
		fi
	fi

	if $PACKAGE_PLACE_HEADERS; then
		echo "--- Development headers selected"
		if ls $TREE_MAIN_DIRECTORY/$HEADER_PATTERN 2>/dev/null >>/dev/null; then
			echo ">>> Development headers... found"
		else
			echo "!!! Development headers... not found"
			exit 1
		fi
	fi

	echo "--- (REQUIRED) Checking for generated version.h header..."
	if [ ! -f $TREE_MAIN_DIRECTORY/$HEADER_VERSION_H ]; then
		echo "!!! version.h... not found"
		echo "!!! Configure the build system in order to get the version.h header"
		exit 1
	fi

	echo ">>> version.h... found"
}

check_zip() {
	echo "--- Checking for zip program..."
	if ! which zip 2>/dev/null >>/dev/null; then
		echo "!!! zip: not found in PATH environment variable"
		exit 1
	fi
	echo ">>> zip... found"
}

COMPRESS_LIST=""
set_compress_list() {

	if $PLACE_README; then
		cp $TREE_MAIN_DIRECTORY/$README_FILE .
		COMPRESS_LIST="$README_FILE"
	fi

	if $PLACE_LICENSE; then
		cp $TREE_MAIN_DIRECTORY/$LICENSE_FILE .
		COMPRESS_LIST="$COMPRESS_LIST $LICENSE_FILE"
	fi

	if $PLACE_EXECUTABLE; then
		mkdir -p $BINARY_DIRECTORY
		cp $TREE_MAIN_DIRECTORY/$EXECUTABLE $BINARY_DIRECTORY
		COMPRESS_LIST="$COMPRESS_LIST $BINARY_DIRECTORY/*"
	fi

	if $PLACE_STATIC_LIBRARY; then
		mkdir -p $LIBRARY_DIRECTORY
		cp $TREE_MAIN_DIRECTORY/$STATIC_LIBRARY $LIBRARY_DIRECTORY
		COMPRESS_LIST="$COMPRESS_LIST $LIBRARY_DIRECTORY/*"
	fi

	if $PACKAGE_PLACE_SHARED; then
		if [ ! -d $LIBRARY_DIRECTORY ]; then
			COMPRESS_LIST="$COMPRESS_LIST $LIBRARY_DIRECTORY/*"
		fi

		mkdir -p $LIBRARY_DIRECTORY
		cp $TREE_MAIN_DIRECTORY/$SHARED_LIBRARY $LIBRARY_DIRECTORY
	fi

	if $PACKAGE_PLACE_HEADERS; then
		mkdir -p $INCLUDE_DIRECTORY
		cp $TREE_MAIN_DIRECTORY/$HEADER_PATTERN $INCLUDE_DIRECTORY
		COMPRESS_LIST="$COMPRESS_LIST $INCLUDE_DIRECTORY/*"
	fi
}

cleanup() {
	rm -rf $COMPRESS_LIST 2>/dev/null
	for elem in $COMPRESS_LIST; do
		rm -r $(echo $elem | sed 's:/#') 2>/dev/null
	done
}

SHOULD_EXIT=0
echo "/!/ Starting dependency check..."
check_depends
echo "/+/ Ready to build package..."
echo "/i/ Using zip"
check_zip
set_compress_list
echo "/i/ Including the following:"

for i in $COMPRESS_LIST; do
	echo " > f: $i"
done

echo "/i/ Zipping everything..."
if ! zip -9 $PACKAGE_NAME_PATTERN $COMPRESS_LIST; then
	echo "/-/ zip wasn't able to build your package"
	SHOULD_EXIT=1
fi
echo "/i/ Cleanup..."
cleanup
echo "/+/ Your package: ${PACKAGE_NAME_PATTERN} was successfully built"
exit $SHOULD_EXIT
