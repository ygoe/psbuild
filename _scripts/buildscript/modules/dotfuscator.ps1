# PowerShell build framework
# Copyright (c) 2015, Yves Goergen, http://unclassified.software/source/psbuild
#
# Copying and distribution of this file, with or without modification, are permitted provided the
# copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

# The dotfuscator module provides Dotfuscator code obfuscation functions.

# Obfuscates assembly files with Dotfuscator.
#
# $configFile = The file name of the obfuscator configuration file.
#
# Requires Dotfuscator CE 5.0.2601 from Visual Studio 2010 with the CLI upgrade to be installed.
#
function Run-Dotfuscate($configFile, $time = 30)
{
	$action = @{ action = "Do-Run-Dotfuscate"; configFile = $configFile; time = $time }
	$global:actions += $action
}

# ==============================  FUNCTION IMPLEMENTATIONS  ==============================

function Do-Run-Dotfuscate($action)
{
	$configFile = $action.configFile
	
	Show-ActionHeader "Dotfuscating $configFile"

	# Find the Dotfuscator CLI binary
	if ((Get-Platform) -eq "x64")
	{
		$dotfuscatorBin = Check-FileName "%ProgramFiles(x86)%\Microsoft Visual Studio 10.0\PreEmptive Solutions\Dotfuscator Community Edition\dotfuscatorCLI.exe"
	}
	if ((Get-Platform) -eq "x86")
	{
		$dotfuscatorBin = Check-FileName "%ProgramFiles%\Microsoft Visual Studio 10.0\PreEmptive Solutions\Dotfuscator Community Edition\dotfuscatorCLI.exe"
	}
	if ($dotfuscatorBin -eq $null)
	{
		WaitError "Dotfuscator binary not found"
		exit 1
	}

	# Read Dotfuscator configuration
	$config = [xml](Get-Content (MakeRootedPath($configFile)))
	$mapDir = $config.SelectSingleNode("/dotfuscator/renaming/mapping/mapoutput/file/@dir").'#text'
	$mapFile = $mapDir + "\" + $config.SelectSingleNode("/dotfuscator/renaming/mapping/mapoutput/file/@name").'#text'
	$mapFile = $mapFile.Replace("`${configdir}", $rootDir)
	if ($mapFile.EndsWith(".xml"))
	{
		# Find and delete previous map file
		$prevMapFile = $mapFile.Replace(".xml", ".0.xml")
		if (Test-Path "$prevMapFile")
		{
			Remove-Item "$prevMapFile"
		}
	}
	
	# TODO: Add English texts
	& $dotfuscatorBin /q "$rootDir\$configFile" | where {
		$_ -notmatch "^Dotfuscator Community Edition Version " -and `
		$_ -notmatch "^Copyright .* PreEmptive Solutions, " -and `
		$_ -notmatch "^Mit dem Verwenden dieser Software stimmen Sie dem " -and `
		$_ -notmatch "^LIZENZIERT FÜR: " -and `
		$_ -notmatch "^SERIENNUMMER: " -and `
		$_ -notmatch "^\[Intelligente Verbergung\] "
	}
	if (-not $?)
	{
		WaitError "Dotfuscation failed"
		exit 1
	}

	# Rename new map file with current build version
	if ($mapFile.EndsWith(".xml"))
	{
		Move-Item -Force "$mapFile" $mapFile.Replace(".xml", ".$revId.xml")
	}
}
