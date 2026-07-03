function Get-FileContent {

    param(
        [String]$Path,
        [Object]$Key   # optional: byte[] key, path to a New-PWEKey file, or New-PWEKey char[] output
    )

    if ($Path -match "^https://") {
        $raw = curl -k "$($Path)" -s | out-string
    } else {
        $raw = get-content "$($Path)" -raw
    }

    if ($Key) {
        $keyBytes = ConvertTo-PWEAesKeyBytes -Key $Key
        $raw = Unprotect-PWEText -EncryptedText $raw.Trim() -KeyBytes $keyBytes
    }

    return $raw

}

function Set-FileContent {

    param(
        [String]$Content,
        [String]$Path,
        [Object]$Key   # optional: byte[] key, path to a New-PWEKey file, or New-PWEKey char[] output
    )

    if ($Key) {
        $keyBytes = ConvertTo-PWEAesKeyBytes -Key $Key
        $Content = Protect-PWEText -Text $Content -KeyBytes $keyBytes
    }

    $Content | out-file "$Path" -encoding default -Force

}