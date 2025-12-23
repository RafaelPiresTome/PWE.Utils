function Set-Env {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value,

        [ValidateSet("User", "Machine")]
        [string]$Scope = "User",

        [switch]$Append
    )

    $sep = Get-EnvSeparator

    if ($IsWindows) {
        $target = if ($Scope -eq "User") { "User" } else { "Machine" }
        $current = [System.Environment]::GetEnvironmentVariable($Name, $target)

        if ($Append -and $current) {
            $parts = $current.Split($sep)
            if ($parts -notcontains $Value) {
                $newValue = ($current.TrimEnd($sep) + $sep + $Value).Trim($sep)
            }
            else { $newValue = $current }
        }
        else {
            $newValue = $Value
        }

        [System.Environment]::SetEnvironmentVariable($Name, $newValue, $target)
		if(get-Item "env:\$($Name)" -ErrorAction SilentlyContinue){
			Set-Item "env:\$($Name)" -value $newValue
		}else{
			New-Item "env:\$($Name)" -value $newValue
		}
        Write-Output "Environment variable '$Name' defined in scope $Scope with value $newValue"
    }
    else {
        if ($Scope -eq "User") {
            $bashrc = "$HOME/.bashrc"

            $existing = $null
            if (Test-Path $bashrc) {
                $line = Get-Content $bashrc | Where-Object { $_ -match "^export $Name=" }
                if ($line -match "^export $Name=(.*)") {
                    $existing = $matches[1].Trim('"')
                }
            }

            if ($Append -and $existing) {
                $parts = $existing -split $sep
                if ($parts -notcontains $Value) {
                    $newValue = ($existing + $sep + $Value).Trim($sep)
                }
                else { $newValue = $existing }
            }
            else {
                $newValue = $Value
            }

            $line = "export $Name=`"$newValue`""
            if (-not (Select-String -Path $bashrc -Pattern "export $Name=" -Quiet)) {
                Add-Content $bashrc $line
            }
            else {
                (Get-Content $bashrc) -replace "export $Name=.*", $line | Set-Content $bashrc
            }

            if(get-Item "env:\$($Name)" -ErrorAction SilentlyContinue){
				Set-Item "env:\$($Name)" -value $newValue
			}else{
				New-Item "env:\$($Name)" -value $newValue
			}
            Write-Output "Environment variable '$Name' defined in $Scope within $bashrc."
        }
        elseif ($Scope -eq "Machine") {
            $profileFile = "/etc/profile.d/pwe_env.sh"
            if (-not (Test-Path $profileFile)) {
                sudo touch $profileFile
                sudo chmod 644 $profileFile
            }

            $existing = $null
            if (Test-Path $profileFile) {
                $line = Get-Content $profileFile | Where-Object { $_ -match "^export $Name=" }
                if ($line -match "^export $Name=(.*)") {
                    $existing = $matches[1].Trim('"')
                }
            }

            if ($Append -and $existing) {
                $parts = $existing -split $sep
                if ($parts -notcontains $Value) {
                    $newValue = ($existing + $sep + $Value).Trim($sep)
                }
                else { $newValue = $existing }
            }else {
                $newValue = $Value
            }

            $line = "export $Name=`"$newValue`""
            if (-not (Select-String -Path $profileFile -Pattern "export $Name=" -Quiet)) {
                sudo sh -c "echo '$line' >> $profileFile"
            }
            else {
                (Get-Content $profileFile) -replace "export $Name=.*", $line | sudo tee $profileFile > $null
            }

            if(get-Item "env:\$($Name)" -ErrorAction SilentlyContinue){
				Set-Item "env:\$($Name)" -value $newValue
			}else{
				New-Item "env:\$($Name)" -value $newValue
			}
            Write-Output "Environment variable '$Name' defined in $Scope within $profileFile add activated within the current session"
        }
    }
}


function Remove-Env {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [ValidateSet("User", "Machine")]
        [string]$Scope = "User",

        [string]$Value
    )

    $sep = Get-EnvSeparator

    if ($IsWindows) {
        $target = if ($Scope -eq "User") { "User" } else { "Machine" }

        if ($Value) {
            $current = [System.Environment]::GetEnvironmentVariable($Name, $target)
            if ($current) {
                $newValue = ($current.Split($sep) | Where-Object { $_ -ne $Value }) -join $sep
                [System.Environment]::SetEnvironmentVariable($Name, $newValue, $target)
                Set-Item "env:\$($Name)" -value $newValue
                Write-Output "Value '$Value' removed from environment variable '$Name' from scope $Scope."
            }
        }
        else {
            [System.Environment]::SetEnvironmentVariable($Name, $null, $target)
            Remove-Item env:$Name -ErrorAction SilentlyContinue
            Write-Output "Environment variable '$Name' removed from scope $Scope."
        }
    }
    else {
        if ($Scope -eq "User") {
            $bashrc = "$HOME/.bashrc"
            if ($Value) {
                (Get-Content $bashrc) |
                    ForEach-Object {
                        if ($_ -match "^export $Name=") {
                            $val = ($_ -replace "export $Name=", "").Trim('"')
                            $newVal = ($val.Split($sep) | Where-Object { $_ -ne $Value }) -join $sep
                            "export $Name=`"$newVal`""
                        }
                        else { $_ }
                    } | Set-Content $bashrc
				Set-Item "env:\$($Name)" -value (((get-item "env:$($Name)").Value -split $sep) | Where-Object { $_ -ne $Value } -join $sep)
                Write-Output "Value '$Value' removed from environment variable '$Name' from scope User."
            }
            else {
                (Get-Content $bashrc) | where {$_ -notmatch "export $Name="} | Set-Content $bashrc
                Remove-Item env:$Name -ErrorAction SilentlyContinue
                Write-Output "Environment variable '$Name' removed from scope User."
            }
        }
        elseif ($Scope -eq "Machine") {
            $profileFile = "/etc/profile.d/pwe_env.sh"
            if (-not (Test-Path $profileFile)) {
                Write-Warning "File $profileFile doesn't exist, no environment variable to remove."
                return
            }

            if ($Value) {
                $line = Get-Content $profileFile | Where-Object { $_ -match "^export $Name=" }
                if ($line -match "^export $Name=(.*)") {
                    $current = $matches[1].Trim('"')
                    $newVal = ($current.Split($sep) | Where-Object { $_ -ne $Value }) -join $sep
                    $newline = "export $Name=`"$newVal`""
                    (Get-Content $profileFile) -replace "export $Name=.*", $newline | sudo tee $profileFile > $null
                    New-Item "env:\$($Name)" -value $newValue
                }
                Write-Output "Value '$Value' removed from environment variable '$Name' from scope Machine."
            }
            else {
                (Get-Content $profileFile) | where {$_ -notmatch "export $Name="} | sudo tee $profileFile > $null
                Remove-Item env:$Name -ErrorAction SilentlyContinue
                Write-Output "Environment variable '$Name' removed from scope Machine."
            }
        }
    }
}


function Get-EnvByScope {
    [CmdletBinding()]
    param(
        [string]$Name,

	[ValidateSet("Process", "User", "Machine")]
        [string]$Scope = "Process",

        [switch]$Expand
    )

    if ($IsWindows) {
        $target = switch ($Scope) {
            "Process" { "Process" }
            "User"    { "User" }
            "Machine" { "Machine" }
        }
        $vars = [System.Environment]::GetEnvironmentVariables($target)
    }
    else {
        switch ($Scope) {
            "Process" {
                $vars = Get-ChildItem Env: | ForEach-Object {
                    @{ Name = $_.Key; Value = $_.Value }
                }
            }
            "User" {
                $bashrc = "$HOME/.bashrc"
                $vars = if (Test-Path $bashrc) {
                    Get-Content $bashrc |
                        Where-Object { $_ -match '^export\s+\w+=' } |
                        ForEach-Object {
                            if ($_ -match '^export\s+([^=]+)=(.*)') {
                                @{ Name = $matches[1]; Value = $matches[2].Trim('"') }
                            }
                        }
                }
            }
            "Machine" {
                $profileFile = "/etc/profile.d/pwe_env.sh"
                $vars = if (Test-Path $profileFile) {
                    Get-Content $profileFile |
                        Where-Object { $_ -match '^export\s+\w+=' } |
                        ForEach-Object {
                            if ($_ -match '^export\s+([^=]+)=(.*)') {
                                @{ Name = $matches[1]; Value = $matches[2].Trim('"') }
                            }
                        }
                }
            }
        }
    }

    if ($Name) {
        $vars = $vars.GetEnumerator() | Where-Object { $_.Key -eq $Name -or $_.Name -eq $Name }
    }
	
	$sep = Get-EnvSeparator
	
    foreach ($v in $vars) {
        $val = if ($Expand) {
            $v.Value.split("$sep")
        } else {
            $v.Value
        }
        [PSCustomObject]@{ Name = $v.Key ?? $v.Name; Value = $val }
    }
}

Function Get-Env {
    [CmdletBinding()]
    param(
        [string]$Name,
	
	[ValidateSet("Process", "User", "Machine")]
        [string]$Scope = "Process",

        [switch]$Expand
    )
	if($Expand){
		if(Get-EnvByScope -Name $Name -scope Machine -ErrorAction SilentlyContinue){
			$envObj = Get-EnvByScope -Name $Name -scope Machine -Expand
			$envResult = [PSCustomObject]@{
				Name=$envObj.Name
				Value=$envObj.Value
				Scope="Machine"
			}
		}
		elseif(Get-EnvByScope -Name $Name -scope User -ErrorAction SilentlyContinue){
			$envObj = Get-EnvByScope -Name $Name -scope User -Expand
			$envResult = [PSCustomObject]@{
				Name=$envObj.Name
				Value=$envObj.Value
				Scope="User"
			}
		}
		elseif(Get-EnvByScope -Name $Name -scope Process -ErrorAction SilentlyContinue){
			$envObj = Get-EnvByScope -Name $Name -scope Process -Expand
			$envResult = [PSCustomObject]@{
				Name=$envObj.Name
				Value=$envObj.Value
				Scope="Process"
			}
		}
	}
	else{
		if(Get-EnvByScope -Name $Name -scope Machine -ErrorAction SilentlyContinue){
			$envObj = Get-EnvByScope -Name $Name -scope Machine
			$envResult = [PSCustomObject]@{
				Name=$envObj.Name
				Value=$envObj.Value
				Scope="Machine"
			}
		}
		elseif(Get-EnvByScope -Name $Name -scope User -ErrorAction SilentlyContinue){
			$envObj = Get-EnvByScope -Name $Name -scope User
			$envResult = [PSCustomObject]@{
				Name=$envObj.Name
				Value=$envObj.Value
				Scope="User"
			}
		}
		elseif(Get-EnvByScope -Name $Name -scope Process -ErrorAction SilentlyContinue){
			$envObj = Get-EnvByScope -Name $Name -scope Process
			$envResult = [PSCustomObject]@{
				Name=$envObj.Name
				Value=$envObj.Value
				Scope="Process"
			}
		}
	}
	return $envResult
	
}
