class PWECredential {
	[String]$Name
	[String]$Username
	[SecureString]$Password
	[Hashtable]$Metadata
	hidden [String]$Authorized_Characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%^&*()_+-=[]{}|;:,.<>?"
	PWECredential([String]$Name,[String]$Username,[SecureString]$Password){
		$this.Name = $Name
		$this.Username = $Username
		$this.Password = $Password
	}
	PWECredential([String]$Name,[String]$Username){
		$this.Name = $Name
		$this.Username = $Username
	}
	PWECredential([String]$Name){
		$this.Name = $Name
		$this.Username = $env:USERNAME
	}
	PWECredential(){
		$this.Name = $env:USERNAME
		$this.Username = $env:USERNAME
	}
	[void]GeneratePassword([Int]$Length,[String]$Authorized_Characters){
		$pass = ""
		$characters = $Authorized_Characters
	
		for ($i = 0; $i -lt $Length; $i++) {
			$randomIndex = Get-Random -Minimum 0 -Maximum $characters.Length
			$pass += $characters[$randomIndex]
		}
	
		$this.Password = convertto-securestring $pass -asplaintext -force
	}
	[void]GeneratePassword([Int]$Length){
		$this.GeneratePassword($Length,$this.Authorized_Characters)
	}
	[void]GeneratePassword(){
		$this.GeneratePassword(16,$this.Authorized_Characters)
	}
	[PSCredential]ToPSCredential(){
		return new-object pscredential($this.Username,$this.password)
	}
	[System.Management.Automation.Runspaces.PSSession]ToPSSession($ComputerName){
		return New-PSSession -ComputerName $ComputerName -Credential $this.ToPSCredential()
	}
	[String]Show(){
		return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.Password))
	}
	[Void]Save([String]$FilePath){
		$pass = convertfrom-securestring $this.Password
		$h = @{Name="$($this.Name)";Username="$($this.Username)";Password="$($pass)";Metadata=$this.Metadata}
		if(!(test-path "$FilePath" )){
			New-item -Path "$FilePath" -ItemType File | out-null
		}
		$y = get-yaml -path $FilePath
		$y += @(h)
		set-yaml -yaml $y -path $FilePath
	}
	[Void]Save([String]$FilePath,[String]$KeyFilePath){
		$SecureKey = New-PWESecureKey -FilePath "$KeyFilePath"
		$pass = convertfrom-securestring $this.Password -SecureKey $SecureKey	
		$h = @{Name="$($this.Name)";Username="$($this.Username)";Password="$($pass)";Metadata=$this.Metadata}
		if(!(test-path "$FilePath" )){
			New-item -Path "$FilePath" -ItemType File | out-null
		}
		$y = get-yaml -path $FilePath
		$y += @(h)
		set-yaml -yaml $y -path $FilePath
	}
}

class PWECredentialVault{
	[PWECredential[]]$PWECredential
	PWECredentialVault(){
		$this.PWECredential = @()
	}
	PWECredentialVault([String]$Path){
		$this.import("$Path")
	}
	PWECredentialVault([String]$Path,[String]$KeyFilePath){
		$this.import("$Path","$KeyFilePath")
	}
	[void]import([String]$Path){
		$y = get-yaml -path "$Path"
		foreach($elem in $y){
			$password = convertto-securestring $elem.password
			$TmpCred = new-object PWECredential($elem.name,$elem.username,$password)
			$TmpCred.Metadata = $elem.Metadata
			$this.PWECredential += @($TmpCred)
		}
	}
	[void]import([String]$Path,[String]$KeyFilePath){
		$c = get-content "$Path"
		$SecureKey = New-PWESecureKey -FilePath "$KeyFilePath"
		foreach($elem in $c){
			$password = convertto-securestring $elem.password -SecureKey $SecureKey
			$TmpCred = new-object PWECredential($elem.name,$elem.username,$password)
			$TmpCred.Metadata = $elem.Metadata
			$this.PWECredential += @($TmpCred)
		}
	}
	[void]generate([String]$Name,[String]$Username,[Int]$Length,[String]$Authorized_Characters){
		$PWECred = new-object PWECredential($Name,$Username)
		$PWECred.GeneratePassword([Int]$Length,[String]$Authorized_Characters)
		$this.PWECredential += @($PWECred)
	}
	[void]generate([String]$Name,[String]$Username,[Int]$Length){
		$PWECred = new-object PWECredential($Name,$Username)
		$PWECred.GeneratePassword([Int]$Length)
		$this.PWECredential += @($PWECred)
	}
	[void]generate([String]$Name,[String]$Username){
		$PWECred = new-object PWECredential($Name,$Username)
		$PWECred.GeneratePassword()
		$this.PWECredential += @($PWECred)
	}
	[void]generate(){
		$PWECred = new-object PWECredential
		$PWECred.GeneratePassword()
		$this.PWECredential += @($PWECred)
	}
	[Void]add([PWECredential]$PWECredential){
		$this.PWECredential += @($PWECredential)
	}
	[Void]remove([PWECredential]$PWECredential){
		$ArrayList = [System.Collections.ArrayList]$this.PWECredential
		$ArrayList.remove($PWECredential)
		$this.PWECredential = $ArrayList
	}
	[void]save([String]$FilePath){
		foreach($cred in $this.PWECredential){
			$cred.save("$FilePath")
		}
	}
	[void]save([String]$FilePath,[String]$KeyFilePath){
		foreach($cred in $this.PWECredential){
			$cred.save("$FilePath",$KeyFilePath)
		}
	}
}
