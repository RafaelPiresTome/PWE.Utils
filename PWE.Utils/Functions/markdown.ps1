<#
.SYNOPSIS
    Convert markdown file to html files.

.DESCRIPTION
    Function to convert markdown files into html files

.PARAMETER Path
    Full path to markdown file.

.PARAMETER FilePath
    Full path to output html file.

.PARAMETER Show
    Switch parameter to show output html file with default web browser .

.EXAMPLE
    Convert-MarkdownToHtmlFile -Path "C:\Users\rafae\Downloads\VSBuildTools\README.md" -show

.EXAMPLE
    Convert-MarkdownToHtmlFile -Path "C:\Users\rafae\Downloads\VSBuildTools\README.md" -FilePath "c:\temp\VSBuildTools.html" 

.EXAMPLE
    Convert-MarkdownToHtmlFile -Path "C:\Users\rafae\Downloads\VSBuildTools\README.md" -FilePath "c:\temp\VSBuildTools.html" -show
#>
Function Convert-MarkdownToHtmlFile {
    param(
    [ValidateScript({Test-Path $_})]
    [string]$Path,
    [string]$FilePath,
    [switch]$Show,
    [Switch]$Links
    )
    $md_file = get-item "$Path"
    if($null -eq $FilePath){
        $FilePath = "$Path/out.html"
    }
    (ConvertFrom-Markdown -Path "$Path").html | out-file -FilePath "$FilePath" -Encoding default -Force
    
    if($Links){
        $html = get-content -Path "$FilePath"
        $c = $html.replace(".md",".md.html")
        $c | out-file -FilePath "$FilePath" -encoding default -Force
    }
    if($show){
        & "$FilePath"
    }
}

Function Convert-MarkdownDirectoryToHtml {
	param(
	[String]$Path = $pwd.path,
	[Switch]$Links)
	
	$files = get-childitem -Path "$Path" -Recurse | where {$_.Name -match ".md$"} | select Name,FullName
	
	foreach($f in $files){
		if($Links){
			Convert-MarkdownToHtmlFile -Path "$($f.FullName)" -FilePath "$($f.FullName).html" -Links
		}else{
			Convert-MarkdownToHtmlFile -Path "$($f.FullName)" -FilePath "$($f.FullName).html"
		}
	}
}

<#
.SYNOPSIS
    Convert markdown within module into html file.

.DESCRIPTION
    Function to convert a README.md file within a module into an html file and show it.

.PARAMETER Name
    Name of the module

.PARAMETER Show
    Show the module markdown file into the default web browser

.EXAMPLE
    New-ModuleMarkdown -Name VSBuildTools
#>

Function New-ModuleMarkdown {
    param(
    [ValidateScript({get-module $_})]
    [string]$Name,
    [bool]$show
    )
    $ModuleFullPath = (get-module "$Name").Path
    $PSM1 = get-item "$ModuleFullPath"
    $Path = "$($PSM1.Directory.FullName)"
    $md = "$($Path)/README.md"
    if($show){
        Convert-MarkdownToHtmlFile -Path "$md" -FilePath "$($md).html" -Show
    }else{
        Convert-MarkdownToHtmlFile -Path "$md" -FilePath "$($md).html"
    }
}
