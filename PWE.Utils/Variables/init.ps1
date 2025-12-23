foreach( $elem in (get-childitem $PSScriptRoot -directory).FullName){ 
	foreach($psscript in (get-childitem "$elem" -File).FullName){
		if($psscript -match ".ps1"){ . $psscript }
	}
} 