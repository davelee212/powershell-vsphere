#---- Redcentric vCenter Alerting Script ----#

$user="redvcloud\dave.lee"
$pass="Lightbulb23"
$vCenterServer="172.24.121.250"


#----Connect to the vCenter Server
Connect-VIServer -Server $vCenterServer -Protocol https -User $user -Password $pass -WarningAction SilentlyContinue | Out-Null

$sessionManager = Get-View -Id $global:DefaultVIServer.ExtensionData.Content.SessionManager
$sessionManager.SetLocale(“en-US”)

Set-VMHostAdvancedConfiguration -VMHost * -Name UserVars.SuppressShellWarning -Value 1

#---Disconnect from vCenter Server----
Disconnect-VIServer -Server $vCenterServer -Force:$true -Confirm:$false