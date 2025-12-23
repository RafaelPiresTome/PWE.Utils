# Prerequisites
--- 
## Modules 

The Following modules are prerequisites to using PWE.Core module (if they were suppressed from the "mod" directory) : 
* powershell-yaml 
* pode
* pode.web

## env.yaml

Before installing PWE, you have to configure $env:PWEInstallPath/conf/env.yaml file. 

Here are the different keys of env.yaml file : 

* Role [Server, Client] : Current role of PWE. "Server" will install and configure a PWE WebServer. "Client" will only configure the essential parameters for PWE.
* ssh [true, false] : if true, it will install ssh for PWE when running PWE's installation script and uninstall it when running PWE's uninstallation script.
* choco [true, false]: if true, it will install the embeded chocolatey for PWE when running PWE's installation script and uninstall it when running PWE's uninstallation script.
* url [http://..., https://...] : url for PWE WebServer. If the role is "Client", you can specify that url so that the PWE Client can retrieve a PWE WebServer for packages, medias, ... .
* BinPath [$env:PWEInstallPath/bin] : Full path to PWE's "bin" directory. This value can be set outside $env:PWEInstallPath directory.
* RepoPath [$env:PWEInstallPath/rpo] : Full path to PWE's "repo" directory. This value can be set outside $env:PWEInstallPath directory and as a shared directory.
* TmpPath [$env:PWEInstallPath/tmp] : Full path to PWE's "tmp" directory. This value can be set outside $env:PWEInstallPath directory.
* ModPath [$env:PWEInstallPath/mod] : Full path to PWE's "mod" directory. This value can be set outside $env:PWEInstallPath directory.
* PWEInstallPath [$env:PWEInstallPath] : Full path to PWE's install directory. This value will be automatically calculated.
* DocPath [$env:PWEInstallPath/doc] : Full path to PWE's "doc" directory. This value can be set outside $env:PWEInstallPath directory.
* AppPath [$env:PWEInstallPath/app] : Full path to PWE's "app" directory. This value can be set outside $env:PWEInstallPath directory.
* pwshPath [$PSHOME] : Full path to Powershell Core's installation directory. It can be changed if Powershell Core is not installed on it's default directory.
* CmdPath [$env:PWEInstallPath/cmd] : Full path to PWE's "cmd" directory. This value can be set outside $env:PWEInstallPath directory.
* StorePath [$env:PWEInstallPath/store] : Full path to PWE's "store" directory. This value can be set outside $env:PWEInstallPath directory and as a shared directory.
* ProjPath [$env:PWEInstallPath/proj] : Full path to PWE's "proj" directory. This value can be set outside $env:PWEInstallPath directory.
* ConfPath [$env:PWEInstallPath/conf] : Full path to PWE's "conf" directory. This directory should remain inside $env:PWEInstallPath directory.

# Setup
---
## Install and uninstall

To install PWE, use the following command :
```
$env:PWEInstallPath/cmd/Install-PWE.ps1
```

It will:
* Set PWEInstallPath environment variable
* Set the env.yaml environment file 
* Set PWE main profile file into powershell-core's global profile
* Install embeded Chocolatey if the OS is a Windows one (can be skipped if choco value in the "conf/env.yaml" is "false")
* Install module PWE.PackageManager
* Install OpenSSH (can be skipped if ssh value in the "conf/env.yaml" is "false")
* Install projects having cmd/install.ps1 file within their directory. Otherwize it will be skipped

To uninstall, replace 'Install' by 'Uninstall'.

For PWE modules configuration, please check $($pwe.env.modpath)/$ModuleName/readme.md file.

## Tunning

If you work offline, you will have some performances issues due to a certificate check that is unreacheable.

To bypass it, please go to $env:PWEInstallPath/cmd and run : ./Set-PWETunning.ps1

## Add reverse proxy to PWEServer

Here is an example of vhost with Apache HTTPD to add https to a PWEServer: 
```
### Virtual Host for PWEServer
Listen 9020

###SSL Session
SSLSessionCache "shmcb:${SRVROOT}/logs/ssl_scache(512000)"
SSLSessionCacheTimeout 300
SSLCryptoDevice builtin
KeepAlive On
KeepAliveTimeout 6
MaxKeepAliveRequests 400

###Cache configuration
CacheRoot "D:\Apache24\cacheroot"
CacheEnable disk "/"
CacheDirLevels 5
CacheDirLength 2

###Apache user access lock
EnableMMAP off
EnableSendFile on
AcceptFilter http none
AcceptFilter https none

<VirtualHost *:9020>

### Server name and alias	(To Adapt)
	ServerName pwes.dps-fr.com
	ServerAlias pwes.dps-fr.com
	
### ALL Log files	(To Adapt)
	ErrorLog logs/PWES_error_log
	TransferLog logs/PWES_access_log
	CustomLog	logs/PWES_ssl_request_log.txt "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
	
### Log level Configuration
	LogLevel warn
	SSLEngine on
	SSLProxyEngine On

### SSL certificate and server private key	(To Adapt)
	SSLCertificateFile D:/Apache24/conf/ssl/ca3dxserver.crt
	SSLCertificateKeyFile D:/Apache24/conf/ssl/ca3dxserver.key
	
	ProxyPreserveHost On
	ProxyRequests Off
	ServerName www.example.com
	ServerAlias example.com
	ProxyPass / http://localhost:9050/
	ProxyPassReverse / http://localhost:9050/
	
</VirtualHost>
```

# Use
--- 
## pwe alias
The alias is architectured as follow :
```
pwe [section] [command] [PSObject]
```
Command can be runned in two ways, like this : 
```
pwe [section] [command] [PSObject]
```
Or like this : 
```
[PSObject] | pwe [section] [command] 
```

## All pwe commands

```
pwe main 	install
pwe main 	uninstall
pwe main 	profile
pwe main 	clear
	 	
pwe key		get
pwe key		activate
pwe key		deactivate
pwe key		convert 	@{Password=[String]$Password}
	 	
pwe server 	install
pwe server 	uninstall
pwe server 	start
pwe server 	stop
pwe server 	restart
pwe server 	status
	
pwe choco 	install
pwe choco 	uninstall
    
pwe service	install 	@{Name=[String]$ServiceName; Path=[String]$PathToPSFile}
pwe service	uninstall 	@{Name=[String]$ServiceName}
pwe service	start 		@{Name=[String]$ServiceName}
pwe service	stop 		@{Name=[String]$ServiceName}
pwe service	restart 	@{Name=[String]$ServiceName}
pwe service	status 		@{Name=[String]$ServiceName}
		
pwe project	install 	@{Name=[String]$ProjectName}
pwe project	uninstall 	@{Name=[String]$ProjectName}
pwe project	test 		@{Name=[String]$ProjectName}
pwe project	upgrade 	@{Name=[String]$ProjectName}
pwe project	list
pwe project	upload 		@{Name=[String]$ProjectName}
pwe project	remove 		@{Name=[String]$ProjectName}
pwe project	start 		@{Name=[String]$ProjectName}
pwe project	stop 		@{Name=[String]$ProjectName}
pwe project	restart 	@{Name=[String]$ProjectName}
pwe project	status 		@{Name=[String]$ProjectName}
	 	
pwe ssh 	install 
pwe ssh		uninstall
pwe ssh		register 	@{HostName=[String]$SSHHostName; Password=[string]$Password}
pwe ssh		registered
pwe ssh		unregister 	@{HostName=[String]$SSHHostName}
pwe ssh		add 		@{HostName=[String]$SSHHostName; Size=[Int]$NumberOfSessions}
pwe ssh		remove 		@{SID=[String]$SessionID}
pwe ssh		connect 	@{SID=[String]$SessionID}
pwe ssh		command 	@{SID=[String]$SessionID; ScriptBlock=[ScriptBlock]$ScriptBlock}
pwe ssh		call 		@{HostName=[String]$SSHHostName; ScriptBlock=[ScriptBlock]$ScriptBlock}
pwe ssh		copy 		@{HostName=[String]$SSHHostName; Path=[String]$Path; Destination=[String]$DestinationPath}
	 			
pwe sshg	add 		@{Name=[String]$GroupName; Hosts=[String[]]$ArrayOfHostnames}
pwe sshg	remove 		@{Name=[String]$GroupName}
pwe sshg	list
pwe sshg	call 		@{Name=[String]$GroupName; ScriptBlock=[ScriptBlock]$ScriptBlock}

pwe job 	start 		@{SID=[String]$SessionID; JID=[String]$JobID; ScriptBlock=[ScriptBlock]$ScriptBlock}
pwe job		LoadBalance @{HostName=[String]$SSHHostName; JID=[String]$JobID; ScriptBlock=[ScriptBlock]$ScriptBlock}
pwe job		get 		@{JID=[String]$JobID}
pwe job		stop 		@{JID=[String]$JobID}
pwe job		remove 		@{JID=[String]$JobID}

pwe dag 	upload 		@{Path=[String]$DagYamlPath}
pwe dag		import 		@{Name=[String]$DagName}		/!\ run dag upload first
pwe dag		init 		@{Name=[String]$DagName}		/!\ run dag import first
pwe dag		add 		@{Name=[String]$DagName; HostName=[String]$SSHHostName}
pwe dag		start 		@{Name=[String]$DagName}
pwe dag		stop 		@{Name=[String]$DagName}
pwe dag		status 		@{Name=[String]$DagName}
pwe dag		restart 	@{Name=[String]$DagName}
pwe dag		retry 		@{Name=[String]$DagName; JID=[String]$JobID; Kind=[String]$NullOrRecurse}
pwe dag		save 		@{Name=[String]$DagName}
pwe dag		remove 		@{Name=[String]$DagName}
pwe dag		import 		@{Name=[String]$DagName}
pwe dag		list
pwe dag		last 		@{Name=[String]$DagName}

pwe module 	upload 		@{Name=[String]$ModuleName}
pwe module	remove 		@{Name=[String]$ModuleName}
pwe module	help 		@{Name=[String]$ModuleName; options=[String]$NullOrNoShow}

pwe history	add  		@{Command=[String]$Command; Data=[PSObject]$InputObject}
pwe module	get
pwe module	clear

```


