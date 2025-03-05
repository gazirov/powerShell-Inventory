#asvinin
#script for powerShell 5.1
#script creates JSON with parameters of the PC on which it is running and then passes it to the REST module



#Main parameters of the REST request
$accessKey = ''
$serv='https://examlple.domen/sd/services/rest/exec-post'
$URL = "${serv}?accessKey=${accessKey}&func=modules.inventory.sendInventoryDataJson&params=requestContent,response"

# function to get WIN serial number
function Get-WindowsKey {
    param(
        [string]$path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\",
        [string]$digitalProductId = "DigitalProductId"
    )
    $regPath = $path + $digitalProductId

    $binaryKey = (Get-ItemProperty -Path $path).$digitalProductId
    $chars = "BCDFGHJKMPQRTVWXY2346789"
    $key = ""

    for ($i = 24; $i -ge 0; $i--) {
        $current = 0
        for ($j = 14; $j -ge 0; $j--) {
            $current = $current * 256 -bxor $binaryKey[$j]
            $binaryKey[$j] = [math]::Floor([double]($current / 24))
            $current = $current % 24
        }
        $key = $chars[$current] + $key
        if (($i % 5 -eq 0) -and ($i -ne 0)) {
            $key = "-" + $key
        }
    }

    return $key
}


# Getting memory information
$memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object BankLabel, @{Name="CapacityGB";Expression={[math]::round($_.Capacity/1GB,2)}}, Manufacturer, Speed, SerialNumber

# Getting information about disks
$diskInfo = Get-PhysicalDisk | Select-Object FriendlyName,  SerialNumber, MediaType, @{Name="size";Expression={[math]::round($_.Size/1GB,2)}}, HealthStatus

# Getting information about monitors
$monitor = Get-WmiObject -Namespace root\wmi -Class WMIMonitorID | Select-Object  @{Name="Vendor";Expression={[System.Text.Encoding]::ASCII.GetString($_.ManufacturerName).Replace("$([char]0x0000)","")}}, @{Name="model";Expression={[System.Text.Encoding]::ASCII.GetString($_.UserFriendlyName).Replace("$([char]0x0000)","")}}, @{Name="SerialNumber";Expression={[System.Text.Encoding]::ASCII.GetString($_.SerialNumberID).Replace("$([char]0x0000)","")}}  

# We receive information about 32-bit software
$soft = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
    Where-Object { $_.DisplayName -ne $null -or $_.DisplayVersion -ne $null -or $_.Publisher -ne $null } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
# We receive information about 64-bit software	
$soft +=  Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
  Where-Object { $_.DisplayName -ne $null -or $_.DisplayVersion -ne $null -or $_.Publisher -ne $null } |
  Select-Object DisplayName, DisplayVersion, Publisher , InstallDate

#Printer information 
$printers = Get-WmiObject -Query "SELECT * FROM Win32_Printer"

$printerInfo = $printers | Select-Object @{Name='Name';Expression={$_.Name}}, 
                                      @{Name='SerialNumber';Expression={$_.DeviceID}}, 
                                      @{Name='Comment';Expression={$_.Comment}}, 
                                      @{Name='PortName';Expression={$_.PortName}}

$printerInfo | ConvertTo-Json -Depth 3

#Network interfaces
$networkAdapters = Get-NetAdapter

$networkInfo = $networkAdapters | ForEach-Object {
    $ipAddresses = (Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex).IPAddress
    [PSCustomObject]@{
        Name         = $_.Name
        Description  = $_.InterfaceDescription
        MacAddress   = $_.MacAddress
        IPAddresses  = $ipAddresses
    }
}

$networkInfo | ConvertTo-Json -Depth 3


# parameters for manual input
$admin = Read-Host "Your Login"
$user = Read-Host "User Login"
$screenDiagonal = Read-Host "screen diagonal"


$systemInfo= @{
	
"cpu" = (gwmi win32_Processor).name 
"speed" = (gwmi win32_Processor).MaxClockSpeed
"cores" = (Get-WmiObject -Class Win32_Processor).NumberOfCores
"model" = (gwmi win32_computersystem).model 
"vendor" = (gwmi win32_computersystem).manufacturer
"sn" = (gwmi win32_bios).serialnumber
"OsVersion" = (Get-WmiObject -class Win32_OperatingSystem).Caption
"windowsKey" =  Get-WindowsKey

"ip" = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway -ne $null }).IPAddress | Select-Object -First 1
"mac" = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway -ne $null } | Select-Object -ExpandProperty MACAddress -First 1
"host" = $env:COMPUTERNAME
"classDev" = (Get-WmiObject -Class Win32_ComputerSystem).PCSystemType
"AuthorLogin" = $admin #Read-Host "Your Login"
"UserLogin" = $user #Read-Host "User Login"
"diagonal" = $screenDiagonal #Read-Host "screen diagonal ?"
"Creation date" = (Get-Date).ToString('dd.MM.yyyy HH:mm:ss')
}


# Creating an object with information sets
$combinedInfo = [PSCustomObject]@{
	
    Memory = @($memoryInfo)
    Disks = @($diskInfo)
	Monitors = @($monitor)
	soft = @($soft)
	printers = @($printerInfo) 
	network = @($networkInfo)
	info = $systemInfo
	
	}


# Converting an object to JSON
$jsonOutput = $combinedInfo | ConvertTo-Json -Depth 3 

# Output JSON to file, optional and can be commented
$jsonOutput | Out-File "C:\Temp\inventori.json" -Encoding UTF8

#Should be commented out if sending should be performed
exit

#We are correcting the encoding, there is a possibility that it needs to be disabled
$encodedData = [System.Text.Encoding]::GetEncoding("utf-8").GetBytes($jsonOutput)

#sending to REST service
$headers = @{
    "Content-type" = "application/json; charset=utf-8"
	
}

$response = Invoke-RestMethod -Uri $URL -Method POST -Headers $headers -Body $encodedData
$response