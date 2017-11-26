# make-package
A simple script to create a compressed folder containing your project's files for distribution.

## Usage
* Place the make-package script (the Batch or the Bash one, depending on your system) in your project's directory
* Run the script providing all the needed arguments
  * project name
  * major version
  * minor version
  * patch version
  * (only on Bash script) target system
  * target architecture
  * (only on Batch script) wether or not to use MinGW library names (1 or 0, defaults to 0)
* The script will now create a zip containing your project files

You can **customize** how the script works by modifying the variables at the start of the script.

## License
See LICENSE file.
