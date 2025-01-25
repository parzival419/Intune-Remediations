#### Remediation for TLS 1.0 and TLS 1.1 (Client and Server)
#### Author  : Jerry Cuevas
### Date    : 01/2025
### Version : 1.0

# Registry paths for TLS 1.0 and TLS 1.1 (Client and Server)
$protocols = @(
    @{
        Name = "TLS 1.0 Client"
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client"
    },
    @{
        Name = "TLS 1.0 Server"
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server"
    },
    @{
        Name = "TLS 1.1 Client"
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
    },
    @{
        Name = "TLS 1.1 Server"
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
    }
)

# Desired values for compliance
$desiredDisabledByDefault = 1
$desiredEnabled = 0

# Apply remediation
foreach ($protocol in $protocols) {
    $path = $protocol.Path
    $name = $protocol.Name

    # Ensure the registry path exists
    if (-not (Test-Path $path)) {
        Write-Output "Creating registry path: ${path}"
        New-Item -Path $path -Force | Out-Null
    }

    # Set DisabledByDefault = 1
    try {
        Set-ItemProperty -Path $path -Name "DisabledByDefault" -Value $desiredDisabledByDefault -Force
        Write-Output "${name}: DisabledByDefault set to ${desiredDisabledByDefault}."
    } catch {
        Write-Output "Failed to set DisabledByDefault for ${name}. Error: $_"
    }

    # Set Enabled = 0
    try {
        Set-ItemProperty -Path $path -Name "Enabled" -Value $desiredEnabled -Force
        Write-Output "${name}: Enabled set to ${desiredEnabled}."
    } catch {
        Write-Output "Failed to set Enabled for ${name}. Error: $_"
    }
}

Write-Output "Remediation completed. TLS 1.0 and TLS 1.1 should now be disabled for both Client and Server."

#### Detection Script for TLS 1.0 and TLS 1.1 (Client and Server)
### Author : Jerry Cuevas 
### Date : 01/2025
### Verison 1.0


# Registry paths for TLS 1.0 and TLS 1.1 (Client and Server)
$protocols = @(
    @{
        Name = "TLS 1.0 Client"
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client"
    },
    @{
        Name = "TLS 1.0 Server"
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server"
    },
    @{
        Name = "TLS 1.1 Client"
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
    },
    @{
        Name = "TLS 1.1 Server"
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
    }
)

# Desired values for compliance
$desiredDisabledByDefault = 1
$desiredEnabled = 0

# Initialize overall compliance flag
$allCompliant = $true

# Check each protocol configuration
foreach ($protocol in $protocols) {
    $path = $protocol.Path
    $name = $protocol.Name

    if (Test-Path $path) {
        $disabledByDefault = (Get-ItemProperty -Path $path -Name "DisabledByDefault" -ErrorAction SilentlyContinue)."DisabledByDefault"
        $enabled = (Get-ItemProperty -Path $path -Name "Enabled" -ErrorAction SilentlyContinue)."Enabled"

        if ($disabledByDefault -eq $desiredDisabledByDefault -and $enabled -eq $desiredEnabled) {
            Write-Output "$name is correctly configured (DisabledByDefault=1, Enabled=0)."
        } else {
            Write-Output "$name is not correctly configured (DisabledByDefault=$disabledByDefault, Enabled=$enabled)."
            $allCompliant = $false
        }
    } else {
        Write-Output "$name registry path does not exist."
        $allCompliant = $false
    }
}

# Determine overall compliance
if ($allCompliant) {
    Write-Output "TLS 1.0 and TLS 1.1 are disabled for both Client and Server."
    Exit 0 # Compliance
} else {
    Write-Output "TLS 1.0 and/or TLS 1.1 are not properly disabled for Client and/or Server."
    Exit 1 # Non-compliance
}

