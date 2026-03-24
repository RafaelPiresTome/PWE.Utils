function Start-WebDavClient {
	$res = Get-service WebClient
	if($res.Status -eq "stopped"){start-service WebClient}
	return Get-Service WebClient
}

function Get-WebDavChildItem {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline=$True)]
        [string[]] $Path,
		[Parameter(Position = 1)]
        [string]   $Filter,
        [string[]] $Include,
        [string[]] $Exclude,
        [switch]   $Recurse,
        [uint]     $Depth,
        [switch]   $Force,
        [string]   $Name
    )

    # Initial path cleanup (TAB completion junk)
    $Path = $Path -replace '\^@', '' -replace "`0", ''

    $gciArgs = @{
        Force = $Force
    }

    if ($Filter)  { $gciArgs.Filter  = $Filter }
    if ($Include) { $gciArgs.Include = $Include }
    if ($Exclude) { $gciArgs.Exclude = $Exclude }
    if ($Name)    { $gciArgs.Name    = $true }

    if (-not $Recurse) {
        return Get-ChildItem @gciArgs -LiteralPath $Path
    }

    if (-not $Depth) { $Depth = [uint]::MaxValue }

    function Invoke-WebDavRecurse {
        param(
            [string] $CurrentPath,
            [uint]   $CurrentDepth
        )

        if ($CurrentDepth -le 0) { return }

        $items = Get-ChildItem @gciArgs -LiteralPath $CurrentPath -ErrorAction SilentlyContinue

        foreach ($item in $items) {

            # Skip WebDAV pseudo-directories
            if ($item.Name -eq '.' -or $item.Name -eq '..') {
                continue
            }

            $item

            if ($item.PSIsContainer) {

                # Build child path manually (DON’T trust FullName)
                $childPath = Join-Path $CurrentPath $item.Name

                # Sanitize WebDAV garbage
                $childPath = $childPath -replace '\^@', '' -replace "`0", ''

                Invoke-WebDavRecurse `
                    -CurrentPath $childPath `
                    -CurrentDepth ($CurrentDepth - 1)
            }
        }
    }

    Invoke-WebDavRecurse -CurrentPath $Path -CurrentDepth $Depth
}

New-Alias -name lswd -value "Get-WebDavChildItem"

Function Clear-WebDavPath {
	[CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline=$True)]
		[string[]] $Path
    )
	if($Path.count -eq 1){
		$Path -replace '\^@','' -replace "`0",''
	}else{
		$list = @()
		foreach($elem in $Path){
			$list += @($elem -replace '\^@','' -replace "`0",'')
		}
		$list
	}
}

New-Alias -name clswd -value "Clear-WebDavPath"

Function Find-WebDavItem{
	[CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]   $Name,
		[Parameter(Position = 1, ValueFromPipeline=$True)]
		[string[]] $Path
    )
	
	lswd "$Path" -Recurse | where {$_.FullName -match "$Name"}
	
}

New-Alias -name flswd -value "Find-WebDavItem"

Function Invoke-WebDavFileScript{
	[CmdletBinding()]
    param(
		[Parameter(Position = 0, ValueFromPipeline=$True)]
		[string[]] $Path
    )
	$MyPath = $Path | clswd
	powershell -f $MyPath
}

New-Alias -name ifswd -value "Invoke-WebDavFileScript"

Function Get-WebDavContent{
	[CmdletBinding()]
    param(
		[Parameter(Position = 0, ValueFromPipeline=$True)]
		[string[]] $Path,
		[Switch]$Raw
    )
	$MyPath = $Path | clswd
	if($Raw){
		get-content "$MyPath" -Raw
	}else{
		get-content "$MyPath"
	}
}

New-Alias -name catwd -value "Get-WebDavContent"

Function Select-WebDavString{
	[CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]   $Pattern,
		[Parameter(Position = 1, ValueFromPipeline=$True)]
		[string[]] $Path
    )
	$MyPath = $Path | clswd
	select-string -Pattern $Pattern -Path 
}

New-Alias -name strwd -value "Select-WebDavString"