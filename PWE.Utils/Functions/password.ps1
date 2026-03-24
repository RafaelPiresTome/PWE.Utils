Function Get-AuthorizedCharactersSample {
	return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%^&*()_+-=[]{}|;:,.<>?"
}

Function New-GeneratedPassword{
	param(
	[String]$AuthorizedCharacters,
	[Int]$Length = 12,
	[Switch]$AsSecureString
	)
	
	if(!($AuthorizedCharacters -and $AuthorizedCharacters -ne "")){
		$AuthorizedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%^&*()_+-=[]{}|;:,.<>?"
	}
	
		
	$pass = ""
	$characters = $AuthorizedCharacters
	
	for ($i = 0; $i -lt $Length; $i++) {
		$randomIndex = Get-Random -Minimum 0 -Maximum $characters.Length
		$pass += $characters[$randomIndex]
	}
	
	if($AsSecureString){
		return convertto-securestring $pass -asplaintext -force
	}else{
		return $pass
	}
}