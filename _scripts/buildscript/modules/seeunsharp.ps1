# PowerShell build framework
# Copyright (c) 2015, Yves Goergen, http://unclassified.software/source/psbuild
#
# Copying and distribution of this file, with or without modification, are permitted provided the
# copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

# The seeunsharp module provides SeeUnsharp code obfuscation functions.

# Obfuscates assembly files with SeeUnsharp .NET Obfuscator.
#
# $configFile = The file name of the SeeUnsharp parameter file.
#
# Requires SeeUnsharp to be installed.
#
function Run-SeeUnsharp($configFile, $time = 5)
{
	$action = @{ action = "Do-Run-SeeUnsharp"; configFile = $configFile; time = $time }
	$global:actions += $action
}

# ==============================  FUNCTION IMPLEMENTATIONS  ==============================

function Do-Run-SeeUnsharp($action)
{
	$configFile = $action.configFile
	
	Show-ActionHeader "Obfuscating with $configFile"

	# Find the SeeUnsharp binary
	$suBin = Check-RegFilename "hkcu:\Software\Unclassified\SeeUnsharp" "ExecutablePath"
	if ($suBin -eq $null)
	{
		$suBin = Check-RegFilename "hklm:\Software\Unclassified\SeeUnsharp" "ExecutablePath"
	}
	if ($suBin -eq $null)
	{
		WaitError "SeeUnsharp binary not found"
		exit 1
	}

	& $suBin "@$rootDir\$configFile"
	if (-not $?)
	{
		WaitError "Obfuscation failed"
		exit 1
	}
}
