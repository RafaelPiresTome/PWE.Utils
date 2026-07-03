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



###################################
### Protection helpers
###################################

function ConvertTo-PWEAesKeyBytes {
    <#
        Normalizes the various forms a PWE AES key can come in into raw key bytes:
          - [byte[]]                -> used as-is
          - [string] path to a file -> read via Get-Content (as produced by New-PWEKey -FilePath)
          - char[] / string         -> the direct in-memory output of New-PWEKey (no -FilePath)
    #>
    param(
        [Parameter(Mandatory)]
        [Object]$Key
    )

    if ($Key -is [byte[]]) {
        return $Key
    }

    if ($Key -is [string] -and (Test-Path -LiteralPath $Key -ErrorAction SilentlyContinue)) {
        $chars = Get-Content -Path $Key
    } else {
        $chars = $Key
    }

    $joined = -join $chars
    return [System.Text.Encoding]::Unicode.GetBytes($joined)
}

function Protect-PWEText {
    param(
        [Parameter(Mandatory)][String]$Text,
        [Parameter(Mandatory)][byte[]]$KeyBytes
    )

    $aes = [System.Security.Cryptography.Aes]::Create()
    try {
        $aes.Key = $KeyBytes
        $aes.GenerateIV()

        $encryptor  = $aes.CreateEncryptor()
        $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)

        $combined = $aes.IV + $cipherBytes
        return [Convert]::ToBase64String($combined)
    }
    finally {
        $aes.Dispose()
    }
}

function Unprotect-PWEText {
    param(
        [Parameter(Mandatory)][String]$EncryptedText,
        [Parameter(Mandatory)][byte[]]$KeyBytes
    )

    $combined = [Convert]::FromBase64String($EncryptedText)

    $aes = [System.Security.Cryptography.Aes]::Create()
    try {
        $aes.Key = $KeyBytes
        $ivLength = $aes.IV.Length   # 16 bytes for AES

        $iv          = $combined[0..($ivLength - 1)]
        $cipherBytes = $combined[$ivLength..($combined.Length - 1)]

        $aes.IV = $iv
        $decryptor  = $aes.CreateDecryptor()
        $plainBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)

        return [System.Text.Encoding]::UTF8.GetString($plainBytes)
    }
    finally {
        $aes.Dispose()
    }
}
