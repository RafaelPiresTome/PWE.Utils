function Get-HashtableKey {
    [CmdletBinding(DefaultParameterSetName="Like")]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [switch]$Recurse,

        [string]$Separator = ".",

        [switch]$AsObject,

        [int]$Depth = [int]::MaxValue,

        [switch]$IncludeArrays,

        [Parameter(ParameterSetName="Like")]
        [string]$Filter = "*",

        [Parameter(ParameterSetName="Match")]
        [string]$Match
    )

    process {

        $stack = New-Object System.Collections.Stack
        $stack.Push(@{
            Value  = $InputObject
            Prefix = ""
            Level  = 0
        })

        while ($stack.Count -gt 0) {

            $current = $stack.Pop()
            $obj     = $current.Value
            $prefix  = $current.Prefix
            $level   = $current.Level

            if ($level -gt $Depth) { continue }

            if ($obj -is [hashtable] -or $obj -is [pscustomobject]) {

                $properties = if ($obj -is [hashtable]) {
                    $obj.Keys
                } else {
                    $obj.PSObject.Properties.Name
                }

                foreach ($prop in $properties) {

                    $fullKey = if ($prefix) {
                        "$prefix$Separator$prop"
                    } else {
                        "$prop"
                    }

                    $value = if ($obj -is [hashtable]) { $obj[$prop] } else { $obj.$prop }

                    # 🔍 FILTERING (ici → performant)
                    $include = $true

                    switch ($PSCmdlet.ParameterSetName) {
                        "Like"  { $include = $fullKey -like $Filter }
                        "Match" { $include = $fullKey -match $Match }
                    }

                    if ($include) {
                        if ($AsObject) {
                            [pscustomobject]@{
                                Key   = $fullKey
                                Value = $value
                                Depth = $level
                            }
                        }
                        else {
                            $fullKey
                        }
                    }

                    if ($Recurse -and $value) {

                        if ($value -is [hashtable] -or $value -is [pscustomobject]) {
                            $stack.Push(@{
                                Value  = $value
                                Prefix = $fullKey
                                Level  = $level + 1
                            })
                        }
                        elseif ($IncludeArrays -and $value -is [array]) {

                            for ($i = 0; $i -lt $value.Count; $i++) {
                                $stack.Push(@{
                                    Value  = $value[$i]
                                    Prefix = "$fullKey$Separator$i"
                                    Level  = $level + 1
                                })
                            }
                        }
                    }
                }
            }
        }
    }
}


function Test-HashtableKey {
    [CmdletBinding(DefaultParameterSetName="Exact")]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(Mandatory, ParameterSetName="Exact")]
        [string]$Key,

        [Parameter(Mandatory, ParameterSetName="Like")]
        [string]$Like,

        [Parameter(Mandatory, ParameterSetName="Match")]
        [string]$Match,

        [switch]$Recurse,

        [string]$Separator = "."
    )

    process {

        if (-not $Recurse -and $PSCmdlet.ParameterSetName -eq "Exact") {

            if ($InputObject -is [hashtable]) {
                return $InputObject.ContainsKey($Key)
            }

            if ($InputObject -is [pscustomobject]) {
                return $InputObject.PSObject.Properties.Name -contains $Key
            }
        }

        foreach ($k in Get-HashtableKey -InputObject $InputObject -Recurse -Separator $Separator) {

            switch ($PSCmdlet.ParameterSetName) {

                "Exact" { if ($k -eq $Key) { return $true } }
                "Like"  { if ($k -like $Like) { return $true } }
                "Match" { if ($k -match $Match) { return $true } }
            }
        }

        return $false
    }
}
