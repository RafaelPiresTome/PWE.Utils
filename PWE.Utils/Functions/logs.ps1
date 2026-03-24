Function Set-PWELogPath {
	param(
	[ValidateScript({Test-Path $_})]
	[Parameter(Mandatory, Position=0, ValueFromPipeline=$true)]
	[String]$Path
	)
	
	$global:PWE_LOG_PATH = (Resolve-Path -path "$Path").Path
}

Function Write-PWELog {
	param(
	[Parameter(Mandatory, Position=0)]
	[String]$Name,
	[Parameter(Mandatory, Position=1)]
	[ValidateSet('DEBUG','INFO','WARN','ERROR','TRACE','FATAL')]
	[String]$Level,
	[Parameter(Position=2, ValueFromPipeline=$true)]
	[String[]]$String,
	[Switch]$PSHost
	)
	
	$date = get-date -format "yyyy-MM-dd|HH:mm:ss"
	
	$msg = "[$date][$level][$String]"
	
	if($PSHost){
		switch($Level){
			'DEBUG' {Write-Host "$msg" -ForegroundColor DarkCyan}
			'INFO' {Write-Host "$msg" -ForegroundColor Green}
			'WARN' {Write-Host "$msg" -ForegroundColor Yellow}
			'ERROR' {Write-Host "$msg" -ForegroundColor Red}
			'TRACE' {Write-Host "$msg" -ForegroundColor Gray}
			'FATAL' {Write-Host "$msg" -ForegroundColor DarkRed}
		}
	}
	
	$msg | out-file "$($global:PWE_LOG_PATH)/$($Name).log" -encoding default -append
	
}

Function Out-PWELog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [String]$Name,

        [Parameter(Mandatory, Position=1)]
        [ValidateSet('DEBUG','INFO','WARN','ERROR','TRACE','FATAL')]
        [String]$Level,

        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$InputObject,

        [Switch]$PSHost
    )

    process {
        if ($null -ne $InputObject) {

            # Convert properly to string (handles objects, tables, etc.)
            $lines = $InputObject | Out-String -Stream

            foreach ($line in $lines) {
                if (-not [string]::IsNullOrWhiteSpace($line)) {

                    if ($PSHost) {
                        Write-PWELog -Name $Name -Level $Level -String $line -PSHost
                    }
                    else {
                        Write-PWELog -Name $Name -Level $Level -String $line
                    }

                }
            }
        }
    }
}

Function Get-PWELog {
	param(
	[Parameter(Mandatory, Position=0)]
	[String]$Name
	)
	if(!(test-path "$($global:PWE_LOG_PATH)/$($Name).log")){
		return Write-host "Log file $Name doesn't exist ..."
	}
	return get-content "$($global:PWE_LOG_PATH)/$($Name).log"
}

Function Clear-PWELog {
	param(
	[Parameter(Mandatory, Position=0)]
	[String]$Name
	)
	if(!(test-path "$($global:PWE_LOG_PATH)/$($Name).log")){
		Write-output "Log file $Name doesn't exist ..."
	}else{
		Remove-Item "$($global:PWE_LOG_PATH)/$($Name).log" -Force
		Write-output "Log file $Name deleted successfully !"
	}
}

Function Get-PWELogList {
	return (get-childitem "$($global:PWE_LOG_PATH)" -File | where {$_.Name -notmatch ".zip$"}).Name.replace(".log","")
}

Function Invoke-PWELogSave {
	$date = get-date -format "yyyy-MM-dd"
	$compress = @{
		Path= "$($global:PWE_LOG_PATH)/*.log"
		CompressionLevel = "Fastest"
		DestinationPath = "$($global:PWE_LOG_PATH)/pwe.logs.$($date).zip"
	}
	Compress-Archive @compress
}