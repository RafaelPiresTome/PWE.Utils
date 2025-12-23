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
# To get yaml file
$h = Get-yaml -Path "/path/to/file.yaml"
$h = Get-yaml -Path "https://server.domain/path/to/file.yaml"
# To set yaml file
Set-yaml -yaml $h -path "/path/to/file.yaml"
```
