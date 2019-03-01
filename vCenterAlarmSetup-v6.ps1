#---- vCenter Alert Setup Script ----#
$user="techdev\dave.lee"   					  # Replace with username for connecting to the vCenter instance
$pass="Telephone23!"        						  # Replace with password for connecting to the vCenter instance
$vCenterServer="10.2.34.21"					  # Replace with vCenter instance IP or DNS name
#$mailserver = "172.24.66.12"					  # Replace with SMTP server instance IP or DNS name
#$mailfromaddress = ""    # Email "from" field for sent alerts - set it to something we'll be able to recognise!
$MailtoAddresses= "dave.lee@techgateplc.com"    # Email "to" field - probably either SMC or Server Management Groups
$vCenterDescription = "Chelmsford Management Cluster vCenter (10.2.34.21)"		  # Will go into email body

#--- Additional information to be added to the top of any emails that go out - can be blank if you don't want anything added
$emailHeader = "This alert has been raised by: $vCenterDescription`n"
$emailContents = "`nTarget: {targetName}`nPrevious Status: {oldStatus}`nNew Status: {newStatus}`n`nAlarm Definition:`n{declaringSummary}`n`nCurrent values for metric/state:`n{triggeringSummary}`n`nDescription:`n{eventDescription}`n"
$emailFooter = ""
#$emailFooter = "`nFurther information dealing with these alerts can be found at https://insight.maxima.co.uk/sites/SAES/Engineering/Customers/Redstone%20Cloud%20Hoddesdon/"
$emailSubject = "{alarmName} - {targetName} status is {newStatus}"

#---- This function is used later on for changing thresholds ----# 
#---- Set any threshold changes you need at the end of the script ----# 
Function SetAlarmThresholds(){

    param(
        [Parameter(Mandatory=$true)][string]$alarmname,
        [Parameter(Mandatory=$true)][int]$yellowthresholdvalue,
        [Parameter(Mandatory=$true)][int]$redthresholdvalue
    )

	$viewAlarmToUpdate = Get-View -Id (Get-AlarmDefinition -Name $alarmname).Id
	$specNewAlarmInfo = $viewAlarmToUpdate.Info
	$specNewAlarmInfo.Expression.Expression[0].yellow = $yellowthresholdvalue
	$specNewAlarmInfo.Expression.Expression[0].red = $redthresholdvalue
	$viewAlarmToUpdate.ReconfigureAlarm($specNewAlarmInfo)	
}

#----Connect to the vCenter Server
Connect-VIServer -Server $vCenterServer -Protocol https -User $user -Password $pass

# -WarningAction SilentlyContinue | Out-Null

$sessionManager = Get-View -Id $global:DefaultVIServer.ExtensionData.Content.SessionManager
$sessionManager.SetLocale(“en-US”)

#---- The following will remove ALL email alerts on the vCenter so only uncomment this if that's what you want to do!
Get-AlarmDefinition | Get-AlarmAction -ActionType SendEmail | Remove-AlarmAction -Confirm:$false

#----Setup Mail Server Settings
#Get-AdvancedSetting –Entity $vCenterServer –Name mail.smtp.sender | Set-AdvancedSetting –Value $mailfromaddress -Confirm:$false
#Get-AdvancedSetting –Entity $vCenterServer –Name mail.smtp.server | Set-AdvancedSetting –Value $mailserver -Confirm:$false
#Get-AdvancedSetting –Entity $vCenterServer –Name mail.smtp.port | Set-AdvancedSetting –Value 25 -Confirm:$false

#----These Alarms will repeat every 24 hours----
$LowPriorityAlarms="Appliance Management Health Alarm",`
"Certificate Status",`
"Cis License Health Alarm",`
"Content Library Service Health Alarm",`
"Data Service Health Alarm",`
"Datastore capability alarm",`
"Datastore compliance alarm",`
"Datastore is in multiple datacenters",`
"ESX Agent Manager Health Alarm",`
"ESXi Host Certificate Status",`
"Exit standby error",`
"Expired host license",`
"Expired host time-limited license",`
"Expired vCenter Server license",`
"Expired vCenter Server time-limited license",`
"Expired Virtual SAN license",`
"Expired Virtual SAN time-limited license",`
"Host Baseboard Management Controller status",`
"Host battery status",`
"Host flash capacity exceeds the licensed limit for Virtual SAN",`
"Host IPMI System Event Log status",`
"Host virtual flash resource status",`
"Host virtual flash resource usage",`
"Identity Health Alarm",`
"Insufficient vSphere HA failover resources",`
"Inventory Health Alarm",`
"License capacity monitoring",`
"License error",`
"License inventory monitoring",`
"License user threshold monitoring",`
"Message Bus Config Health Alarm",`
"Migration error",`
"No compatible host for Secondary VM",`
"Object type storage alarm",`
"Open Virtualization Format Service Health Alarm",`
"Performance Charts Service Health Alarm",`
"RBD Health Alarm",`
"Refreshing CA certificates and CRLs for a VASA provider failed",`
"Registration/unregistration of a VASA vendor provider on a Virtual SAN host fails",`
"Registration/unregistration of third-party IO filter storage providers fails on a host",`
"Service Control Agent Health Alarm",`
"SRM Consistency Group Violation",`
"Storage DRS is not supported on a host",`
"Storage DRS recommendation",`
"The host license edition is not compatible with the vCenter Server license edition",`
"Transfer Service Health Alarm",`
"Unmanaged workload detected on SIOC-enabled datastore",`
"VASA Provider certificate expiration alarm",`
"VASA provider disconnected",`
"vCenter Server Health Alarm",`
"Virtual machine Consolidation Needed status",`
"Virtual machine CPU usage",`
"Virtual machine Fault Tolerance state changed",`
"Virtual Machine Fault Tolerance vLockStep interval Status Changed",`
"Virtual machine memory usage",`
"Virtual Machine network adapter reservation status",`
"Virtual SAN Health Alarm 'Active multicast connectivity check'",`
"Virtual SAN Health Alarm 'Advanced Virtual SAN configuration in sync'",`
"Virtual SAN Health Alarm 'After 1 additional host failure'",`
"Virtual SAN Health Alarm 'All hosts have a Virtual SAN vmknic configured'",`
"Virtual SAN Health Alarm 'All hosts have matching multicast settings'",`
"Virtual SAN Health Alarm 'All hosts have matching subnets'",`
"Virtual SAN Health Alarm 'Basic (unicast) connectivity check (normal ping)'",`
"Virtual SAN Health Alarm 'Cluster health'",`
"Virtual SAN Health Alarm 'Cluster with multiple unicast agents'",`
"Virtual SAN Health Alarm 'Component metadata health'",`
"Virtual SAN Health Alarm 'Congestion'",`
"Virtual SAN Health Alarm 'Controller Driver'",`
"Virtual SAN Health Alarm 'Controller Release Support'",`
"Virtual SAN Health Alarm 'Current cluster situation'",`
"Virtual SAN Health Alarm 'Data health'",`
"Virtual SAN Health Alarm 'Disk capacity'",`
"Virtual SAN Health Alarm 'ESX Virtual SAN Health service installation'",`
"Virtual SAN Health Alarm 'Fault domain number check'",`
"Virtual SAN Health Alarm 'Host issues retrieving hardware info'",`
"Virtual SAN Health Alarm 'Hosts disconnected from VC'",`
"Virtual SAN Health Alarm 'Hosts with connectivity issues'",`
"Virtual SAN Health Alarm 'Hosts with Virtual SAN disabled'",`
"Virtual SAN Health Alarm 'Hosts without configured unicast agent'",`
"Virtual SAN Health Alarm 'Limits health'",`
"Virtual SAN Health Alarm 'Memory pools (heaps)'",`
"Virtual SAN Health Alarm 'Memory pools (slabs)'",`
"Virtual SAN Health Alarm 'Metadata health'",`
"Virtual SAN Health Alarm 'MTU check (ping with large packet size)'",`
"Virtual SAN Health Alarm 'Multicast assessment based on other checks'",`
"Virtual SAN Health Alarm 'Network health'",`
"Virtual SAN Health Alarm 'Overall disks health'",`
"Virtual SAN Health Alarm 'Physical disk health'",`
"Virtual SAN Health Alarm 'Physical disk health retrieval issues'",`
"Virtual SAN Health Alarm 'SCSI Controller on Virtual SAN HCL'",`
"Virtual SAN Health Alarm 'Software state health'",`
"Virtual SAN Health Alarm 'Some hosts do not support stretched cluster'",`
"Virtual SAN Health Alarm 'Stretched cluster health'",`
"Virtual SAN Health Alarm 'Stretched cluster with no disk mapping witness host'",`
"Virtual SAN Health Alarm 'Stretched cluster without a witness host'",`
"Virtual SAN Health Alarm 'Unexpected Virtual SAN cluster members'",`
"Virtual SAN Health Alarm 'Virtual SAN CLOMD liveness'",`
"Virtual SAN Health Alarm 'Virtual SAN cluster partition'",`
"Virtual SAN Health Alarm 'Virtual SAN HCL DB up-to-date'",`
"Virtual SAN Health Alarm 'Virtual SAN HCL health'",`
"Virtual SAN Health Alarm 'Virtual SAN Health Service up-to-date'",`
"Virtual SAN Health Alarm 'Virtual SAN object health'",`
"Virtual SAN Health Alarm 'Witness host inside one of the fault domain'",`
"Virtual SAN Health Alarm 'Witness host part of cluster'",`
"Virtual SAN Health Alarm 'Witness host with invalid preferred fault domain'",`
"Virtual SAN Health Alarm 'Witness host with non-existing fault domain'",`
"Virtual SAN Health Service Alarm for Overall Health Summary",`
"Errors occurred on the disk(s) of a Virtual SAN host",`
"VM storage compliance alarm",`
"VMKernel NIC not configured correctly",`
"VMware Common Logging Service Health Alarm",`
"VMware System and Hardware Health Manager Service Health Alarm",`
"VMware vAPI Endpoint Service Health Alarm",`
"VMware vFabric Postgres Service Health Alarm",`
"VMware vSphere ESXi Dump Collector Health Alarm",`
"VMware vSphere Profile-Driven Storage Service Health Alarm",`
"vService Manager Health Alarm",`
"vSphere APIs for IO Filtering (VAIO) Filter Management Operations",`
"vSphere Client Health Alarm",`
"vSphere Distributed Switch MTU matched status",`
"vSphere Distributed Switch MTU supported status",`
"vSphere Distributed Switch teaming matched status",`
"vSphere Distributed Switch VLAN trunked status",`
"vSphere HA VM Component Protection could not power off a virtual machine",`
"vSphere vCenter Host Certificate Management Mode"


#----These Alarms will repeat every 4 hours----
$MediumPriorityAlarms="Cannot find vSphere HA master agent",`
"Datastore usage on disk",`
"Health status changed alarm",`
"Host CPU usage",`
"Host memory usage",`
"Host service console swap rates",`
"Virtual machine error",`
"vSphere HA host status",`
"vSphere HA virtual machine monitoring action",`
"vSphere HA virtual machine monitoring error"

#----These Alarms will repeat every 1 hour----
$HighPriorityAlarms="Cannot connect to storage",`
"Datastore cluster is out of space",`
"Host connection and power state",`
"Host connection failure",`
"Host error",`
"Host hardware fan status",`
"Host hardware power status",`
"Host hardware system board status",`
"Host hardware temperature status",`
"Host hardware voltage",`
"Host memory status",`
"Host processor status",`
"Host storage status",`
"Network connectivity lost",`
"Network uplink redundancy degraded",`
"Network uplink redundancy lost",`
"Status of other host hardware objects",`
"Thin-provisioned volume capacity threshold exceeded",`
"Timed out starting Secondary VM",`
"vSphere HA failover in progress",`
"vSphere HA virtual machine failover failed"


#---Set Alarm Action for Low Priority Alarms---
Foreach ($LowPriorityAlarm in $LowPriorityAlarms) 
{
    Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
    Set-AlarmDefinition "$LowPriorityAlarm" -ActionRepeatMinutes (60 * 24) # 24 Hours
    Get-AlarmDefinition -Name "$LowPriorityAlarm" | New-AlarmAction -Email -To @($MailtoAddresses)  -Subject "$emailSubject" -Body "$emailHeader $emailContents $emailFooter"
    Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
	Start-Sleep -s 1  # One second pause added to allow New-AlarmAction to complete
    Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | Get-AlarmActionTrigger | Select -First 1 | Remove-AlarmActionTrigger -Confirm:$false
    Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" -Repeat
    Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
    Get-AlarmDefinition -Name "$LowPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}

#---Set Alarm Action for Medium Priority Alarms---
Foreach ($MediumPriorityAlarm in $MediumPriorityAlarms) {
    Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
    Set-AlarmDefinition "$MediumPriorityAlarm" -ActionRepeatMinutes (60 * 4) # 4 Hours
    Get-AlarmDefinition -Name "$MediumPriorityAlarm" | New-AlarmAction -Email -To @($MailtoAddresses) -Subject "$emailSubject" -Body "$emailHeader $emailContents $emailFooter"
    Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
    Start-Sleep -s 1  # One second pause added to allow New-AlarmAction to complete
	Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | Get-AlarmActionTrigger | Select -First 1 | Remove-AlarmActionTrigger -Confirm:$false
    Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" -Repeat
    Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
    Get-AlarmDefinition -Name "$MediumPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}

#---Set Alarm Action for High Priority Alarms---
Foreach ($HighPriorityAlarm in $HighPriorityAlarms) {
    Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
    Set-AlarmDefinition "$HighPriorityAlarm" -ActionRepeatMinutes (60 * 1) # 1 hour
    Get-AlarmDefinition -Name "$HighPriorityAlarm" | New-AlarmAction -Email -To @($MailtoAddresses) -Subject "$emailSubject" -Body "$emailHeader $emailContents $emailFooter"
	Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
	Start-Sleep -s 1  # One second pause added to allow New-AlarmAction to complete
    Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | Get-AlarmActionTrigger | Select -First 1 | Remove-AlarmActionTrigger -Confirm:$false
    Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" -Repeat
    Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
    Get-AlarmDefinition -Name "$HighPriorityAlarm" | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}

#--- Set thresholds for alarm triggers ---
#--- Should be in the format:  SetAlarmThresholds "Alarm Name" YellowThreshold RedThreshold
#--- 85% should be expressed as 8500
#--- E.g.  SetAlarmThresholds "Datastore usage on disk" 8500 9500
SetAlarmThresholds "Datastore usage on disk" 8500 9500
SetAlarmThresholds "Datastore cluster is out of space" 8500 9500
SetAlarmThresholds "Host CPU Usage" 8500 9500


#---Disconnect from vCenter Server----
Disconnect-VIServer -Server $vCenterServer -Force:$true -Confirm:$false