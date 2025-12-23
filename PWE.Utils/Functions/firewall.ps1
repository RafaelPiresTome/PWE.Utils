
function New-FirewallRule {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [ValidateSet("Inbound","Outbound")] [string]$Direction = "Inbound",
        [ValidateSet("Allow","Block")] [string]$Action = "Allow",
        [ValidateSet("TCP","UDP")] [string]$Protocol = "TCP",
        [int]$Port,
        [string]$Program,
        [string]$RemoteAddress,
        [string]$LocalAddress,
        [string]$Zone = "public",
        [ValidateSet("ipv4","ipv6")] [string]$Family = "ipv4"
    )

    switch (Get-Platform) {
        "Windows" {
            $params = @{
                DisplayName = $Name
                Direction   = $Direction
                Action      = $Action
                Profile     = $Zone
            }

            if ($Protocol) { $params.Protocol = $Protocol }
            if ($Port)              { $params.LocalPort = $Port }
            if ($Program)           { $params.Program = $Program }
            if ($RemoteAddress)     { $params.RemoteAddress = $RemoteAddress }
            if ($LocalAddress)      { $params.LocalAddress = $LocalAddress }

            New-NetFirewallRule @params | out-null
        }
        "Linux" {
			$table = "filter"
			$chain = if ($Direction -eq "Inbound") { "INPUT" } else { "OUTPUT" }
		
			$cmd = @(
				"firewall-cmd", "--permanent", "--direct",
				"--add-rule", $Family, $table, $chain, "0"
			)
		
			if ($Protocol) {
				$cmd += "-p"
				$cmd += $Protocol.ToLower()
			}
		
			if ($Port) {
				$cmd += "--dport"
				$cmd += $Port
			}
		
			if ($RemoteAddress) {
				$cmd += "-s"
				$cmd += $RemoteAddress
			}
		
			if ($LocalAddress) {
				$cmd += "-d"
				$cmd += $LocalAddress
			}
		
			# Metadata (rule name + zone)
			$cmd += "-m"
			$cmd += "comment"
			$cmd += "--comment"
			$cmd += "$Name|zone=$Zone"
		
			# ✅ FIXED: split jump and target
			$cmd += "-j"
			$cmd += if ($Action -eq "Allow") { "ACCEPT" } else { "DROP" }
		
			sudo $cmd | out-null
			sudo firewall-cmd --reload | out-null
		}

    }
}


function Get-FirewallRule {
    param(
        [string]$Name,
        [string]$Zone = "public"
    )

    $results = @()

    switch (Get-Platform) {
        "Windows" {

            $rules = if ($Name) {
                Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
            } else {
                Get-NetFirewallRule
            }

            foreach ($r in $rules) {

                $portFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $r
                $addrFilter = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $r
                $appFilter  = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $r

                $results += [PSCustomObject]@{
                    Name          = $r.DisplayName
                    Platform      = "Windows"
                    Zone          = $r.Profile
                    Direction     = $r.Direction
                    Action        = $r.Action
                    Protocol      = if ($portFilter.Protocol) { $portFilter.Protocol } else { "Any" }
                    Port          = if ($portFilter.LocalPort -and $portFilter.LocalPort -ne "Any") {
                                        [int]$portFilter.LocalPort
                                    } else { $null }
                    Program       = $appFilter.Program
                    RemoteAddress = $addrFilter.RemoteAddress
                    LocalAddress  = $addrFilter.LocalAddress
                    Family        = "ipv4"
                }
            }
        }
        "Linux" {

            $rules = sudo firewall-cmd --direct --get-all-rules

            foreach ($line in $rules) {

                # Example line:
                # ipv4 filter INPUT 0 -p tcp --dport 443 -s 1.2.3.4 -m comment --comment "Allow HTTPS|zone=public" -j ACCEPT

                if ($Name -and $line -notmatch [regex]::Escape($Name)) {
                    continue
                }

                if ($line -notmatch "zone=$Zone") {
                    continue
                }

                $tokens = $line -split '\s+'

                $family = $tokens[0]
                $chain  = $tokens[2]

                $direction = if ($chain -eq "INPUT") { "Inbound" } else { "Outbound" }

                $protocol = "Any"
                if ($line -match "-p\s+(tcp|udp)") {
                    $protocol = $Matches[1].ToUpper()
                }

                $port = $null
                if ($line -match "--dport\s+(\d+)") {
                    $port = [int]$Matches[1]
                }

                $remote = $null
                if ($line -match "-s\s+([0-9./]+)") {
                    $remote = $Matches[1]
                }

                $local = $null
                if ($line -match "-d\s+([0-9./]+)") {
                    $local = $Matches[1]
                }

                $action = if ($line -match "-j\s+ACCEPT") { "Allow" } else { "Block" }

                $name = $null
                if ($line -match "'.*\|") {
                    $name = $Matches[0].replace("'","").replace("|","")
                }

                $results += [PSCustomObject]@{
                    Name          = $name
                    Platform      = "Linux"
                    Zone          = $Zone
                    Direction     = $direction
                    Action        = $action
                    Protocol      = $protocol
                    Port          = $port
                    Program       = $null
                    RemoteAddress = $remote
                    LocalAddress  = $local
                    Family        = $family
                }
				$Name = $Null
            }
        }
    }

    $results
}


function Remove-FirewallRule {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [string]$Zone = "public",
        [ValidateSet("ipv4","ipv6")] [string]$Family = "ipv4"
    )

    switch (Get-Platform) {

        "Windows" {
            Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue |
                Remove-NetFirewallRule
        }

        "Linux" {
            $rules = @(sudo firewall-cmd --direct --get-all-rules | Where-Object { $_ -match "$Name.*\|zone=$Zone" })
            foreach ($r in $rules) {
                Invoke-Expression "sudo firewall-cmd --permanent --direct --remove-rule $r" | out-null
            }

            sudo firewall-cmd --reload | out-null
        }
    }
}
