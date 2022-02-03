$verbose= $true

$host.ui.RawUI.WindowTitle= "UPS Monitor"
$snmp= New-Object -ComObject olePrn.oleSNMP
#$ErrorActionPreference= "SilentlyContinue"
.\Send-Report.ps1 "Starting UPS monitor..."

while (1) 
{
    $upsList= @()
    if ($verbose) {Write-Host "Getting UPS list..."}
    $dhcpServerList= Get-DhcpServerInDC
    foreach ($dhcpServer in $dhcpServerList) 
    {
        $upsList+= Get-DhcpServerv4Scope -ComputerName $dhcpServer.dnsName | Get-DhcpServerv4Lease -ComputerName $dhcpServer.dnsName | Where-Object {($_.clientID -like "28-29-86*") -or ($_.clientId -like "00-c0-b7*")}
    }
    if ($verbose) {Write-Host "Beginning checks..."}
    foreach ($ups in $upsList)
    {
        if ($verbose) {Write-Host "trying $($ups.IPAddress)..."}
        if (!(Test-Connection -ComputerName $ups.IPAddress -Quiet -Count 1)) 
        {
            if ($verbose) {Write-Host "no answer"}
            continue
        }
        $snmp.Open($ups.IPAddress,"ccspub",1,1000)
        $res= $snmp.Get(".1.3.6.1.4.1.318.1.1.1.11.1.1.0")
        if ($res[32] -eq "1") 
        {
            .\Send-Report.ps1 "$($ups.hostName) no batteries attached"
        }
        if ($res[4] -eq "1") 
        {
            .\Send-Report.ps1 "$($ups.hostName) replace batteries"
        }
    }
    if ($verbose) {Write-Host "sleeping now..."}
    Start-Sleep -Seconds 86400
}