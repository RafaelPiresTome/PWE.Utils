function Get-Yaml{
    param([String]$Path)
	if($Path -match "^https://"){
		$h = convertfrom-yaml (curl -k "$($Path)" -s | out-string)
	}else{
		$c = get-content "$($Path)" -raw
		$h = convertfrom-yaml $c
	}
    return $h
}

function Set-Yaml{
    param([PSObject]$Yaml,
	[String]$Path)
    
	convertto-yaml $Yaml | out-file "$Path" -encoding default -Force
	
}