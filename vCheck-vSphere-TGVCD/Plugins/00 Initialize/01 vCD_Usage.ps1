$Title = "Organisation Summary"
$Header =  "Summary of utilisation per Organisation"
$Comments = "When setting up an OrgVDC the default CPU MHz allocation is 0.26 MHz this may impact the performance of VMs in this Org."
$Display = "Table"
$Author = "Dave Lee"
$Version = 1.0


Function Get-CIVMHardDisk {
Param (
[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
$CIVM
)
Process {
$AllHDD = $CIVM.ExtensionData.getvirtualhardwaresection().Item | Where { $_.Description -like “Hard Disk”}
$HDInfo = @()
Foreach ($HD in $AllHDD) {
$HD | Add-Member -MemberType NoteProperty -Name “Capacity” -Value $HD.HostResource[0].AnyAttr[0].”#text”
$HD | Add-Member -MemberType NoteProperty -Name “VMName” -Value $CIVM.Name
$HDInfo += $HD
}
$HDInfo
}

}

$allOrgs = Get-Org

foreach ($org in $allorgs)
{
  $PoweredVMs = $org | Get-CIVapp | Get-CIVM | Where {$_.Status -eq "PoweredOn"}
  $PoweredVMDisks = $PoweredVMs | Get-CIVMHardDisk
  $NonPoweredVMs = $org | Get-CIVapp | Get-CIVM | Where {$_.Status -ne "PoweredOn"}
  $NonPoweredVMDisks = $NonPoweredVMs | Get-CIVMHardDisk

  $org | Add-Member -MemberType NoteProperty -Name PoweredVMs -Value ($PoweredVMs | Measure).Count
  $org | Add-Member -MemberType NoteProperty -Name PoweredOn_CPUCount -Value ($PoweredVMs.CPUCount | Measure-Object -Sum).Sum
  $org | Add-Member -MemberType NoteProperty -Name PoweredOn_MemoryGB -Value ($PoweredVMs.MemoryGB | Measure-Object -Sum).Sum
  $org | Add-Member -MemberType NoteProperty -Name PoweredOn_DiskUsed -Value ($PoweredVMDisks.Capacity | Measure-Object -Sum).Sum

  $org | Add-Member -MemberType NoteProperty -Name NonPoweredVMs -Value ($NonPoweredVMs | Measure).Count
  $org | Add-Member -MemberType NoteProperty -Name NonPowered_CPUCount -Value ($NonPoweredVMs.CPUCount | Measure-Object -Sum).Sum
  $org | Add-Member -MemberType NoteProperty -Name NonPowered_MemoryGB -Value ($NonPoweredVMs.MemoryGB | Measure-Object -Sum).Sum
  $org | Add-Member -MemberType NoteProperty -Name NonPowered_DiskUsed -Value ($NonPoweredVMDisks.Capacity | Measure-Object -Sum).Sum
}

$allOrgs | Select Name, PoweredVMs, PoweredOn_CPUCount, POweredOn_MemoryGB, PoweredOn_DiskUsed, NonPoweredVMs, NonPowered_CPUCount, NonPowered_MemoryGB, NonPowered_DiskUsed