Function Get-Hostname{
	if($IsWindows){$env:COMPUTERNAME}
	if($IsLinux){$env:HOSTNAME}
}

function Get-Platform {
    if ($IsWindows) { return "Windows" }
    elseif ($IsLinux) { return "Linux" }
    else { throw "Unsupported platform" }
}

function Get-EnvSeparator {
    if ($IsWindows) { return ';' }
    else { return ':' }
}