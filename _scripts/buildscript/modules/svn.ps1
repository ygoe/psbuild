# PowerShell build framework
# Copyright (c) 2015, Yves Goergen, http://unclassified.software/source/psbuild
#
# Copying and distribution of this file, with or without modification, are permitted provided the
# copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

# The svn module provides Subversion source control functions.

# Commits the working directory modifications to the current branch.
#
# Requires TortoiseSVN to be installed.
#
function Svn-Commit($time = 5)
{
	$action = @{ action = "Do-Svn-Commit"; time = $time }
	$global:actions += $action
}

# Exports the current repository revision to an archive file.
#
# $archive = The file name of the archive to create.
#
# Requires TortoiseSVN CLI and 7-Zip to be installed.
#
function Svn-Export($archive, $time = 5)
{
	$action = @{ action = "Do-Svn-Export"; archive = $archive; time = $time }
	$global:actions += $action
}

# Collects the recent commit messages and adds them to a log file, with the current time and
# revision ID in the header. This file will be opened in an editor to let the user edit it. The
# purpose of this file is to give it to the end users as a change log or release notes summary.
#
# $logFile = The file name of the log file to update and open.
#
# Requires TortoiseSVN CLI to be installed.
#
function Svn-Log($logFile, $time = 1)
{
	$action = @{ action = "Do-Svn-Log"; logFile = $logFile; time = $time }
	$global:actions += $action
}

# ==============================  FUNCTION IMPLEMENTATIONS  ==============================

function Do-Svn-Commit($action)
{
	Show-ActionHeader "Subversion commit and update"

	# Find the TortoiseProc binary
	$tsvnBin = Check-RegFilename "hklm:\SOFTWARE\TortoiseSVN" "ProcPath"
	if ($tsvnBin -eq $null)
	{
		WaitError "TortoiseProc binary not found"
		exit 1
	}
	
	# Wait until the started process has finished
	& $tsvnBin /command:commit /path:"$rootDir" | Out-Host
	if (-not $?)
	{
		WaitError "Subversion commit failed"
		exit 1
	}

	# Also do an update to ensure that all files are at the same revision. This is required to get
	# a consistent revision number for a public release build. (This is not necessary for Git.)
	& $tsvnBin /command:update /path:"$rootDir" | Out-Host
	if (-not $?)
	{
		WaitError "Subversion update failed"
		exit 1
	}
}

function Do-Svn-Export($action)
{
	$archive = $action.archive
	
	Show-ActionHeader "Subversion export to $archive"

	# Warn on modified working directory
	# (Set a dummy format so that it won't go search an AssemblyInfo file somewhere. We don't provide a suitable path for that.)
	$consoleEncoding = [System.Console]::OutputEncoding
	[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
	$revId = Invoke-Expression ((Join-Path $absToolsPath "NetRevisionTool") + " /format dummy /rejectmod `"$rootDir`"")
	if ($LASTEXITCODE -ne 0)
	{
		[System.Console]::OutputEncoding = $consoleEncoding
		Write-Host -ForegroundColor Yellow "Warning: The local working copy is modified! Uncommitted changes are exported."
	}
	[System.Console]::OutputEncoding = $consoleEncoding

	# Find the SVN binary
	$svnBin = Check-RegFilename "hklm:\SOFTWARE\TortoiseSVN" "Directory"
	$svnBin = Check-Filename "$svnBin\bin\svn.exe"
	if ($svnBin -eq $null)
	{
		WaitError "Tortoise SVN CLI binary not found"
		exit 1
	}

	# Find the 7-Zip binary
	$sevenZipBin = Check-RegFilename "hklm:\SOFTWARE\7-Zip" "Path"
	$sevenZipBin = Check-Filename "$sevenZipBin\7z.exe"
	if ($sevenZipBin -eq $null)
	{
		WaitError "7-Zip binary not found"
		exit 1
	}

	# Delete previous export if it exists
	if (Test-Path "$rootDir\.tmp.export")
	{
		Remove-Item "$rootDir\.tmp.export" -Recurse -ErrorAction Stop
	}

	& $svnBin export -q "$rootDir" "$rootDir\.tmp.export"
	if (-not $?)
	{
		WaitError "Subversion export failed"
		exit 1
	}

	# Delete previous archive if it exists
	if (Test-Path (MakeRootedPath $archive))
	{
		Remove-Item (MakeRootedPath $archive) -ErrorAction Stop
	}

	Push-Location "$rootDir\.tmp.export"
	& $sevenZipBin a (MakeRootedPath $archive) -mx=9 * | where {
		$_ -notmatch "^7-Zip " -and `
		$_ -notmatch "^Scanning$" -and `
		$_ -notmatch "^Creating archive " -and `
		$_ -notmatch "^\s*$" -and `
		$_ -notmatch "^Compressing "
	}
	if (-not $?)
	{
		Pop-Location
		WaitError "Creating SVN export archive failed"
		exit 1
	}
	Pop-Location

	# Clean up
	Remove-Item "$rootDir\.tmp.export" -Recurse
}

function Do-Svn-Log($action)
{
	$logFile = $action.logFile
	
	Show-ActionHeader "Subversion log dump"
	
	if ($PSVersionTable.PSVersion.Major -lt 3)
	{
		WaitError "PowerShell 3 or newer required for SVN log"
		exit 1
	}
	
	# Stop on modified working directory
	# (Set a dummy format so that it won't go search an AssemblyInfo file somewhere. We don't provide a suitable path for that.)
	$consoleEncoding = [System.Console]::OutputEncoding
	[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
	$revId = Invoke-Expression ((Join-Path $absToolsPath "NetRevisionTool") + " /format dummy /rejectmod `"$rootDir`"")
	if ($LASTEXITCODE -ne 0)
	{
		[System.Console]::OutputEncoding = $consoleEncoding
		WaitError "The local working copy is modified"
		exit 1
	}
	[System.Console]::OutputEncoding = $consoleEncoding

	# Find the SVN binary
	$svnBin = Check-RegFilename "hklm:\SOFTWARE\TortoiseSVN" "Directory"
	$svnBin = Check-Filename "$svnBin\bin\svn.exe"
	if ($svnBin -eq $null)
	{
		WaitError "Tortoise SVN CLI binary not found"
		exit 1
	}
	
	# Read the output log file and determine the last added revision
	$data = ""
	$startRev = 1;
	if (Test-Path (MakeRootedPath $logFile))
	{
		$data = [System.IO.File]::ReadAllText((MakeRootedPath $logFile))
		if ($data -Match " - .+ \(r([0-9]+)\)")
		{
			$startRev = [int]([regex]::Match($data, " - .+ \(r([0-9]+)\)")).Groups[1].Value + 1
		}
	}

	if ($lastRev)
	{
		Write-Host "Adding log messages since revision $startRev"
	}
	else
	{
		Write-Host "Adding all log messages since the first revision (new log file)"
	}
	
	# Get log messages for the new revisions
	$consoleEncoding = [System.Console]::OutputEncoding
	[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
	Push-Location "$rootDir"
	$xmlText = (& $svnBin log --xml -r ${startRev}:HEAD 2>&1)
	if (-not $?)
	{
		Pop-Location
		[System.Console]::OutputEncoding = $consoleEncoding
		WaitError "Subversion log failed"
		exit 1
	}
	Pop-Location
	[System.Console]::OutputEncoding = $consoleEncoding
	if (([string]$xmlText).Contains(": No such revision $startRev"))
	{
		Write-Host "No new messages"
		return
	}
	# DEBUG: Write-Host -ForegroundColor Yellow $xmlText
	$xml = [xml]$xmlText

	# Extract non-empty lines from all returned messages
	$msgs = $xml.log.logentry.msg -split "`n" | Foreach { $_.Trim() } | Where { $_ }

	# Format current date and revision and new messages
	$date = $xml.SelectSingleNode("(/log/logentry)[last()]/date").InnerText
	$currentRev = $xml.SelectSingleNode("(/log/logentry)[last()]/@revision").Value
	$caption = $date.Substring(0, 10) + " - " + $shortRevId + " (r" + $currentRev + ")"
	$newMsgs = $caption + "`r`n" + `
		("—" * $caption.Length) + "`r`n" + `
		[string]::Join("`r`n", $msgs).Replace("`r`r", "`r") + "`r`n`r`n"

	# Write back the complete file
	$data = ($newMsgs + $data).Trim() + "`r`n"
	[System.IO.File]::WriteAllText((MakeRootedPath $logFile), $data, [System.Text.Encoding]::UTF8)

	# Open file in editor for manual edits of the raw changes
	Start-Process (MakeRootedPath $logFile)
}
