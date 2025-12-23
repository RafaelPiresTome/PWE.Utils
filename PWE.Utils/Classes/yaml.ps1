class Yaml {
    [object]$Data
    [string]$SourcePath

    Yaml([string]$input) {
        if (Test-Path $input) {
            # YAML file
            $this.SourcePath = (Resolve-Path $input).Path
            $content = Get-Content -Path $this.SourcePath -Raw
        } else {
            # YAML string
            $content = $input
        }
        $this.Data = ConvertFrom-Yaml -Yaml $content
    }

    [string] ToString() {
        return (ConvertTo-Yaml -Data $this.Data)
    }

    [void] Save([string]$Path) {
        $yaml = $this.ToString()
        Set-Content -Path $Path -Value $yaml -Encoding UTF8
        $this.SourcePath = (Resolve-Path $Path).Path
    }
}
