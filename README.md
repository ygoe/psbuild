# PowerShell build framework

_Automated, local building of Visual Studio solutions and calling external tools like unit tests, source code commit, obfuscation, digitally signing, file publishing and transfer._

This portable, customisable build script does not only build your solution. It rather coordinates diverse tasks that are to be executed for a release build or a commit or at other occasions. The framework consists of multiple modules that each cover a topic, a central function library, and a project-specific control file. To simplify running the particular scenarios there are additional Windows batch files.

The build script can be used on every developer computer and it serves as a great entry script on a build server. No need to configure all required tasks on your build server, and redo the work when switching build servers. All the build instructions are already in the repository and run everywhere. Updates to the build procedure are simply committed to the repository just like any other code.

See http://unclassified.software/source/psbuild for further information.

## Usage

The recommended way to use this framework is to copy the directory `_scripts` into your solution directory. You can delete the module files in `_scripts\buildscript\modules` that you do not need. Customise the file `_scripts\buildscript\control.ps1` so that it runs the actions you want to automate. The included example is from the FieldLog project. Finally, customise the batch files `_scripts\*.cmd` to run the control script with a set of configurations.

The most interesting entry batch files are `build.cmd` to start a default release build and `commit.cmd` to test-build the solution and commit it to version control.

If you need to move some of the paths, you can update them in the entry batch files `_scripts\*.cmd` as well as the psbuild main script `_scripts\buildscript\psbuild.ps1` in the first few lines. The psbuild main script also has more documentation about how it can be started and configured.

The file `.gitignore` from this project is also a template for other Visual Studio projects and already includes rules for the PowerShell build framework. If you’re starting a new project with Visual Studio under Git version control, just copy this file to your solution directory.
