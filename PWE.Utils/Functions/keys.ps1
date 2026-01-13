Function New-PWEKey {
	param([String]$FilePath)
	$aes = [System.Security.Cryptography.Aes]::Create()
	$Key = $aes.Key
	$res = [System.Text.Encoding]::Unicode.GetString($Key).ToCharArray()
	if($FilePath){
		$res | out-file -FilePath "$FilePath" -encoding default -Force
	}
	else{
		$res
	}
}

Function New-PWESecureKey{
	param([String]$FilePath,
	[String]$Key)
	if($FilePath -and (-not $Key)){
		$c = get-content "$FilePath"
	}
	elseif($Key -and (-not $FilePath)){
		$c = $key
	}else{
		Write-output "Error : you cannot use both -FilePath and -Key arguments ... "
		break
	}
	$secureKey = [securestring]::new()
	foreach($char in $c){
		$secureKey.AppendChar($char)
	}
	return $secureKey
}