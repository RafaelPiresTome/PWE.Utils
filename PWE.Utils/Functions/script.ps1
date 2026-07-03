function Invoke-PWEScript {

    param(
        [Parameter(Mandatory)]
        [String]$Path,          # URL (https://...) or local/UNC path to a .ps1 file

        [Object]$Key,           # optional: byte[] key, path to a New-PWEKey file, or New-PWEKey char[] output

        [Parameter(ValueFromRemainingArguments = $true)]
        [Object[]]$ArgumentList # optional: positional args forwarded to the script
    )

    $content = Get-FileContent -Path $Path -Key $Key

    if ([String]::IsNullOrWhiteSpace($content)) {
        Write-Error "Invoke-PWEScript : no content retrieved from '$Path'"
        return
    }

    if ($Path -match "^https://") {
        $uri = [System.Uri]$Path
        $PWEScriptName = [System.IO.Path]::GetFileName($uri.AbsolutePath)
        $PWEScriptRoot = $Path.Substring(0, $Path.Length - $PWEScriptName.Length).TrimEnd('/')
    } else {
	$mypath = (resolve-path $path).ProviderPath
        $PWEScriptName = Split-Path -Path $mypath -Leaf
        $PWEScriptRoot = Split-Path -Path $mypath -Parent
    }

    $sb = [scriptblock]::Create($content)

    & $sb @ArgumentList

}