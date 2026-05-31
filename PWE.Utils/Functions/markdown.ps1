<#
.SYNOPSIS
    Convert markdown file to html files.

.DESCRIPTION
    Function to convert markdown files into html files using github style

.PARAMETER Path
    Full path to markdown file.

.PARAMETER FilePath
    Full path to output html file.

.PARAMETER Title
    Title of the html page

.PARAMETER Show
    Switch parameter to show output html file with default web browser.

.PARAMETER DarkMode
    Transform the html page into a full dark mode style.

.PARAMETER Links
    Transform ".md" links into ".md.html" links.

.EXAMPLE
    Convert-MarkdownToHtmlFile -Path "C:\Users\rafae\Downloads\VSBuildTools\README.md" -show

.EXAMPLE
    Convert-MarkdownToHtmlFile -Path "C:\Users\rafae\Downloads\VSBuildTools\README.md" -FilePath "c:\temp\VSBuildTools.html" 

.EXAMPLE
    Convert-MarkdownToHtmlFile -Path "C:\Users\rafae\Downloads\VSBuildTools\README.md" -FilePath "c:\temp\VSBuildTools.html" -DarkMode
	
.EXAMPLE
    Convert-MarkdownToHtmlFile -Path "C:\Users\rafae\Downloads\VSBuildTools\README.md" -FilePath "c:\temp\VSBuildTools.html" -Links
#>
Function Convert-MarkdownToHtmlFile {
	
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$FilePath,

        [string]$Title = "Markdown Document",

        [switch]$DarkMode,

        [switch]$Show,

        [switch]$Links
    )

    if (-not (Test-Path $Path)) {
        throw "Input file not found: $Path"
    }

    if (-not $FilePath) {

        $directory = Split-Path $Path
        $name      = [IO.Path]::GetFileNameWithoutExtension($Path)

        $FilePath = Join-Path $directory "$name.html"
    }

    $markdown = Get-Content $Path -Raw

    $content = ($markdown | ConvertFrom-Markdown).Html

    $theme = if ($DarkMode) {
@"
body {
    background-color: #0d1117;
    color: #c9d1d9;
}

.markdown-body {
    background-color: #0d1117;
    color: #c9d1d9;
}

.markdown-body pre {
    background-color: #161b22;
}

.markdown-body code {
    #background-color: rgba(110,118,129,0.4);
    color: #c9d1d9;
}

.markdown-body table tr {
    background-color: #0d1117;
    border-top: 1px solid #30363d;
}

.markdown-body table tr:nth-child(2n) {
    background-color: #161b22;
}

.markdown-body blockquote {
    color: #8b949e;
    border-left: 0.25em solid #30363d;
}
"@
    }
    else {
@"
body {
    background-color: #ffffff;
    color: #24292f;
}

.markdown-body {
    background-color: #ffffff;
    color: #24292f;
}

.markdown-body pre {
    background-color: #f6f8fa;
}

.markdown-body code {
    #background-color: rgba(175,184,193,0.2);
}

.markdown-body blockquote {
    color: #57606a;
    border-left: 0.25em solid #d0d7de;
}
"@
    }

    $html = @"
<!DOCTYPE html>
<html lang="en">

<head>

<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">

<title>$Title</title>

<style>

body {
    margin: 0;
    padding: 2rem;
    font-family:
        -apple-system,
        BlinkMacSystemFont,
        "Segoe UI",
        Helvetica,
        Arial,
        sans-serif;
}

.markdown-body {
    box-sizing: border-box;
    max-width: 980px;
    margin: 0 auto;
    line-height: 1.7;
}

.markdown-body h1,
.markdown-body h2 {
    border-bottom: 1px solid #d8dee4;
    padding-bottom: .3em;
}

.markdown-body pre {
    padding: 16px;
    overflow: auto;
    border-radius: 6px;
}

.markdown-body code {
    padding: .2em .4em;
    border-radius: 6px;
    font-size: 85%;
}

.markdown-body table {
    border-collapse: collapse;
    width: 100%;
}

.markdown-body table th,
.markdown-body table td {
    border: 1px solid #d0d7de;
    padding: 6px 13px;
}

.markdown-body img {
    max-width: 100%;
}

.markdown-body blockquote {
    margin: 0;
    padding: 0 1em;
}

$theme

</style>

</head>

<body>

<article class="markdown-body">
$content
</article>

</body>
</html>
"@

    $html | Set-Content $FilePath -Encoding utf8

    Get-Item $FilePath
	
	if($Links){
        $html = get-content -Path "$FilePath"
        $c = $html.replace(".md",".md.html")
        $c | out-file -FilePath "$FilePath" -encoding default -Force
    }
    if($show){
        & "$FilePath"
    }
}

<#
.SYNOPSIS
    Convert all markdown files from a directory into html with github style.

.DESCRIPTION
    Convert all markdown files from a directory into html with github style.

.PARAMETER Path
    Path of the directory. Default value : $pwd.path

.PARAMETER DarkMode
    Transform html pages into a full dark mode style.

.PARAMETER Links
    Transform ".md" links into ".md.html" links.

.EXAMPLE
    Convert-MarkdownDirectoryToHtml
	
.EXAMPLE
    Convert-MarkdownDirectoryToHtml -Path "D:\PWE\doc"

.EXAMPLE
    Convert-MarkdownDirectoryToHtml -Path "D:\PWE\doc" -DarkMode
	
.EXAMPLE
    Convert-MarkdownDirectoryToHtml -Path "D:\PWE\doc" -Links

#>

Function Convert-MarkdownDirectoryToHtml {
	param(
	[String]$Path = $pwd.path,
	[Switch]$Links,
	[Switch]$DarkMode
	)
	
	$files = get-childitem -Path "$Path" -Recurse | where {$_.Name -match ".md$"} | select Name,FullName
	
	foreach($f in $files){
		if($DarkMode){
			if($Links){
				Convert-MarkdownToHtmlFile -Path "$($f.FullName)" -FilePath "$($f.FullName).html" -Title "$($f.Name)" -Links -DarkMode
			}else{
				Convert-MarkdownToHtmlFile -Path "$($f.FullName)" -FilePath "$($f.FullName).html" -Title "$($f.Name)" -DarkMode
			}
		}else{
			if($Links){
				Convert-MarkdownToHtmlFile -Path "$($f.FullName)" -FilePath "$($f.FullName).html" -Title "$($f.Name)" -Links
			}else{
				Convert-MarkdownToHtmlFile -Path "$($f.FullName)" -FilePath "$($f.FullName).html" -Title "$($f.Name)"
			}
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

.PARAMETER DarkMode
    Transform the html page into a full dark mode style.

.PARAMETER Links
    Transform ".md" links into ".md.html" links.

.EXAMPLE
    New-ModuleMarkdown -Name "PWE.Utils"
	
.EXAMPLE
    New-ModuleMarkdown -Name "PWE.Utils" -Show

.EXAMPLE
    New-ModuleMarkdown -Name "PWE.Utils" -Links

.EXAMPLE
    New-ModuleMarkdown -Name "PWE.Utils" -DarkMode
#>

Function New-ModuleMarkdown {
    param(
    [ValidateScript({get-module $_})]
    [string]$Name,
    [Switch]$Show,
	[Switch]$Links,
	[Switch]$DarkMode
    )
    $ModuleFullPath = (get-module "$Name").Path
    $PSM1 = get-item "$ModuleFullPath"
    $Path = "$($PSM1.Directory.FullName)"
    $md = "$($Path)/README.md"
	
	$param = @{
		path = "$md" ;
		FilePath = "$($md).html";
		Show = $Show;
		Links = $Links;
		DarkMode = $DarkMode;
	}
	
	Convert-MarkdownToHtmlFile @param
}
