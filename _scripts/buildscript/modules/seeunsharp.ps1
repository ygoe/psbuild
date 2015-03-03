# PowerShell build framework
# Copyright (c) 2015, Yves Goergen, http://unclassified.software/source/psbuild
#
# Copying and distribution of this file, with or without modification, are permitted provided the
# copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

# The seeunsharp module provides SeeUnsharp code obfuscation functions.

# Obfuscates assembly files with SeeUnsharp.
#
# $configFile = The file name of the obfuscator configuration file.
#
function Run-Obfuscate($configFile, $time = 5)
{
	$action = @{ action = "Do-Run-Obfuscate"; configFile = $configFile; time = $time }
	$global:actions += $action
}

# ==============================  FUNCTION IMPLEMENTATIONS  ==============================

function Do-Run-Obfuscate($action)
{
	$configFile = $action.configFile
	
	Write-Host ""
	Write-Host -ForegroundColor DarkCyan "Obfuscating $configFile..."

	# Find the Obfuscator binary
	# TODO

	# Rename new map file with current build version
	# TODO
	if ($mapFile.EndsWith(".xml"))
	{
		#Move-Item -Force "$mapFile" $mapFile.Replace(".xml", ".$revId.xml")
	}
}
