# PWE.Utils
This module is made of utilities for Powershell Wide Environment (PWE) project.

It contains functions to manage multi-platform features working on Linux (Redhat - CentOS) and Windows. Powershell 7.x is the only supported platform.


# Platform function
Here are usefull platform functions : 
``` powershell
# To get hostname
Get-Hostname
# To get if it's windows or Linux
Get-Platform
# To get separator
Get-EnvSeparator
```

# Environment Variables
Here are an example of the functions to manage environment variables :
``` powershell
# Create environment variable
Set-Env -Name "TEST_ENV" -Value "This is a test env" -scope "Machine"
Set-Env -Name "PATH" -Value "/my/new/path" -scope "User" -Append
# Get environment variable object
Get-Env -Name "TEST_ENV" -scope "Machine"
# Remove environment variable object
Get-Env -Name "TEST_ENV" -scope "Machine"
```

# Yaml
Here are some usefull functions for yaml parsing based on "powershell-yaml" module :
``` powershell
# To get yaml file
$h = Get-yaml -Path "/path/to/file.yaml"
$h = Get-yaml -Path "https://server.domain/path/to/file.yaml"
# To set yaml file
Set-yaml -yaml $h -path "/path/to/file.yaml"
```

# Services
Here are some usefull functions to manage services :
``` powershell
# To get service
Get-PWEService -Name "ssh*"
# To stop service
Stop-PWEService -Name "ssh*"
# To restart service
Restart-PWEService -Name "ssh*"
# To start service
Start-PWEService -Name "ssh*"
```

# Firewall
Here are some usefull functions to manage firewall rules :
``` powershell
# To add firewall rule
New-FirewallRule -Name "Restrict_HTTP" -Port 80 -RemoteAddress 123.456.789.0/24
# To get firewall rule
Get-FirewallRule -Name "Restrict_HTTP
# To remove firewall rule
Remove-FirewallRule -Name "Restrict_HTTP
```

# Logs
Here are some usefull functions to manage logs :
``` powershell
# To set path for log files
Set-PWELogPath -Path /logs
# To write a log file
Write-PWELog -Name "File_Name" -Level DEBUG -String "This is a debug line" -PSHost
Write-PWELog -Name "File_Name" -Level INFO -String "This is an info line" -PSHost
Write-PWELog -Name "File_Name" -Level WARN -String "This is a warning line" -PSHost
Write-PWELog -Name "File_Name" -Level ERROR -String "This is an error line" -PSHost
Write-PWELog -Name "File_Name" -Level TRACE -String "This is a trace line" -PSHost
Write-PWELog -Name "File_Name" -Level FATAL -String "This is a fatal line" -PSHost
# To write a script or function output into a log file
. /pat/to/script | Out-PWELog -Name "File_Name" -Level INFO -PSHost
invoke-function | Out-PWELog -Name "File_Name" -Level INFO -PSHost
# To get a log file
Get-PWELog -Name "File_Name"
# To get the list of all log files within the setted path
Get-PWELogList
# To delete a log file
Clear--PWELog -Name "File_Name"
# To save logs with timestamp
Invoke-PWELogSave
```

# Hostmetrics
Here are some usefull functions to git hostmetrics :
``` powershell
# To get hostmetrics within the console (only with separate commands)
Invoke-HostMetrics -CPU
Invoke-HostMetrics -RAM
Invoke-HostMetrics -Disk
Invoke-HostMetrics -GPU
Invoke-HostMetrics -Network
# To get hostmetrics within a csv file
Invoke-HostMetrics -CPU -RAM -Disk -GPU -Network -CsvPath "/tmp/file.csv"
# To get hostmetrics continuously
Invoke-HostMetrics -CPU -RAM -Disk -GPU -Network -CsvPath "/tmp/file.csv" -Continuous -Interval 10
```

# Modifying file 
Here is a provided function to modify files : 
``` powershell
# To replace a Regex String
Invoke-PWEFiler -Path "C:\My\file.txt" -String "MyRegexToReplace" -Replace "NewValue"
# To replace the full line 
Invoke-PWEFiler -Path "C:\My\file.txt" -String "MyRegexToReplace" -Replace "NewValue" -Line
```
To massively replace a file : 
``` powershell
# To replace a Regex String
Invoke-PWEBulkFiler -Path "C:\My\file.txt" -PSObject @(
  @{ String="FirstRegexToReplace"; Replace="NewValue"},
  @{ String="SecondRegexToReplaceFullLine"; Replace="NewValue"; Line=$True}
)
```

# Hashtable Keys
Here are some usefull functions to manipulate Hashtable Keys : 
``` powershell
# To get hashtable keys : 
$h | Get-HashtableKey
$h | Get-HashtableKey -Recurse
$h | Get-HashtableKey -Recurse -Separator /
$h | Get-HashtableKey -Recurse -Separator / -AsObject
$h | Get-HashtableKey -Recurse -Separator / -AsObject -IncludeArrays
$h | Get-HashtableKey -Recurse -Separator / -AsObject -IncludeArrays -Filter *child22*
# To get hostmetrics within a csv file
$h | Test-HashtableKey -Key child1
$h | Test-HashtableKey -Key child1.child12 -Recurse
$h | Test-HashtableKey -Match child12 -Recurse
```

# Passwords
You can use the following function to generate random passwords : 
``` powershell
# To have a sample of authorized character to use :
$authorized =  Get-AuthorizedCharactersSample
# To Generate a new random password : 
New-GeneratedPassword
New-GeneratedPassword -Length 8
New-GeneratedPassword -AuthorizedCharacters $authorized
New-GeneratedPassword -AsSecureString
```

# Keys
To create new keys for password encryption :  
``` powershell
# To generate a new key :
$key = New-PWEKey
New-PWEKey -FilePath "/path/to/mykey.key"
# To generate a new secure key :
$SecureKey = New-PWESecureKey -Key $Key
$SecureKey = New-PWESecureKey -FilePath "/path/to/mykey.key"
```

# Markdowns
You can use the following function to generate random passwords : 
``` powershell
# To convert a simple file markdown into an HTML file
Convert-MarkdownToHtmlFile -Path "/path/to/file.md" # To create "/path/to/file.md.html" output file
Convert-MarkdownToHtmlFile -Path "/path/to/file.md" -FilePath "/another/path/to/name.html" # To create custom output file
Convert-MarkdownToHtmlFile -Path "/path/to/file.md" -Show # To show html file after generation into default browser
Convert-MarkdownToHtmlFile -Path "/path/to/file.md" -Links # To change links to other markdown files
# To generate html files from markdown files from an entire Directory : 
Convert-MarkdownDirectoryToHtml -Path "/directory/path"
Convert-MarkdownDirectoryToHtml -Path "/directory/path" -Links
# To convert main markdown file from a module :
New-ModuleMarkdown -Name "ModuleName"
New-ModuleMarkdown -Name "ModuleName" -Show $True
```
