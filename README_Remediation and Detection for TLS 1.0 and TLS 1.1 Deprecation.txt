
<#


Here’s a complete README file for your project:

Remediation and Detection for TLS 1.0 and TLS 1.1 Deprecation
Overview
This repository contains PowerShell scripts to help organizations detect and remediate configurations related to the deprecation of TLS 1.0 and TLS 1.1 protocols. These legacy protocols are insecure and should be explicitly disabled to comply with modern security standards such as PCI DSS, NIST, and Microsoft's recommendations.

The scripts ensure that both the Client and Server configurations for TLS 1.0 and TLS 1.1 are disabled by modifying relevant registry keys on Windows systems.

Contents
1. Remediation Script
File: Remediation-TLS.ps1
Purpose: This script ensures compliance by configuring the registry to disable TLS 1.0 and TLS 1.1 for both Client and Server settings.

It sets the following registry values for each protocol:

DisabledByDefault = 1: Disables the protocol by default.
Enabled = 0: Explicitly disables the protocol.
Targeted Registry Paths:

HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client
HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server
HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client
HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server
2. Detection Script
File: Detection-TLS.ps1
Purpose: This script verifies whether TLS 1.0 and TLS 1.1 are properly disabled by checking the registry values.

The script checks the same registry paths targeted by the remediation script and validates that:

DisabledByDefault = 1
Enabled = 0
Output:

Compliant: "TLS 1.0 and TLS 1.1 are disabled for both Client and Server."
Non-Compliant: Details which protocols and configurations are not properly set.
Exit Codes:

0: Compliance achieved.
1: Non-compliance detected.
Why Disable TLS 1.0 and TLS 1.1?
TLS 1.0 and TLS 1.1 are deprecated cryptographic protocols with known vulnerabilities, including:

Man-in-the-middle (MITM) attacks
Downgrade attacks
Exploits like BEAST, POODLE, and Logjam
By disabling these protocols, you ensure the system uses TLS 1.2 or TLS 1.3, providing modern encryption standards and enhanced security.



#>

