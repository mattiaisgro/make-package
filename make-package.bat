:: MIT License

:: Copyright (c) 2017 Mattia Isgrò

:: Permission is hereby granted, free of charge, to any person obtaining a copy
:: of this software and associated documentation files (the "Software"), to deal
:: in the Software without restriction, including without limitation the rights
:: to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
:: copies of the Software, and to permit persons to whom the Software is
:: furnished to do so, subject to the following conditions:

:: The above copyright notice and this permission notice shall be included in all
:: copies or substantial portions of the Software.

:: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
:: IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
:: FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
:: AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
:: LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
:: OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
:: SOFTWARE.


@echo off

:: The project's main directory
set TREE_MAIN_DIRECTORY="."

:: Args
set PACKAGE_NAME=%1
set VERSION_MAJOR=%2
set VERSION_MINOR=%3
set VERSION_PATCH=%4
set TARGET_ARCH=%5
set USE_MINGW=%6

:: Check that arguments exist
if "%TARGET_ARCH%" == "" (
	goto usage_and_exit
)

:: Configuration

:: Where are header files
set INCLUDE_DIRECTORY=include
:: Where are library files
set LIBRARY_DIRECTORY=lib
:: Where are binaries
set BINARY_DIRECTORY=bin
:: Where is source code
set SOURCE_DIRECTORY=src
:: Where is the version header
set HEADER_VERSION_H="%SOURCE_DIRECTORY%\version.h"
:: Which header files should be included
set HEADER_PATTERN="%SOURCE_DIRECTORY%\*.h"
:: Path to executable
set EXECUTABLE="%BINARY_DIRECTORY%\%PROJECT_NAME%.exe"
:: Path to static library
set STATIC_LIBRARY="%LIBRARY_DIRECTORY%\%PACKAGE_NAME%.lib"
:: Path to shared library
set SHARED_LIBRARY="%LIBRARY_DIRECTORY%\%PACKAGE_NAME%.dll"
:: Path to readme file
set README_FILE=README.md
:: Path to license file
set LICENSE_FILE=LICENSE

:: Change these settings to configure the script

:: Should include the readme?
set PLACE_README=1
:: Should include the license?
set PLACE_LICENSE=1
:: Should include executable?
set PLACE_EXECUTABLE=0
:: Should include the static library?
set PLACE_STATIC_LIBRARY=1
:: Should include the shared library?
set PLACE_SHARED_LIBRARY=1
:: Should place the header files?
set PLACE_HEADERS=1

:: The final name of the package
set PACKAGE_NAME_PATTERN=%PACKAGE_NAME%-%VERSION_MAJOR%-%VERSION_MINOR%-%VERSION_PATCH%-windows-%TARGET_ARCH%


if "%USE_MINGW%" == "1" (
	set STATIC_LIBRARY="%LIBRARY_DIRECTORY%\lib%PACKAGE_NAME%.a"
	set SHARED_LIBRARY="%LIBRARY_DIRECTORY%\lib%PACKAGE_NAME%.dll"
)


echo /!/ Starting dependency check...

if %PLACE_README% == 1 (
	echo --- README selected
	if exist %TREE_MAIN_DIRECTORY%/%README_FILE% (
		echo ^>^>^> README.md... found
	) else (
		echo !!! README.md... not found
		exit /B 1
	)
)

if %PLACE_LICENSE% == 1 (
	echo --- LICENSE selected
	if exist %TREE_MAIN_DIRECTORY%/%LICENSE_FILE% (
		echo ^>^>^> LICENSE... found
	) else (
		echo !!! LICENSE... not found
		exit /B 1
	)
)

if %PLACE_EXECUTABLE% == 1 (
	echo --- Executable selected
	if exist %TREE_MAIN_DIRECTORY%/%EXECUTABLE% (
		echo ^>^>^> Executable... found
	) else (
		echo !!! Executable... not found
		exit /B 1
	)
)

if %PLACE_STATIC_LIBRARY% == 1 (
	echo --- Static library selected
	if exist %TREE_MAIN_DIRECTORY%/%STATIC_LIBRARY% (
		echo ^>^>^> Static library... found
	) else (
		echo !!! Static library... not found
		exit /B 1
	)
)

if %PLACE_SHARED_LIBRARY% == 1 (
	echo --- Shared library selected
	if exist %TREE_MAIN_DIRECTORY%/%SHARED_LIBRARY% (
		echo ^>^>^> Shared library... found
	) else (

		echo !!! Shared library... not found
		exit /B 1
	)
)

echo --- (REQUIRED) Checking for generated version.h header...
if exist %TREE_MAIN_DIRECTORY%/%HEADER_VERSION_H% (
	echo ^>^>^> version.h... found
) else (
	echo !!! version.h... not found
	echo !!! Configure the build system in order to get the version.h header
	exit /B 1
)


echo /+/ Ready to build package...

:set_compress_list

mkdir %PACKAGE_NAME_PATTERN%

if "%PLACE_README%" == "1" (
	copy /Y %TREE_MAIN_DIRECTORY%\%README_FILE% %PACKAGE_NAME_PATTERN%\ >nul
)

if "%PLACE_LICENSE%" == "1" (
	copy /Y %TREE_MAIN_DIRECTORY%\%LICENSE_FILE% %PACKAGE_NAME_PATTERN%\ >nul
)

if "%PLACE_EXECUTABLE%" == "1" (
	mkdir %PACKAGE_NAME_PATTERN%\%LIBRARY_DIRECTORY% >nul
) else (
	mkdir %PACKAGE_NAME_PATTERN%\%LIBRARY_DIRECTORY% >nul
)



if "%PLACE_STATIC_LIBRARY%" == "1" (
	copy /Y %TREE_MAIN_DIRECTORY%\%STATIC_LIBRARY% %PACKAGE_NAME_PATTERN%\%LIBRARY_DIRECTORY% >nul
)

if "%PLACE_STATIC_LIBRARY%" == "1" (
	copy /Y %TREE_MAIN_DIRECTORY%\%STATIC_LIBRARY% %PACKAGE_NAME_PATTERN%\%LIBRARY_DIRECTORY% >nul
)

if "%PLACE_SHARED_LIBRARY%" == "1" (
	copy /Y %TREE_MAIN_DIRECTORY%\%SHARED_LIBRARY% %PACKAGE_NAME_PATTERN%\%LIBRARY_DIRECTORY% >nul
)

if "%PLACE_HEADERS%" == "1" (
	mkdir %PACKAGE_NAME_PATTERN%\%INCLUDE_DIRECTORY% >nul
	copy /Y %TREE_MAIN_DIRECTORY%\%HEADER_PATTERN% %PACKAGE_NAME_PATTERN%\%INCLUDE_DIRECTORY% >nul
)

if errorlevel 1 (
	echo /-/ An error occurred while copying files
	exit /B 1
)

echo /i/ Zipping everything...
echo /i/ Using PowerShell to make a compressed package

if exist %PACKAGE_NAME_PATTERN%.zip (
	del %PACKAGE_NAME_PATTERN%.zip
)

powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.fileSystem'; [IO.Compression.Zipfile]::CreateFromDirectory('%PACKAGE_NAME_PATTERN%', '%PACKAGE_NAME_PATTERN%.zip'); }"

if errorlevel 1 (
	echo /-/ Powershell wasn't able to build your package
	rmdir /S/Q %PACKAGE_NAME_PATTERN%
	exit /B 1
)

:temporary_cleanup
echo /i/ Cleanup...
: Delete temp dir
rmdir /S/Q %PACKAGE_NAME_PATTERN%

echo /+/ Your package: %PACKAGE_NAME_PATTERN% was successfully built

exit /B 0

:usage_and_exit
echo * Usage: %0 ^<project_name^> ^<version_major^> ^<version_minor^> ^<version_patch^> ^<target_arch^> ^<use_mingw^>
exit /B 1
