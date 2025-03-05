# Description
The Inventory.ps1 script is designed to collect information about the computer on which it is executed and send this data in JSON format to a REST service. It gathers system data, including information about the CPU, memory, disks, monitors, network interfaces, installed applications, and printers.

### Features
System Information Collection: The script retrieves data about the processor, RAM, hard disks, monitors, network interfaces, printers, and installed software.
JSON Generation: The collected data is converted into JSON format for subsequent transmission.
Data Transmission: The JSON is sent to a specified REST service. Request parameters such as URL and access key are set within the script.
Manual Input Support: The script prompts the user to input the administrator login, user login, and screen diagonal.
Monitor Vendor Codes: Monitor vendor names may be retrieved as three-letter codes. A map for decoding these codes is attached to the project. However, due to the abundance of new Chinese brands, it may not be complete.

### Requirements
PowerShell 5.1
Internet access to send data to the REST service

### Usage
Ensure you have PowerShell 5.1 installed.
Configure the REST request parameters in the script, such as $accessKey and $serv.
Run the script in PowerShell.
Enter the requested information when prompted by the script (administrator login, user login, screen diagonal).
The script will generate a JSON file with system information and send it to the REST service.

###Notes
The script saves the JSON to the file C:\Temp\inventori.json for debugging purposes. This can be commented out if not needed.
The data transmission to the REST service is commented out for security. Uncomment the relevant block if you wish to send the data.
Ensure you have the necessary permissions to execute all commands and access the specified paths and services.

###Limitations
The map for decoding monitor vendor codes may be incomplete due to the presence of many new Chinese brands.
