Function Invoke-PWEFiler {
	param(
	[Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True)]
	[String]$Path,
	[Parameter(Position=1, Mandatory=$True)]
	[String]$String,
	[String]$Replace,
	[Switch]$Line
	)
	
	$content_raw = get-content $Path -raw
	
	$modified_content = $content_raw
	
	$res = get-content $Path | where { $_ -match "$String"}
	
	if($Replace){
		if($Line){
			$lines = @($res)
			foreach($elem in $lines){
				$modified_content = $modified_content.replace("$elem","$Replace")
			}
			
			$modified_content | out-file $Path -encoding default -force
		}else{
			$modified_content = $modified_content.replace("$String","$Replace")
			
			$modified_content | out-file $Path -encoding default -force
		}
	}else{
		$res
	}
}

New-Alias -Name "pwe.filer" -value "Invoke-PSFiler"

Function Invoke-PWEBulkFiler {
	param(
	[Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True)]
	[String]$Path,
	[Parameter(Position=1, Mandatory=$True)]
	[PSObject[]]$PSObject
	)
	$list = @($PSObject)
	foreach($elem in $list){
		$cmd = "Invoke-PWEFiler -path `"$Path`" -string `"$($elem.String)`""
		if($elem.Replace){
			$cmd += " -Replace `"$($elem.Replace)`""
		}
		if($elem.Line){
			$cmd += " -Line"
		}
		
		Invoke-Expression "$cmd"
	}
}

New-Alias -Name "pwe.filer.bulk" -value "Invoke-PWEBulkFiler"
