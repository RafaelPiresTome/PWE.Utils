Function Get-HashtableKeys {
	param([Parameter(Mandatory=$True, ValueFromPipeline=$True)][Hashtable]$Hashtable)
	return $Hashtable.keys.split("`n")
}

Function Test-IsKeyInHashtable {
	param([Parameter(Mandatory=$True, ValueFromPipeline=$True)][Hashtable]$Hashtable,[Parameter(Mandatory=$True)][String]$Key )
	$h = Get-HashtableKeys -hashtable $Hashtable
	return $h.contains("$Key")
}