<#
.SYNOPSIS
    Cross-platform PowerShell Service Manager (functions only).
.DESCRIPTION
    Provides functions to manage services (Windows + Linux).
    Supports querying, starting, stopping, restarting, installing and removing services.
#>

#region Functions

<#
.SYNOPSIS
    Gets services cross-platform.
.DESCRIPTION
    Retrieves service information on both Windows and Linux.
    Supports wildcards and returns consistent PSObjects with StartType.
.EXAMPLE
    Get-PWEService spool*
.EXAMPLE
    Get-PWEService ssh
#>
function Get-PWEService {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name = '*'
    )

    process {
        if ($IsWindows) {
            # Optimize: get all WMI services once
            $allWmi = Get-CimInstance Win32_Service
            foreach ($pattern in $Name) {
                $services = Get-Service -Name $pattern -ErrorAction SilentlyContinue
                foreach ($svc in $services) {
                    $wmi = $allWmi | Where-Object Name -eq $svc.Name
                    $startType = if ($wmi) { $wmi.StartMode } else { "Unknown" }
                    [pscustomobject]@{
                        Name        = $svc.Name
                        DisplayName = $svc.DisplayName
                        Status      = $svc.Status
                        ServiceType = "WindowsService"
                        StartType   = $startType
                    }
                }
            }
        }
        elseif ($IsLinux) {
            # Optimize: get all services once
			$allUnits = & systemctl list-unit-files --no-pager --no-legend 2>$null |
                ForEach-Object { ($_ -split '\s+')[0]}

            foreach ($pattern in $Name) {
                $matches = $allUnits | Where-Object { $_ -like $pattern }
                foreach ($svc in $matches) {
					$unitProps = & systemctl show "$svc" --property=UnitFileState,ActiveState,SubState,Description 2>$null
                    if (-not $unitProps) { continue }

                    $props = @{}
                    foreach ($line in $unitProps -split "`n") {
                        if ($line -match "=") { $k,$v = $line -split "=",2; $props[$k]=$v }
                    }

                    $statusMap = @{ active="Running"; inactive="Stopped"; failed="Stopped" }
                    $startMap  = @{ enabled="Automatic"; disabled="Disabled"; static="Manual"; masked="Disabled" }

                    [pscustomobject]@{
                        Name        = $svc
                        DisplayName = $props.Description
                        Status      = $statusMap[$props.ActiveState] ?? $props.ActiveState
                        SubState    = $props.SubState
                        ServiceType = "LinuxSystemd"
                        StartType   = $startMap[$props.UnitFileState] ?? $props.UnitFileState
                    }
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Starts a service.
.DESCRIPTION
    Starts one or more services cross-platform using Get-PWEService.
.EXAMPLE
    Start-PWEService spooler -PassThru
.EXAMPLE
    Get-PWEService ssh* | Start-PWEService
#>
function Start-PWEService {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [switch]$PassThru
    )
    process {
        $services = Get-PWEService -Name $Name
        foreach ($svc in $services) {
            if ($PSCmdlet.ShouldProcess($svc.Name, "Start service")) {
                if ($IsWindows) { Start-Service -Name $svc.Name }
                elseif ($IsLinux) { sudo systemctl start $svc.Name }
                if ($PassThru) { Get-PWEService -Name $svc.Name }
            }
        }
    }
}

<#
.SYNOPSIS
    Stops a service.
.DESCRIPTION
    Stops one or more services cross-platform using Get-PWEService.
.EXAMPLE
    Stop-PWEService sshd -Force -PassThru
.EXAMPLE
    Get-PWEService spool* | Stop-PWEService
#>
function Stop-PWEService {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [switch]$Force,
        [switch]$PassThru
    )
    process {
        $services = Get-PWEService -Name $Name
        foreach ($svc in $services) {
            if ($PSCmdlet.ShouldProcess($svc.Name, "Stop service")) {
                if ($IsWindows) {
                    if ($Force) { Stop-Service -Name $svc.Name -Force }
                    else { Stop-Service -Name $svc.Name }
                }
                elseif ($IsLinux) {
                    if ($Force) { sudo systemctl stop $svc.Name --force }
                    else { sudo systemctl stop $svc.Name }
                }
                if ($PassThru) { Get-PWEService -Name $svc.Name }
            }
        }
    }
}

<#
.SYNOPSIS
    Restarts a service.
.DESCRIPTION
    Restarts one or more services cross-platform using Get-PWEService.
.EXAMPLE
    Restart-PWEService ssh -PassThru
#>
function Restart-PWEService {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [switch]$Force,
        [switch]$PassThru
    )
    process {
        $services = Get-PWEService -Name $Name
        foreach ($svc in $services) {
            if ($PSCmdlet.ShouldProcess($svc.Name, "Restart service")) {
                if ($IsWindows) {
                    if ($Force) { Restart-Service -Name $svc.Name -Force }
                    else { Restart-Service -Name $svc.Name }
                }
                elseif ($IsLinux) {
                    if ($Force) { sudo systemctl restart $svc.Name --force }
                    else { sudo systemctl restart $svc.Name }
                }
                if ($PassThru) { Get-PWEService -Name $svc.Name }
            }
        }
    }
}

#endregion
