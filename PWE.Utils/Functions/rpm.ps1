
function Get-RpmPackage {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Version,
        
        # Type usually maps to architecture (x86_64, noarch, etc.)
        [string]$Type
    )

    $rpmFormat = '%{NAME}|%{VERSION}|%{RELEASE}|%{ARCH}\n'

    $packages = rpm -qa --qf $rpmFormat 2>$null | ForEach-Object {
        $parts = $_ -split '\|'

        [PSCustomObject]@{
            Name    = $parts[0]
            Version = $parts[1]
            Release = $parts[2]
            Type    = $parts[3]
        }
    }

    if ($Name) {
        $packages = $packages | Where-Object {
            $_.Name -like "*$Name*"
        }
    }

    if ($Version) {
        $packages = $packages | Where-Object {
            $_.Version -like "*$Version*"
        }
    }

    if ($Type) {
        $packages = $packages | Where-Object {
            $_.Type -like "*$Type*"
        }
    }

    return $packages
}


function Test-RpmInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    rpm -q $Name *> $null

    return ($LASTEXITCODE -eq 0)
}


function Install-Rpm {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        # Use upgrade mode (-Uvh) instead of install (-ivh)
        [switch]$Upgrade
    )

    if (-not (Test-Path $Path)) {
        throw "RPM file not found: $Path"
    }

    $command = if ($Upgrade) {
        "rpm -Uvh `"$Path`""
    }
    else {
        "rpm -ivh `"$Path`""
    }

    if ($PSCmdlet.ShouldProcess($Path, "Install RPM")) {
        Invoke-Expression $command

        if ($LASTEXITCODE -ne 0) {
            throw "RPM installation failed."
        }
    }
}


function Remove-Rpm {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Test-RpmInstalled -Name $Name)) {
        throw "Package '$Name' is not installed."
    }

    if ($PSCmdlet.ShouldProcess($Name, "Remove RPM")) {
        rpm -e $Name

        if ($LASTEXITCODE -ne 0) {
            throw "RPM removal failed."
        }
    }
}
