# VM Data Extract Script
#
# v0.1 - Initial version incorporating Zerto script for WriteAvg Data


Write-Host ""
Write-Host -Foreground Yellow "****************** VM Data Extract Script *********************"
Write-Host -Foreground Yellow "Make sure statistics logging is set to at least level 2 for"
Write-Host -Foreground Yellow "all collection intervals.  vCenter should be allowed to collect"
Write-Host -Foreground Yellow "data for a minimum of 3 days before running this script."
Write-Host -Foreground Yellow "***************************************************************"

Write-Host ""
$vCenter = Read-Host "Enter vCenter Server name or IP"

Write-Host -Foreground Yellow "Connecting to $vCenter"
Write-Host -Foreground Yellow "You will be prompted for your vCenter credentials."

Connect-VIServer $vCenter

Write-Host -Foreground Yellow "Extracting Basic VM Configuration Information..."
Get-VM | Select Name, PowerState, NumCPU, MemoryGB, @{N="vCPUs";E={@($_.ExtensionData.config.Hardware.NumCPU[0])}}, @{N="Cores Per Socket";E={@($_.ExtensionData.config.Hardware.NumCoresPerSocket[0])}}, @{N="IP Address";E={@($_.guest.IPAddress[0])}}, @{N="VMwareToolsStatus";E={@($_.extensiondata.guest.ToolsStatus)}}, @{N="VM Hardware Ver";E={@($_.version)}}, @{N="GuestFullName";E={@($_.extensiondata.guest.GuestFullName)}}, @{N="Notes";E={@($_.notes)}}  | Export-CSV "VMConfigInfo.csv"

Write-Host -Foreground Yellow "Extracting VM Hard Disk Information..."
Get-VM | Get-HardDisk | %{IF($_.ExtensionData.ControllerKey -eq 200){$_ | Select @{N="VM";E={$_.Parent.Name}},@{N="vControllerType";E={"IDE"}},Name,@{N="Path";E={$_.Filename}},@{N="StorageFormat";E={$_.StorageFormat}},@{N="CapacityGB";E={$_.CapacityGB}}} elseif ($disk.ExtensionData.ControllerKey -ne 200) {$_ | Select @{N="VM";E={$_.Parent.Name}},@{N="vControllerType";E={"SCSI"}},Name,@{N="Path";E={$_.Filename}},@{N="StorageFormat";E={$_.StorageFormat}},@{N="CapacityGB";E={$_.CapacityGB}}}} | Export-CSV "VMDiskInfo.csv"

Write-Host -Foreground Yellow "Extracting VM Disk Write Statistics..."
$report = @()
	Get-VM | %{$stats = Get-Stat -Entity $_ -Stat disk.write.average -Start (Get-Date).adddays(-7) -ErrorAction SilentlyContinue
	if($stats){
	$statsGrouped = $stats | Group-Object -Property MetricId
	$row = "" | Select Name, CPU, MemoryGB, WriteAvgKBps, WriteAvgMBps
	$row.Name = $_.Name
    $row.CPU = $_.NumCPU
    $row.MemoryGB = $_.MemoryGB
	$row.WriteAvgKBps = ($statsGrouped | where {$_.Name -eq "disk.write.average"} | %{$_.Group | Measure-Object -Property Value -Average}).Average
	$row.WriteAvgMBps = $row.WriteAvgKBps/1024
	$row.WriteAvgKBps = "{0:N2}" -f $row.WriteAvgKbps
	$row.WriteAvgMBps = "{0:N2}" -f $row.WriteAvgMBps
	$report += $row
	}
}
$report | Export-Csv "VMDiskWriteStats.csv"

Write-Host -Foreground Yellow "Completed."