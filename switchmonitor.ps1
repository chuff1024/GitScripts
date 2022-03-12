Set-Location $scriptPath
$host.ui.RawUI.WindowTitle= "Switch Port Monitor"
$verbose= $true
$snmpReadPass= "snmpReadPass"
$snmpWritePass= "snmpWritePass"

.\Send-Report.ps1 "Starting switch monitoring script..."

while (1) 
{
    #get list of switches to monitor
    if ($verbose) {"getting list of switches..."}
    $switchList= $switchList
    $switchList+= (Get-DhcpServerv4Lease -ComputerName $dhcpserver -ScopeId 10.255.248.0).IPAddress

    #initialize variable(s)
    $snmp= New-Object -ComObject oleprn.olesnmp
    #$ErrorActionPreference= "SilentlyContinue"

    foreach ($switch in $switchList) {
        #initialize variables
        $systemName= ""
        $poeArray= @()
        $poeHash= @{}
        $macArray= @()
        $macHash= @{}
        $ifArray= @()
        $ifHash= @{}
        #get/arrange pertinent port data
        if ($verbose) {"checking $switch..."}
        if (!(Test-Connection -ComputerName $switch -Quiet -Count 1)) {continue}
        $snmp.Open($switch,$snmpReadPass,1,1000)
        $systemName= $snmp.get(".1.3.6.1.2.1.1.5.0")
        $poeArray= $snmp.gettree(".1.3.6.1.2.1.105.1.1.1.6")
        for ($i=0; $i -lt $poeArray.Length/2; $i++) {
            $index= "$($poeArray[0,$i].Split(".")[-2]).$($poeArray[0,$i].Split(".")[-1])"
            $poeHash[$index]= $poeArray[1,$i]
        } 
        $macArray= $snmp.GetTree(".1.3.6.1.2.1.17.7.1.2.2.1.2")
        for ($i=0; $i -lt $macArray.Length/2; $i++) {
            $macHash[$macArray[0,$i]]= $macArray[1,$i]
        }
        $ifArray= $snmp.GetTree(".1.3.6.1.2.1.31.1.1.1.1")
        for ($i=0; $i -lt $ifArray.Length/2; $i++) {
            $ifHash[$ifArray[0,$i].Split(".")[-1]]= $ifArray[1,$i] 
        }

        #make comparisons/ take actions
        foreach ($port in $poeHash.Keys) {
            if ($poeHash[$port] -ne 3) {continue}
            if ($macHash.Values -notcontains $port.Split(".")[-1]) {
                .\Send-Report.ps1 "problem at port index $port on $systemName"
                $snmp.Open($switch,$snmpWritePass,1,1000)
                $snmp.Set(".1.3.6.1.2.1.105.1.1.1.3.$port",2)
                Start-Sleep -Seconds 6
                $snmp.Set(".1.3.6.1.2.1.105.1.1.1.3.$port",1)
            }
        }
        $snmp.Close()
    }
    if ($verbose) {"sleeping..."}
    Start-Sleep -Seconds 3600
}
