<#
.SYNOPSIS
Get Server Information
.DESCRIPTION
This script will get the CPU specifications, memory usage statistics, and OS configuration of any Server or Computer listed in Serverlist.txt.
.NOTES  
The script will execute the commands on multiple machines sequentially using non-concurrent sessions. This will process all servers from Serverlist.txt in the listed order.
The info will be exported to a csv format.
Requires: wst.txt must be created in the same folder where the script is.
File Name  : get-inventory.ps1
Author: Nikolay Petkov
http://power-shell.com/
#>
#Get the server list
$servers = Get-Content .\wst.txt
#Run the commands for each server in the list
$infoColl = @()
Foreach ($s in $servers)
{
	$HDD = Get-WmiObject Win32_LogicalDisk -ComputerName $s -Filter "DriveType=3" | Measure-Object -Property Size -Sum | % { [Math]::Round(($_.sum / 1GB), 2) } #HDD info
	$HDDFS = Get-WmiObject Win32_LogicalDisk -ComputerName $s -Filter "DriveType=3" | Measure-Object -Property FreeSpace -Sum | % { [Math]::Round(($_.sum / 1GB), 2) } #HDD free space info
	$HDDSerial = Get-WmiObject Win32_PhysicalMedia -ComputerName $s
	$CPUInfo = Get-WmiObject Win32_Processor -ComputerName $s #Get CPU Information
	$CPUSerial = Get-WmiObject Win32_bios -ComputerName $s
	$OSInfo = Get-WmiObject Win32_OperatingSystem -ComputerName $s #Get OS Information
	#Get Memory Information. The data will be shown in a table as MB, rounded to the nearest second decimal.
	$OSTotalVirtualMemory = [math]::round($OSInfo.TotalVirtualMemorySize / 1MB, 2)
	$OSTotalVisibleMemory = [math]::round(($OSInfo.TotalVisibleMemorySize / 1MB), 2)
	$PhysicalMemory = Get-WmiObject CIM_PhysicalMemory -ComputerName $s | Measure-Object -Property capacity -Sum | % { [Math]::Round(($_.sum / 1GB), 2) }
	Foreach ($CPU in $CPUInfo)
	{
		$infoObject = New-Object PSObject
		#The following add data to the infoObjects.	
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "ServerName" -value $CPU.SystemName
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "Processor" -value $CPU.Name
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU Serial" -value $CPUSerial.SerialNumber
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "Model" -value $CPU.Description
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "Manufacturer" -value $CPU.Manufacturer
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "PhysicalCores" -value $CPU.NumberOfCores
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_L2CacheSize" -value $CPU.L2CacheSize
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_L3CacheSize" -value $CPU.L3CacheSize
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "Sockets" -value $CPU.SocketDesignation
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "LogicalCores" -value $CPU.NumberOfLogicalProcessors
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Name" -value $OSInfo.Caption
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Version" -value $OSInfo.Version
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "HDD Free Space" -value $HDDFS
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "HDD Size" -value $HDD
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "HDD Serial" -value $HDDSerial.SerialNumber
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalPhysical_Memory_GB" -value $PhysicalMemory
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalVirtual_Memory_MB" -value $OSTotalVirtualMemory
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalVisable_Memory_MB" -value $OSTotalVisibleMemory
		$infoObject #Output to the screen for a visual feedback.
		$infoColl += $infoObject
	}
}
$infoColl | Export-Csv -path .\Server_Inventory_$((Get-Date).ToString('MM-dd-yyyy')).csv -NoTypeInformation #Export the results in csv file.