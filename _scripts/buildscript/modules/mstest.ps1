# PowerShell build framework
# Copyright (c) 2015, Yves Goergen, http://unclassified.software/source/psbuild
#
# Copying and distribution of this file, with or without modification, are permitted provided the
# copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

# The mstest module provides Microsoft MSTest unit testing functions.

# Runs a test with MSTest.
#
# $metadataFile = The file name of the test metadata file for MSTest.
# $runConfig = The test run configuration.
# $testList = The name of the test list to run.
# $resultFile = The name of the test result file to create.
#
# Requires MSTest from Visual Studio 2010 to be installed.
#
function Run-MSTest($metadataFile, $runConfig, $testList, $resultFile, $time)
{
	$action = @{ action = "Do-Run-MSTest"; metadataFile = $metadataFile; runConfig = $runConfig; testList = $testList; resultFile = $resultFile; time = $time }
	$global:actions += $action
}

# ==============================  FUNCTION IMPLEMENTATIONS  ==============================

function Do-Run-MSTest($action)
{
	$metadataFile = $action.metadataFile
	$runConfig = $action.runConfig
	$testList = $action.testList
	$resultFile = $action.resultFile
	
	Write-Host ""
	Write-Host -ForegroundColor DarkCyan "Running test $metadataFile, $runConfig, $testList..."

	# Find the MSTest binary
	if ((Get-Platform) -eq "x64")
	{
		$mstestBin = Check-FileName "%ProgramFiles(x86)%\Microsoft Visual Studio 10.0\Common7\IDE\MSTest.exe"
	}
	if ((Get-Platform) -eq "x86")
	{
		$mstestBin = Check-FileName "%ProgramFiles%\Microsoft Visual Studio 10.0\Common7\IDE\MSTest.exe"
	}
	if ($mstestBin -eq $null)
	{
		WaitError "MSTest binary not found"
		exit 1
	}

	$md = (MakeRootedPath $metadataFile)
	$rc = (MakeRootedPath $runConfig)
	$rf = (MakeRootedPath $resultFile)

	# Create result directory if it doesn't exist (MSTest requires it)
	$resultDir = [System.IO.Path]::GetDirectoryName("$rf")
	[void][System.IO.Directory]::CreateDirectory($resultDir)
	
	& $mstestBin /nologo /testmetadata:"$md" /runconfig:"$rc" /testlist:"$testList" /resultsfile:"$rf"
	if (-not $?)
	{
		WaitError "Test failed"
		exit 1
	}
}
