
<#

Detection Script for TLS 1.0 and TLS 1.1 (Client and Server)

Overview
This PowerShell script detects and verifies the registry configurations for TLS 1.0 and TLS 1.1 protocols (both Client and Server) to ensure compliance with security best practices. The script checks if these protocols are disabled (DisabledByDefault=1 and Enabled=0) to enhance system security and align with modern standards.
By running this script, administrators can quickly identify systems where TLS 1.0 and TLS 1.1 are not properly disabled, reducing the risk of using outdated or insecure encryption protocols.

Features
Checks the registry paths for TLS 1.0 and TLS 1.1 (Client and Server).
Verifies registry values for DisabledByDefault and Enabled.
Outputs the compliance status for each protocol.
Provides an overall compliance summary (compliant or non-compliant).
Exits with a status code:
0 for compliance.
1 for non-compliance.

Prerequisites
PowerShell: The script requires Windows PowerShell to execute.
Permissions: Must be run with administrative privileges to access and read the registry.
Operating System: Designed for Windows systems where TLS protocols are configurable in the registry.


#>

