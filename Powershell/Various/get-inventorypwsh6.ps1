<#
.SYNOPSIS
Get Server Information
.DESCRIPTION
This script will get the CPU specifications, memory usage statistics, and OS configuration of any Server or Computer listed in ws.txt.
.NOTES  
The script will execute the commands on multiple machines sequentially using non-concurrent sessions. This will process all servers from ws.txt in the listed order.
The info will be exported to a csv format.
Requires: ws.txt must be created in the same folder where the script is.
File Name  : get-inventory.ps1
Author: Nikolay Petkov
Added HDD info, Ivan, 26 Jan 2017
Script Modified 
http://power-shell.com/
#>
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
#Get the server list
$servers = Get-Content .\ws.txt
#Run the commands for each server in the list
$infoColl = @()
Foreach ($s in $servers)
{
	#GET HDD Info - The data will be shown in a table as MB, rounded to the nearest second decimal.
	$HDD = Invoke-Command -ComputerName $s {Get-PSDrive C} | Select-Object PSComputerName,Used,Free | Measure-Object -Property Used,Free -sum | %  {[Math]::Round(($_.sum / 1GB), 2)}
#####	$HDD = Get-PSDrive C | Select-Object Used,Free | Measure-Object -Property Used,Free -sum | %  {[Math]::Round(($_.sum / 1GB), 2)} 
	$HDDFree = Invoke-Command -ComputerName $s {Get-PSDrive C} | Select-Object Free | Measure-Object -Property Free -sum | %  {[Math]::Round(($_.sum / 1GB), 2)} 
	$HDDUsed = Invoke-Command -ComputerName $s {Get-PSDrive C} | Select-Object Used | Measure-Object -Property Used -sum | %  {[Math]::Round(($_.sum / 1GB), 2)}
	#$HDDTotal = Invoke-Command -ComputerName $s {Get-PSDrive C} | Select-Object Total | Measure-Object -Property Used -sum | %  {[Math]::Round(($_.sum / 1GB), 2)} 	
	$HDDTotal = Get-CimInstance -class Win32_LogicalDisk -ComputerName $s -Filter "DriveType=3" | Measure-Object -Property Size -Sum | % { [Math]::Round(($_.sum / 1GB), 2) }
	$HDDSerial = Get-CimInstance -ClassName win32_physicalmedia  -ComputerName $s | select -ExpandProperty Serialnumber 
	#$HDDTotalSize = Get-CimInstance -class Win32_LogicalDisk -ComputerName $s -Filter "DriveType=3" | Measure-Object -Property Size -Sum | % { [Math]::Round(($_.sum / 1GB), 2) }
	$CPUSerial = Get-CimInstance -class Win32_bios -ComputerName $s 
	$CPUInfo = Get-CimInstance Win32_Processor -ComputerName $s #Get CPU Information
	$OSInfo = Get-CimInstance Win32_OperatingSystem -ComputerName $s #Get OS Information
	#Get Memory Information. The data will be shown in a table as MB, rounded to the nearest second decimal.
	$OSTotalVirtualMemory = [math]::round($OSInfo.TotalVirtualMemorySize / 1MB, 2)
	$OSTotalVisibleMemory = [math]::round(($OSInfo.TotalVisibleMemorySize / 1MB), 2)
	$PhysicalMemory = Get-CimInstance CIM_PhysicalMemory -ComputerName $s | Measure-Object -Property capacity -Sum | % { [Math]::Round(($_.sum / 1GB), 2) }
	$ComputerModel = Get-CimInstance -Class Win32_ComputerSystem
	Foreach ($CPU in $CPUInfo)
	{
		$infoObject = New-Object PSObject
		#The following add data to the infoObjects.	
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "ServerName" -value $CPU.SystemName
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "Processor" -value $CPU.Name
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "Model" -value $CPU.Description
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "Manufacturer" -value $CPU.Manufacturer
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "PhysicalCores" -value $CPU.NumberOfCores
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_L2CacheSize" -value $CPU.L2CacheSize
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_L3CacheSize" -value $CPU.L3CacheSize
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "Sockets" -value $CPU.SocketDesignation
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "LogicalCores" -value $CPU.NumberOfLogicalProcessors
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Name" -value $OSInfo.Caption
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Version" -value $OSInfo.Version
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalPhysical_Memory_GB" -value $PhysicalMemory
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "Space_GB Free" -value $HDDFree
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "Space_GB Used" -value $HDDUsed
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalSpace_GB" -value $HDD.TotalSize
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalSpace_GB" -value $HDDTotal
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "HDDSerial" -value $HDDSerial
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPUSerial" -value $CPUSerial.SerialNumber
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalVirtual_Memory_MB" -value $OSTotalVirtualMemory
		#Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalVisable_Memory_MB" -value $OSTotalVisibleMemory
		Add-Member -inputObject $ComputerModel -memberType NoteProperty -name "Computer_Model" -value $ComputerModel
		$infoObject #Output to the screen for a visual feedback.
		$infoColl += $infoObject
	}
}
$infoColl | Export-Csv -path .\CBTD_Inventory_$((Get-Date).ToString('MM-dd-yyyy')).csv -NoTypeInformation #Export the results in csv file.
$StopWatch.Stop()
$StopWatch.Elapsed
