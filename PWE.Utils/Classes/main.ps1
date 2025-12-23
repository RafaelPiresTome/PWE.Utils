foreach($psscript in (get-childitem "$PSScriptRoot" -File).fullname){
	if(($psscript -match ".ps1") -and !($psscript -match "main.ps1")){ . $psscript }
}