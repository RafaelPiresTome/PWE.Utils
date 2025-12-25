function Invoke-HostMetrics {
    [CmdletBinding()]
    param(
        [switch]$CPU,
        [switch]$RAM,
        [switch]$Disk,
        [switch]$GPU,
        [switch]$Network,
        [string]$CsvPath,
        [string]$SqlitePath,
        [int]$Interval = 5,
        [switch]$Continuous
    )

    function NowIso { (Get-Date).ToString("s") }
    $onWindows = $PSVersionTable.Platform -eq "Win32NT"

    # Locate nvidia-smi if not in PATH
    $nvidiaSmi = if ($onWindows) {
        @(
            "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe",
            "$env:ProgramFiles(x86)\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    } else {
        (Get-Command nvidia-smi -ErrorAction SilentlyContinue)?.Source
    }

    # Optional SQLite support
    $useSqlite = $false
    if ($SqlitePath) {
        try {
            Import-Module PSSQLite -ErrorAction Stop
            $useSqlite = $true
        } catch {
            Write-Warning "PSSQLite not found. Install it via: Install-Module PSSQLite -Scope CurrentUser"
        }
    }

    # ---- Metric collectors ----
    function Get-CPU {
        if ($onWindows) {
            $cpu  = Get-CimInstance Win32_Processor
            $perf = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor | Where-Object Name -eq "_Total"
            [pscustomobject]@{
                Resource    = 'CPU'
                Timestamp   = NowIso
                cpu_percent = [math]::Round($perf.PercentProcessorTime, 2)
                core_count  = $cpu.NumberOfCores
            }
        } else {
            $usage = (grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
            $cores = (nproc)
            [pscustomobject]@{
                Resource    = 'CPU'
                Timestamp   = NowIso
                cpu_percent = [math]::Round([double]$usage, 2)
                core_count  = [int]$cores
            }
        }
    }

    function Get-RAM {
        if ($onWindows) {
            $os = Get-CimInstance Win32_OperatingSystem
            [pscustomobject]@{
                Resource        = 'RAM'
                Timestamp       = NowIso
                total_bytes     = [int64]$os.TotalVisibleMemorySize * 1KB
                available_bytes = [int64]$os.FreePhysicalMemory * 1KB
                used_bytes      = ([int64]$os.TotalVisibleMemorySize - [int64]$os.FreePhysicalMemory) * 1KB
                used_percent    = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
            }
        } else {
            $meminfo = @{}
            foreach ($line in (cat /proc/meminfo)) {
                if ($line -match '(\w+):\s+(\d+)') { $meminfo[$matches[1]] = [int64]$matches[2] * 1024 }
            }
            $total = $meminfo['MemTotal']
            $avail = $meminfo['MemAvailable']
            [pscustomobject]@{
                Resource        = 'RAM'
                Timestamp       = NowIso
                total_bytes     = $total
                available_bytes = $avail
                used_bytes      = $total - $avail
                used_percent    = [math]::Round((($total - $avail) / $total) * 100, 2)
            }
        }
    }

    function Get-Disk {
        $disks = @()
        if ($onWindows) {
            Get-CimInstance Win32_LogicalDisk |
                Where-Object DriveType -eq 3 |  # Only fixed disks
                ForEach-Object {
                    $disk = $_
                    $perf = Get-CimInstance Win32_PerfFormattedData_PerfDisk_LogicalDisk |
                        Where-Object Name -eq $disk.DeviceID
                    $disks += [PSCustomObject]@{
                        Resource      = 'Disk'
                        Timestamp     = NowIso
                        Name          = $disk.DeviceID
                        Root          = $disk.VolumeName
                        used_size      = [int64]($disk.Size - $disk.FreeSpace)
                        used_ratio     = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
                        free_size      = [int64]$disk.FreeSpace
                        free_ratio     = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
                        total         = [int64]$disk.Size
                        read_bytes_sec  = [int64]$perf.DiskReadBytesPerSec
                        write_bytes_sec = [int64]$perf.DiskWriteBytesPerSec
                    }
                }
        }
        else {
            df -k | Select-String -NotMatch "tmpfs|udev" | ForEach-Object {
                $line = $_ -split '\s+'
                $mount = $line[5]
                $stats = Get-Content "/sys/block/$(lsblk -no pkname $mount)/stat" -ErrorAction SilentlyContinue
                $readBytesSec = 0
                $writeBytesSec = 0
                if ($stats) {
                    $stats = $stats -split '\s+'
                    $readBytesSec = [int64]$stats[2] * 512
                    $writeBytesSec = [int64]$stats[6] * 512
                }
                $disks += [PSCustomObject]@{
                    Resource      = 'Disk'
                    Timestamp     = NowIso
                    Name          = $mount
                    Root          = $mount
                    used_size      = [int64]$line[2] * 1KB
                    used_ratio     = [math]::Round([double]($line[4].replace("%","")/100), 2)
                    free_size      = [int64]$line[3] * 1KB
                    free_ratio     = [math]::Round(100 - [double]($line[4].replace("%","")/100), 2)
                    total         = [int64]$line[1] * 1KB
                    bead_bytes_sec  = $readBytesSec
                    write_bytes_sec = $writeBytesSec
                }
            }
        }
        return $disks
    }

    function Get-GPU {
        if ($nvidiaSmi) {
            try {
                & $nvidiaSmi --query-gpu=index,name,utilization.gpu,utilization.memory,memory.total,memory.used,temperature.gpu,power.draw --format=csv,noheader,nounits |
                    ForEach-Object {
                        $f = ($_ -split ',') | ForEach-Object { $_.Trim() }
                        [pscustomobject]@{
                            Resource            = 'GPU'
                            Timestamp           = NowIso
                            gpu_index           = [int]$f[0]
                            name                = $f[1]
                            util_percent        = [double]$f[2]
                            memory_util_percent = [double]$f[3]
                            memory_total_mb     = [int]$f[4]
                            memory_used_mb      = [int]$f[5]
                            temperature_c       = [int]$f[6]
                            power_watts         = [double]$f[7]
                        }
                    }
            } catch {
                Write-Warning "Could not parse GPU metrics from nvidia-smi."
            }
        } elseif ($onWindows) {
            Get-CimInstance Win32_VideoController | ForEach-Object {
                [pscustomobject]@{
                    Resource            = 'GPU'
                    Timestamp           = NowIso
                    gpu_index           = 0
                    name                = $_.Name
                    util_percent        = $null
                    memory_util_percent = $null
                    memory_total_mb     = $null
                    memory_used_mb      = $null
                    temperature_c       = $null
                    power_watts         = $null
                }
            }
        }
    }

    function Get-Network {
        [CmdletBinding()]
        param([int]$SampleSeconds = 1)
        function Get-RawStats {
            $stats = @()
            if ($onWindows) {
                try {
                    $adapters = Get-NetAdapterStatistics -ErrorAction Stop
                    foreach ($a in $adapters) {
                        $stats += [PSCustomObject]@{
                            Name                   = $a.Name
                            received_bytes          = [int64]$a.ReceivedBytes
                            sent_bytes              = [int64]$a.SentBytes
                            received_unicast_packets = [int64]$a.ReceivedUnicastPackets
                            sent_unicast_packets     = [int64]$a.SentUnicastPackets
                        }
                    }
                } catch {
                    Write-Warning "Failed to get Windows stats: $_"
                }
            }
            else {
                try {
                    $interfaces = Get-ChildItem -Path /sys/class/net -ErrorAction Stop | Where-Object { $_.Name -ne 'lo' }
                    foreach ($if in $interfaces) {
                        $rx_bytes = Get-Content "$($if.FullName)/statistics/rx_bytes" -ErrorAction SilentlyContinue
                        $tx_bytes = Get-Content "$($if.FullName)/statistics/tx_bytes" -ErrorAction SilentlyContinue
                        $rx_pkts  = Get-Content "$($if.FullName)/statistics/rx_packets" -ErrorAction SilentlyContinue
                        $tx_pkts  = Get-Content "$($if.FullName)/statistics/tx_packets" -ErrorAction SilentlyContinue
                        $stats += [PSCustomObject]@{
                            Name                   = $if.Name
                            received_bytes          = [int64]$rx_bytes
                            sent_bytes              = [int64]$tx_bytes
                            received_unicast_packets = [int64]$rx_pkts
                            sent_unicast_packets     = [int64]$tx_pkts
                        }
                    }
                } catch {
                    Write-Warning "Failed to get Linux stats: $_"
                }
            }
            return $stats
        }
        $first = Get-RawStats
        Start-Sleep -Seconds $SampleSeconds
        $second = Get-RawStats
        $results = @()
        foreach ($iface in $second) {
            $prev = $first | Where-Object { $_.Name -eq $iface.Name }
            if ($null -eq $prev) { continue }
            $rx_delta = $iface.ReceivedBytes - $prev.ReceivedBytes
            $tx_delta = $iface.SentBytes - $prev.SentBytes
            $results += [PSCustomObject]@{
                Resource              = 'Network'
                Timestamp             = NowIso
                Name                  = $iface.Name
                received_gb            = [math]::Round($iface.ReceivedBytes / 1GB, 3)
                sent_gb                = [math]::Round($iface.SentBytes / 1GB, 3)
                received_packets       = $iface.ReceivedUnicastPackets
                sent_packets           = $iface.SentUnicastPackets
                receive_speed_gbps      = [math]::Round(($rx_delta / 1GB) / $SampleSeconds, 6)
                send_speed_gbps         = [math]::Round(($tx_delta / 1GB) / $SampleSeconds, 6)
            }
        }
        return $results
    }

    # ---- Ensure tables ----
    if ($useSqlite -and -not (Test-Path $SqlitePath)) {
        $schemas = @{
            cpu     = "CREATE TABLE IF NOT EXISTS cpu (timestamp TEXT, cpu_percent REAL, core_count INTEGER);"
            ram     = "CREATE TABLE IF NOT EXISTS ram (timestamp TEXT, total_bytes INTEGER, available_bytes INTEGER, used_bytes INTEGER, used_percent REAL);"
            disk    = "CREATE TABLE IF NOT EXISTS disk (timestamp TEXT, name TEXT, root TEXT, used_size INTEGER, used_ratio REAL, free_size INTEGER, free_ratio REAL, total INTEGER, read_bytes_sec INTEGER, write_bytes_sec INTEGER);"
            gpu     = "CREATE TABLE IF NOT EXISTS gpu (timestamp TEXT, gpu_index INTEGER, name TEXT, util_percent REAL, memory_util_percent REAL, memory_total_mb INTEGER, memory_used_mb INTEGER, temperature_c REAL, power_watts REAL);"
            network = "CREATE TABLE IF NOT EXISTS network (timestamp TEXT, name TEXT, received_gb REAL, sent_gb REAL, received_packets INTEGER, sent_packets INTEGER, receive_speed_gbps REAL, send_speed_gbps REAL);"
        }
        foreach ($q in $schemas.Values) {
            Invoke-SqliteQuery -DataSource $SqlitePath -Query $q
        }
    }

    Write-Host "Collecting host metrics... Press Ctrl+C to stop."
    do {
        $results = @()
        if ($CPU)     { $results += Get-CPU }
        if ($RAM)     { $results += Get-RAM }
        if ($Disk)    { $results += Get-Disk }
        if ($GPU)     { $results += Get-GPU }
        if ($Network) { $results += Get-Network -SampleSeconds 1 }

        if ($CsvPath) {
            if (-not (Test-Path $CsvPath)) { New-Item -ItemType Directory -Path $CsvPath -Force | Out-Null }
            foreach ($r in $results) {
                $table = $r.Resource.ToLower()
                $file  = Join-Path $CsvPath "$table.csv"
                $r | Export-Csv -Path $file -Append -NoTypeInformation -Encoding UTF8
            }
        }
        elseif ($useSqlite) {
            foreach ($r in $results) {
                $table = $r.Resource.ToLower()
                $cols  = ($r.PSObject.Properties | Where-Object Name -ne 'Resource').Name
                $colList   = ($cols -join ',')
                $paramList = ($cols | ForEach-Object { '@' + $_ }) -join ','
                $query = "INSERT INTO $table ($colList) VALUES ($paramList)"
                $params = @{}
                foreach ($c in $cols) { $params[$c] = $r.$c }
                Invoke-SqliteQuery -DataSource $SqlitePath -Query $query -SqlParameters $params -ErrorAction SilentlyContinue
            }
        }
        else {
            $results
        }
        if (-not $Continuous) { break }
        Start-Sleep -Seconds $Interval
    } while ($true)
}

function Get-DBHostMetrics {
    [CmdletBinding()]
    param(
        [ValidateSet('CPU','RAM','Disk','Network','GPU')]
		[String]$hostmetric,
        [String]$SqlitePath,
		[Switch]$Format,
		[Int]$Last
    )
	$result = Invoke-SqliteQuery -Query "SELECT * FROM $($hostmetric);" -Path "$SqlitePath"
	
	if($last){
		if($Format){
			return $result[-$last..-1] | format-table
		}
		return $result[-$last..-1]
	}
	
	if($Format){
		return $result | format-table
	}
	return $result
}

