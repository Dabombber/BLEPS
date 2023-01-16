@{
	RootModule = 'BLEPS.psm1'
	ModuleVersion = '1.1'
	CompatiblePSEditions = @('Core')
	GUID = 'e10ba87e-8d84-4f4e-80e3-e10252f42bd0'

	Author = 'Sean Williams'
	Copyright = '(c) 2019 Sean Williams. All rights reserved.'

	RequiredAssemblies = @(
		'lib\WinRT.Runtime.dll',
		'lib\Microsoft.Windows.SDK.NET.dll'
	)

	AliasesToExport = @()
	CmdletsToExport = @()
	FunctionsToExport = @(
		'Get-BLEAdapter',
		'Get-BLEDevice',
		'Get-BLEService',
		'Get-BLECharacteristic',
		'Read-BLECharacteristic',
		'Write-BLECharacteristic',
		'Get-BLEDescriptor'
	)
	VariablesToExport = @()

	PrivateData = @{
        PSData = @{
            ReleaseNotes = @'
## 1.1
- Switched to C++/WinRT to support PowerShell Core
- Functions explicity exported to support automatic loading
- 'Get-BLEAdapter -All' returns a BluetoothLEDevice(s) instead of a DeviceInformationCollection
- 'Get-BLEAdapter -All:$false' now returns the default adapter
- Added -String option to Write-BLECharacteristic
- CHanged Write-BLECharacteristic NoResponse switch to WriteOption setting

## 1.0
- Initial release
'@
        }
	}
}
