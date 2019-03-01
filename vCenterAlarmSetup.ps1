#---- Redcentric vCenter Alert Setup Script ----#
$user="redvcloud\dave.lee"   					  # Replace with username for connecting to the vCenter instance
$pass="Lightbulb23"        						  # Replace with password for connecting to the vCenter instance
$vCenterServer="172.24.121.250"					  # Replace with vCenter instance IP or DNS name
$mailserver = "172.24.66.12"					  # Replace with SMTP server instance IP or DNS name
$mailfromaddress = "rsh-rcvc-01@redvcloud.com"    # Email "from" field for sent alerts - set it to something we'll be able to recognise!
$MailtoAddresses= "dave.lee@redcentricplc.com"    # Email "to" field - probably either SMC or Server Management Groups
$vCenterDescription = "Hoddesdon Resource Cluster vCenter (172.24.121.250)"		  # Will go into email body

#--- Additional information to be added to the top of any emails that go out - can be blank if you don't want anything added
$emailHeader = "This alert has been raised by: $vCenterDescription`n"
$emailContents = "`nTarget: {targetName}`nPrevious Status: {oldStatus}`nNew Status: {newStatus}`n`nAlarm Definition:`n{declaringSummary}`n`nCurrent values for metric/state:`n{triggeringSummary}`n`nDescription:`n{eventDescription}`n"
$emailFooter = "`nFurther information dealing with these alerts can be found at https://insight.maxima.co.uk/sites/SAES/Engineering/Customers/Redstone%20Cloud%20Hoddesdon/"
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
Connect-VIServer -Server $vCenterServer -Protocol https -User $user -Password $pass -WarningAction SilentlyContinue | Out-Null

$sessionManager = Get-View -Id $global:DefaultVIServer.ExtensionData.Content.SessionManager
$sessionManager.SetLocale(“en-US”)

#---- The following will remove ALL email alerts on the vCenter so only uncomment this if that's what you want to do!
Get-AlarmDefinition | Get-AlarmAction -ActionType SendEmail | Remove-AlarmAction -Confirm:$false

#----Setup Mail Server Settings
Get-AdvancedSetting –Entity $vCenterServer –Name mail.smtp.sender | Set-AdvancedSetting –Value $mailfromaddress -Confirm:$false
Get-AdvancedSetting –Entity $vCenterServer –Name mail.smtp.server | Set-AdvancedSetting –Value $mailserver -Confirm:$false
Get-AdvancedSetting –Entity $vCenterServer –Name mail.smtp.port | Set-AdvancedSetting –Value 25 -Confirm:$false

#----These Alarms will repeat every 24 hours----
$LowPriorityAlarms="Timed out starting Secondary VM",`
#"No compatible host for Secondary VM",`
#"Virtual Machine Fault Tolerance vLockStep interval Status Changed",`
#"Migration error",`
#"Exit standby error",`
#"License error",`
#"Virtual machine Fault Tolerance state changed",`
#"VMKernel NIC not configured correctly",`
#"Unmanaged workload detected on SIOC-enabled datastore",`
#"Host IPMI System Event Log status",`
#"Host Baseboard Management Controller status",`
#"License user threshold monitoring",`
#"Datastore capability alarm",`
#"Storage DRS recommendation",`
#"Storage DRS is not supported on Host.",`
#"Datastore is in multiple datacenters",`
#"Insufficient vSphere HA failover resources",`
#"License capacity monitoring",`
#"Pre-4.1 host connected to SIOC-enabled datastore",`
"License inventory monitoring"

#----These Alarms will repeat every 4 hours----
$MediumPriorityAlarms="Virtual machine error",`
#"Health status changed alarm",`
#"Host cpu usage",`
#"Health status monitoring",`
#"Host memory usage",`
#"Cannot find vSphere HA master agent",`
#"vSphere HA host status",`
#"Host service console swap rates",`
#"vSphere HA virtual machine monitoring action",`
#"vSphere HA virtual machine monitoring error",
"Datastore usage on disk"

#----These Alarms will repeat every 1 hour----
$HighPriorityAlarms="Host connection and power state",`
#"Host processor status",`
#"Host memory status",`
#"Host hardware fan status",`
#"Host hardware voltage",`
#"Host hardware temperature status",`
#"Host hardware power status",`
#"Host hardware system board status",`
#"Host battery status",`
#"Status of other host hardware objects",`
#"Host storage status",`
#"Host error",`
#"Host connection failure",`
#"Cannot connect to storage",`
#"Network connectivity lost",`
#"Network uplink redundancy lost",`
#"Network uplink redundancy degraded",`
#"Thin-provisioned volume capacity threshold exceeded.",`
#"Datastore cluster is out of space",`
#"vSphere HA failover in progress",`
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