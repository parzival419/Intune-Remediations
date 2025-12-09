

# Intune Detection (User Context)
# Exit 0 -> compliant (uptime < 1 day)
# Exit 1 -> non-compliant (uptime >= 1 day)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

function Get-UptimeSpan {
    try {
        # Primary: Win32_OperatingSystem
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $raw = $os.LastBootUpTime

        if ($raw -is [DateTime]) {
            $lastBoot = $raw
        } elseif ($raw -is [string] -and $raw.Length -ge 8) {
            # Convert DMTF string to DateTime
            $lastBoot = [Management.ManagementDateTimeConverter]::ToDateTime($raw)
        } else {
            throw "Unexpected LastBootUpTime type: $($raw.GetType().FullName)"
        }

        return (Get-Date) - $lastBoot
    }
    catch {
        # Fallback: Perf counter SystemUpTime (seconds)
        try {
            $perf = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_System -ErrorAction Stop
            $seconds = [double]$perf.SystemUpTime
            if ($seconds -gt 0) {
                return [TimeSpan]::FromSeconds($seconds)
 } else {
                throw "PerfOS SystemUpTime returned invalid value: $seconds"
            }
        }
        catch {
            return $null
        }
    }
}
