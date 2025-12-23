Get-ChildItem -Path $PSScriptRoot\Functions -File | ForEach-Object -Process { . $PSItem.FullName }
Get-ChildItem -Path $PSScriptRoot\Variables -File | ForEach-Object -Process { . $PSItem.FullName }

Export-ModuleMember -Function * -Variable *