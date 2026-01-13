Function Get-AuthorizedCharactersSample {
	return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%^&*()_+-=[]{}|;:,.<>?"
}

Function New-GeneratedPassword {
	param([String]$Characters,[Int]$Length=12)
	$pass = ""
	for ($i = 0; $i -lt $Length; $i++) {
		$randomIndex = Get-Random -Minimum 0 -Maximum $characters.Length
		$pass += $characters[$randomIndex]
	}
	
	return @{password=$pass}
}