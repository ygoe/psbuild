# PowerShell build framework
# Copyright (c) 2015, Yves Goergen, http://unclassified.software/source/psbuild
#
# Copying and distribution of this file, with or without modification, are permitted provided the
# copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

# The ssh module provides SSH transfer functions.

# Copies a file to a remote SFTP server.
#
# $src = The path of the source file.
# $dest = The path of the destination file.
# $password = The password to log in to the remote server.
#
# Files can be uploaded or downloaded with this function.
#
# The format for remote paths is "user@host:/path/".
#
# The remote path and password should be passed from variables that are defined in a file that is
# excluded from the source code repository. This file can be sourced into the definition script
# to make the variables available. Example:
#
#    . "$sourcePath\.local\ssh_config.ps1"
#    Sftp-Copy "My.exe" "$sshDest" "$sshPassword" 15
#
# Requires PSCP from PuTTY to be in the search path.
#
function Sftp-Copy($src, $dest, $password, $time)
{
	$action = @{ action = "Do-Sftp-File"; src = $src; dest = $dest; password = $password; time = $time }
	$global:actions += $action
}

# ==============================  FUNCTION IMPLEMENTATIONS  ==============================

function Do-Sftp-File($action)
{
	$src = $action.src
	$dest = $action.dest
	$password = $action.password
	
	Write-Host ""
	Write-Host -ForegroundColor DarkCyan "Copying $src to $dest..."

	Push-Location "$sourcePath"
	& pscp -sftp -batch -pw "$password" "$src" "$dest"
	if (-not $?)
	{
		Pop-Location
		WaitError "Copy failed"
		exit 1
	}
	Pop-Location
}
