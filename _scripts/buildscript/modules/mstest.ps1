# PowerShell build framework
# Copyright (c) 2015, Yves Goergen, http://unclassified.software/source/psbuild
#
# Copying and distribution of this file, with or without modification, are permitted provided the
# copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

# The mstest module provides Microsoft MSTest unit testing functions.

# Runs a test with MSTest using a metadata file (VS 2010 style).
#
# $metadataFile = The file name of the test metadata file for MSTest.
# $runConfig = The test run configuration.
# $testList = The name of the test list to run.
# $resultFile = The name of the test result file to create.
#
# Requires MSTest from Visual Studio 2015, 2013, 2012 or 2010 to be installed.
#
function Run-MSTestMeta($metadataFile, $runConfig, $testList, $resultFile, $time = 5)
{
	$action = @{ action = "Do-Run-MSTestMeta"; metadataFile = $metadataFile; runConfig = $runConfig; testList = $testList; resultFile = $resultFile; time = $time }
	$global:actions += $action
}

# Runs all tests from an assembly with MSTest (VS 2013 style).
#
# $asmFile = The file name of the assembly that contains the test methods.
# $resultFile = The name of the test result file to create.
#
# Requires MSTest from Visual Studio 2015, 2013, 2012 or 2010 to be installed.
#
function Run-MSTestAsm($asmFile, $resultFile, $time = 5)
{
	$action = @{ action = "Do-Run-MSTestAsm"; asmFile = $asmFile; resultFile = $resultFile; time = $time }
	$global:actions += $action
}

# ==============================  FUNCTION IMPLEMENTATIONS  ==============================

function Do-Run-MSTestMeta($action)
{
	$metadataFile = $action.metadataFile
	$runConfig = $action.runConfig
	$testList = $action.testList
	$resultFile = $action.resultFile
	
	Write-Host ""
	Write-Host -ForegroundColor DarkCyan "Running test $metadataFile, $runConfig, $testList..."

	$md = (MakeRootedPath $metadataFile)
	$rc = (MakeRootedPath $runConfig)
	$rf = (MakeRootedPath $resultFile)

	# Create result directory if it doesn't exist (MSTest requires it)
	$resultDir = [System.IO.Path]::GetDirectoryName("$rf")
	[void][System.IO.Directory]::CreateDirectory($resultDir)
	
	$mstestBin = (Find-MSTest)
	& $mstestBin /nologo /testmetadata:"$md" /runconfig:"$rc" /testlist:"$testList" /resultsfile:"$rf"
	if (-not $?)
	{
		WaitError "Test failed"
		exit 1
	}
}

function Do-Run-MSTestAsm($action)
{
	$asmFile = $action.asmFile
	$resultFile = $action.resultFile
	
	Write-Host ""
	Write-Host -ForegroundColor DarkCyan "Running tests in $asmFile..."

	$af = (MakeRootedPath $asmFile)
	$rf = (MakeRootedPath $resultFile)

	# Create result directory if it doesn't exist (MSTest requires it)
	$resultDir = [System.IO.Path]::GetDirectoryName("$rf")
	[void][System.IO.Directory]::CreateDirectory($resultDir)
	
	# Delete result file if it exists (MSTest won't overwrite it)
	Remove-Item $rf -ErrorAction SilentlyContinue
	
	# MSBuild command line reference: https://msdn.microsoft.com/en-us/library/ms182489.aspx
	
	$mstestBin = (Find-MSTest)
	& $mstestBin /nologo /testcontainer:"$af" /resultsfile:"$rf" /detail:errormessage /detail:errorstacktrace /usestderr | Out-Null
	if (-not $?)
	{
		WaitError "Test failed"
		exit 1
	}
}

function Find-MSTest()
{
	# Normalise the ProgramFilesx86 directory for all system platforms (how stupid...)
	$pfx86 = "%ProgramFiles(x86)%"
	if ((Get-Platform) -eq "x86")
	{
		$pfx86 = "%ProgramFiles%"
	}
	
	# Find the MSTest binary
	$mstestBin = Check-FileName "$pfx86\Microsoft Visual Studio 14.0\Common7\IDE\MSTest.exe"
	if (!$mstestBin)
	{
		$mstestBin = Check-FileName "$pfx86\Microsoft Visual Studio 12.0\Common7\IDE\MSTest.exe"
	}
	if (!$mstestBin)
	{
		$mstestBin = Check-FileName "$pfx86\Microsoft Visual Studio 11.0\Common7\IDE\MSTest.exe"
	}
	if (!$mstestBin)
	{
		$mstestBin = Check-FileName "$pfx86\Microsoft Visual Studio 10.0\Common7\IDE\MSTest.exe"
	}
	if (!$mstestBin)
	{
		WaitError "MSTest binary not found"
		exit 1
	}
	return $mstestBin
}
