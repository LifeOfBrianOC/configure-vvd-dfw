#PowerShell script to configure the NSX-V Distributed Firewall per VMware Validated Design guidance
#Created by Brian O'Connell
#VMware ISBU Solutions Architecture

### User Variables ###

#Target vCenter Server details
$vCenterServer = "sfo01m01vc01.rainpole.local"
$vCenterServerUser = "administrator@vsphere.local"
$vCenterServerPassword = "VMw@re1!"

# Target NSX Manager details
$NSXServer = "sfo01m01nsx01.rainpole.local"
$NSXAdminPassword = "VMw@re1!"

#VM Name of vCenter to exclude. e.g. "sfo01m01vc01"
$vCenterToExclude = "sfo01m01vc01"
#Comma separated list of Platform Services Controller IPs. e.g. "192.168.110.61,192.168.110.63"
$PSCIPs = @("192.168.110.61,192.168.110.63")
#Comma separated list of vCenter Server IPs. e.g. "192.168.110.62,192.168.110.64"
$VCIPs = @("192.168.110.62,192.168.110.64")
#Comma separated list of vRealize Automation Appliance IPs. e.g. "192.168.11.50,192.168.11.51,192.168.11.52"
$vRAIPs = "192.168.11.50,192.168.11.51,192.168.11.52"
#Comma separated list of vRealize Automation IaaS Web, Manager & DEM instance IPs. e.g. "192.168.11.54,192.168.11.55,192.168.11.57,192.168.11.58,192.168.11.60,192.168.11.61"
$vRAIaaSIPs = "192.168.11.54,192.168.11.55,192.168.11.57,192.168.11.58,192.168.11.60,192.168.11.61"
#Comma separated list of vRealize Automation IaaS Proxy Agent IPs. e.g. "192.168.31.52,192.168.31.53"
$vRAProxyIPs = "192.168.31.52,192.168.31.53"
#vRealize Business Server IP. e.g. "192.168.11.66"
$vRBIPs = "192.168.11.66"
#Comma separated list of vRealize Business Collector IPs. e.g. "192.168.31.54"
$vRBCIPs = "192.168.31.54"
#Comma separated list of vRealize Operations Manager Analytics cluster node IPs. e.g. "192.168.11.31,192.168.11.32,192.168.11.33"
$vROPsIPs = "192.168.11.31,192.168.11.32,192.168.11.33"
#Comma separated list of vRealize Operations Manager Remote Collector node IPs. e.g. "192.168.31.31,192.168.31.32"
$vROPsCIPs = "192.168.31.31,192.168.31.32"
#Comma separated list of vRealize Log Insight node IPs including forwarders. e.g. "192.168.31.11,192.168.31.12,192.168.31.13"
$vRLIIPs = "192.168.31.11,192.168.31.12,192.168.31.13"
#Comma separated list of vRealize Lifecycle Manager node IPs. e.g. "192.168.11.20"
$vRSLCMIPs = "192.168.11.20"
#Region Specific Site Recovery Manager IP. e.g. "192.168.110.124"
$SRMIPs = "192.168.110.124"
#Region Specific vSphere Replication IP. e.g. "192.168.110.123"
$vRIPs = "192.168.110.123"
#Region Specific Update Manager Download Service IP. e.g. "192.168.110.67"
$UMDSIPs = "192.168.110.67"
#Comma separated list of Management-VLAN_Subnets, Management-VXLAN_Subnets. e.g. "192.168.110.0/24,192.168.11.0/24,192.168.31.0/24"
$SDDCIPs = "192.168.110.0/24,192.168.11.0/24,192.168.31.0/24"
#Comma separated list of Administrator Subnets. e.g. "192.168.110.0/24"
$AdminsIPs = "192.168.110.0/24"

### DO NOT MODIFY ANYTHING BELOW THIS LINE UNLESS YOU REQUIRE CUSTOM NAMES FOR IP SETS & SECURITY GROUPS ###


$IpSetPSCName = "Platform Services Controller Instances"
$IpSetVCName = "vCenter Server Instances"
$IPSetvRAName = "vRealize Automation Appliances"
$IPSetvRAIaaSName = "vRealize Automation Windows"
$IPSetvRAProxyName = "vRealize Automation Proxy Agents"
$IPSetvRBName = "vRealize Business Server"
$IPSetvRBCName = "vRealize Business Data Collector"
$IPSetvROPsName = "vRealize Operations Manager"
$IPSetvROPsCName = "vRealize Operations Manager Remote Collectors"
$IPSetvRLIName = "vRealize Log Insight"
$IPSetvRSLCMName = "vRealize Suite Lifecycle Manager"
$IPSetSRMName = "Site Recovery Manager"
$IPSetvRName = "vSphere Replication"
$IPSetUMDSName = "Update Manager Download Service"
$IPSetSDDCName = "SDDC"
$IPSetAdminsName = "Administrators"
$WindowsServersSGName = "Windows Servers"
$VMwareAppliancesSGName = "VMware Appliances"
$NSXFirewallSectionName = "VMware Management Services"

$Rule1Name = "Allow vRA Portal to end users"
$Rule2Name = "Allow vRA Console Proxy to end users"
$Rule3Name = "Allow SDDC to any"
$Rule4Name = "Allow PSC to admins"
$Rule5Name = "Allow SSH to admins"
$Rule6Name = "Allow RDP to admins"
$Rule7Name = "Allow Orchestrator to admins"
$Rule8Name = "Allow vRB Data Collector to admins"
$Rule9Name = "Allow vROPs to admins"
$Rule10Name = "Allow vRLI to admins"
$Rule11Name = "Allow vRSLCM to admins"
$Rule12Name = "Allow VAMI to admins"
$Rule13Name = "Allow VMware VADP Solution to admins"

### DO NOT MODIFY ANYTHING BELOW THIS LINE ###

Function Get-PowerNSX {
# Check if PowerNSX Module is installed
Write-Host "Checking if PowerNSX is installed" -ForegroundColor Cyan
if (Get-Module -ListAvailable -Name PowerNSX) {
Write-Host "PowerNSX is installed" -ForegroundColor Green
}
else {
	Write-Host "PowerNSX is not installed" -ForegroundColor Red
	Write-Host "Attempting Install" -ForegroundColor Cyan
	Find-Module PowerNSX | Install-Module
	}
}

Function Connect-Server {
Write-Host "Connecting to $vCenterServer" -ForegroundColor Cyan
Connect-VIServer -Server $vCenterServer -user $vCenterServerUser -password $vCenterServerPassword | Out-Null
Write-Host "Connecting to $NSXServer" -ForegroundColor Cyan
Connect-NSXServer -Server $NSXServer -user "admin" -password $NSXAdminPassword | Out-Null
}

#Add VMs to the DFW Exclusion List
Function ExcludeVM {
Write-Host "Adding $vCenterToExclude to the DFW Exclusions List" -ForegroundColor Cyan
Get-VM $vCenterToExclude | Add-NsxFirewallExclusionListMember | Out-Null
Write-Host "Done" -ForegroundColor Green
}

#Create IP Sets
Function CreateNSXIpSets {
$IPSetHash = @{$IpSetPSCName = $PSCIPs;$IpSetVCName=$VCIPs;$IPSetvRAName=$vRAIPs;$IPSetvRAIaaSName=$IPSetvRAIaaIPs;$IPSetvRAProxyName=$vRAProxyIPs;$IPSetvRBName=$vRBIPs;$IPSetvRBCName=$vRBCIPs;$IPSetvROPsName=$vROPsIPs;$IPSetvROPsCName=$vROPsCIPs;$IPSetvRLIName=$vRLIIPs;$IPSetvRSLCMName=$vRSLCMIPs;$IPSetSRMName=$SRMIPs;$IPSetvRName=$vRIPs;$IPSetUMDSName=$UMDSIPs;$IPSetSDDCName=$SDDCIPs;$IPSetAdminsName=$AdminsIPs}

foreach ($key in $IPSetHash.keys) {
$value = $IPSetHash[$key]
Write-Host "Createing IP Set $key" -ForegroundColor Cyan
new-nsxipset -Name $key  -Universal -IPAddress $value | Out-Null
Write-Host "Done" -ForegroundColor Green
}
}

# Create Security Groups
Function CreateNSXSecurityGroups {
$IPSets = @($IpSetPSCName,$IpSetVCName,$IPSetvRAName,$IPSetvRAIaaSName,$IPSetvRAProxyName,$IPSetvRBName,$IPSetvRBCName,$IPSetvROPsName,$IPSetvROPsCName,$IPSetvRLIName,$IPSetvRSLCMName,$IPSetSRMName,$IPSetvRName,$IPSetUMDSName,$IPSetSDDCName,$IPSetAdminsName)

Foreach ($IPSet in $IPSets) {
$IPSetName = Get-NsxIpSet $IPSet | Select-Object -ExpandProperty Name
$Member = Get-NsxIpSet $IPSet
Write-Host "Creating Security Group $IPSetName" -ForegroundColor Cyan
New-NsxSecurityGroup $IPSetName -Universal -IncludeMember $Member | Out-Null
Write-Host "Done" -ForegroundColor Green
}
#Create Nested Security Group Windows Servers
Write-Host "Creating Security Group $WindowsServersSGName" -ForegroundColor Cyan
$WindowsServers = @($IPSetSRMName, $IPSetvRAIaaSName, $IPSetvRAProxyName)
New-NsxSecurityGroup $WindowsServersSGName -Universal | Out-Null
Foreach ($Server in $WindowsServers) {
$SG = Get-NSXSecurityGroup $WindowsServersSGName
$Member = Get-NsxSecurityGroup $Server
Add-NSXSecurityGroupMember -SecurityGroup $SG -Member $Member | Out-Null
}
Write-Host "Done" -ForegroundColor Green
#Create Nested Security Group VMware Appliances
Write-Host "Creating Security Group $VMwareAppliancesSGName" -ForegroundColor Cyan
$VMwareAppliances = @($IpSetPSCName, $IpSetVCName, $IPSetvRName, $IPSetvRAName, $IPSetvRBName, $IPSetvRBCName, $IPSetvROPsName, $IPSetvROPsCName, $IPSetvRSLCMName, $IPSetvRLIName)
New-NsxSecurityGroup $VMwareAppliancesSGName -Universal | Out-Null
Foreach ($Server in $VMwareAppliances) {
$SG = Get-NSXSecurityGroup $VMwareAppliancesSGName
$Member = Get-NsxSecurityGroup $Server
Add-NSXSecurityGroupMember -SecurityGroup $SG -Member $Member | Out-Null
}
Write-Host "Done" -ForegroundColor Green
}

# Create Firewall Section
Function CreateNSXFirewallSection {
New-NsxFirewallSection $NSXFirewallSectionName -Universal
}


Function Create-NSXFirewallRules {
# Get Service IDs
$SSH = Get-NsxService SSH | Where-Object {$_.isUniversal -eq $true}
$HTTP = Get-NsxService HTTP | Where-Object {$_.isUniversal -eq $true}
$HTTPS = Get-NsxService HTTPS | Where-Object {$_.isUniversal -eq $true}
$RDP = Get-NsxService RDP | Where-Object {$_.isUniversal -eq $true}
$HTTPALL = @($HTTP,$HTTPS)
$TCP8444 = New-NsxService -name 'TCP8444' -Universal -protocol tcp -port 8444
$TCP5480 = New-NsxService -name 'TCP5480' -Universal -protocol tcp -port 5480
$TCP8543 = New-NsxService -name 'TCP8543' -Universal -protocol tcp -port 8543
$TCP8283_8281 = New-NsxService -name 'TCP8283-8281' -Universal -protocol tcp -port '8283,8281'


#Create Rule: Allow vRA Portal to end users
$RuleName = $Rule1Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -service $HTTPALL | out-Null
#Add Destinations
$Destinations = ($IPSetvRAName, $IPSetvRAIaaSName, $IPSetvRBName)
Foreach ($Destination in $Destinations) {
Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"} | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $Destination) | Out-Null
}
Write-Host "Done" -ForegroundColor Green

#Create Rule: Allow vRA Console Proxy to end users
$RuleName = $Rule2Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -service (Get-NSXService 'TCP8444') | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $IPSetvRAName) | out-Null
Write-Host "Done" -ForegroundColor Green


#Create Rule: Allow SDDC to any
$RuleName = $Rule3Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Source (Get-NSXSecurityGroup $IPSetSDDCName) | out-Null
Write-Host "Done" -ForegroundColor Green

#Create Rule: Allow PSC to admins
$RuleName = $Rule4Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -Service $HTTPS | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Source (Get-NSXSecurityGroup $IPSetAdminsName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $IpSetPSCName) | out-Null
Write-Host "Done" -ForegroundColor Green

#Create Rule: Allow SSH to admins
$RuleName = $Rule5Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -Service $SSH | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Source (Get-NSXSecurityGroup $IPSetAdminsName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $VMwareAppliancesSGName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $IPSetUMDSName) | out-Null
Write-Host "Done" -ForegroundColor Green

#Create Rule: Allow RDP to admins
$RuleName = $Rule6Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -Service $RDP | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Source (Get-NSXSecurityGroup $IPSetAdminsName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $WindowsServersSGName) | out-Null
Write-Host "Done" -ForegroundColor Green

#Create Rule: Allow Orchestrator to admins
$RuleName = $Rule7Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -Service  (Get-NSXService 'TCP8283-8281') | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Source (Get-NSXSecurityGroup $IPSetAdminsName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $IPSetvRAName) | out-Null
Write-Host "Done" -ForegroundColor Green


#Create Rule: Allow vRB Data Collector to admins
$RuleName = $Rule8Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -Service $HTTPALL | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Source (Get-NSXSecurityGroup $IPSetAdminsName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $IPSetvRBCName) | out-Null
Write-Host "Done" -ForegroundColor Green

#Create Rule: Allow vROPs to admins
$RuleName = $Rule9Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -Service $HTTPALL | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Source (Get-NSXSecurityGroup $IPSetAdminsName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $IPSetvROPsName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $IPSetvROPsCName) | out-Null
Write-Host "Done" -ForegroundColor Green

#Create Rule: Allow vRLI to admins
$RuleName = $Rule10Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -Service $HTTPALL | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Source (Get-NSXSecurityGroup $IPSetAdminsName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $IPSetvRLIName) | out-Null
Write-Host "Done" -ForegroundColor Green

#Create Rule: Allow vRSLCM to admins
$RuleName = $Rule11Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -Service $HTTPS | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Source (Get-NSXSecurityGroup $IPSetAdminsName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $IPSetvRSLCMName) | out-Null
Write-Host "Done" -ForegroundColor Green

#Create Rule: Allow VAMI to admins
$RuleName = $Rule12Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -Service  (Get-NSXService 'TCP5480') | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Source (Get-NSXSecurityGroup $IPSetAdminsName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $VMwareAppliancesSGName) | out-Null
Write-Host "Done" -ForegroundColor Green

#Create Rule: Allow VMware VADP Solution to admins
$RuleName = $Rule13Name
Write-Host "Creating DFW Rule: $RuleName" -ForegroundColor Cyan
Get-NsxFirewallSection $NSXFirewallSectionName | New-NsxFirewallRule -name $RuleName -action "allow" -Service  (Get-NSXService 'TCP8543') | out-Null
#Add Destinations
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Source (Get-NSXSecurityGroup $IPSetAdminsName) | out-Null
(Get-NSXFirewallRule -name $RuleName | Where-Object {$_.managedBy -eq "universalroot-0"}) | Add-NsxFirewallRuleMember -MemberType Destination (Get-NSXSecurityGroup $VMwareAppliancesSGName) | out-Null
Write-Host "Done" -ForegroundColor Green

}

Function anyKey 
{
    Write-Host -NoNewline -Object 'Press any key to return to the main menu...' -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Menu
}

Function Menu 
{
    Clear-Host         
    Do
    {
        Clear-Host
        Write-Host -Object 'Please choose an option'
        Write-Host     -Object '**********************'
        Write-Host -Object 'Configure VVD NSX Distributed Firewall' -ForegroundColor Cyan
        Write-Host     -Object '**********************'
        Write-Host -Object ''						
        Write-Host -Object '1.  Create IP Sets & Security Groups'
        Write-Host -Object ''
		Write-Host -Object '2.  Create NSX Distributed Firewall Rules'
        Write-Host -Object ''
        Write-Host -Object 'Q.  Quit'
        Write-Host -Object $errout
        $Menu = Read-Host -Prompt '(1-2, Q)'

        switch ($Menu) 
        {
            1 
            {
                Get-PowerNSX
				Connect-Server
				ExcludeVM
                CreateNSXIpSets
                CreateNSXSecurityGroups
                anyKey
            }
			2
            {
                Connect-Server
				Create-NSXFirewallRules
                anyKey
            }
            3
			{
                Exit
            }
            default 
            {
                $errout = 'Invalid option please try again........Try 1-2 or Q only'
            }

        }
    }
    until ($Menu -ne '')
}
Menu
