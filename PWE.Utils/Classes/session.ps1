class PWESession{
	[String]$Name
	[String]$ComputerName
	[String]$Mode
	[PWECredential]$PWECredential
	[System.Management.Automation.Runspaces.PSSession]$PSSession
	PWESession($Name,$ComputerName,$PWECredential,$Mode){
	
	}
}