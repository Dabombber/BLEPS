Add-Type -ReferencedAssemblies "$PSScriptRoot\lib\WinRT.Runtime.dll", "$PSScriptRoot\lib\Microsoft.Windows.SDK.NET.dll" -TypeDefinition @'
	using System;
	using System.Threading.Tasks;
	using Windows.Devices.Enumeration;
	using Windows.Devices.Bluetooth;
	using Windows.Devices.Bluetooth.GenericAttributeProfile;
	using Windows.Storage.Streams;

	public class BLEPS
	{
		public static BluetoothAdapter GetBLEAdapter() {
			var t = BluetoothAdapter.GetDefaultAsync().AsTask();
			Task.WaitAll(t);
			return t.Result;
		}
		public static BluetoothAdapter GetBLEAdapter(string deviceId) {
			var t = BluetoothAdapter.FromIdAsync(deviceId).AsTask();
			Task.WaitAll(t);
			return t.Result;
		}

		public static DeviceInformationCollection GetBLEDeviceInformation(string selector) {
			var t = DeviceInformation.FindAllAsync(selector).AsTask();
			Task.WaitAll(t);
			return t.Result;
		}

		public static BluetoothLEDevice GetBLEDevice(string deviceId) {
			var t = BluetoothLEDevice.FromIdAsync(deviceId).AsTask();
			Task.WaitAll(t);
			return t.Result;
		}

		public static GattDeviceServicesResult GetBLEServices(ref BluetoothLEDevice device) {
			var t = device.GetGattServicesAsync().AsTask();
			Task.WaitAll(t);
			return t.Result;
		}
		public static GattDeviceServicesResult GetBLEServices(ref BluetoothLEDevice device, Guid serviceUuid) {
			var t = device.GetGattServicesForUuidAsync(serviceUuid).AsTask();
			Task.WaitAll(t);
			return t.Result;
		}

		public static GattCharacteristicsResult GetBLECharacteristics(ref GattDeviceService service) {
			var t = service.GetCharacteristicsAsync().AsTask();
			Task.WaitAll(t);
			return t.Result;
		}
		public static GattCharacteristicsResult GetBLECharacteristics(ref GattDeviceService service, Guid characteristicUuid) {
			var t = service.GetCharacteristicsForUuidAsync(characteristicUuid).AsTask();
			Task.WaitAll(t);
			return t.Result;
		}
		public static GattReadResult ReadBLECharacteristics(ref GattCharacteristic characteristic) {
			var t = characteristic.ReadValueAsync().AsTask();
			Task.WaitAll(t);
			return t.Result;
		}
		public static GattWriteResult WriteBLECharacteristics(ref GattCharacteristic characteristic, IBuffer value, GattWriteOption writeOption) {
			var t = characteristic.WriteValueWithResultAsync(value, writeOption).AsTask();
			Task.WaitAll(t);
			return t.Result;
		}

		public static GattDescriptorsResult GetBLEDescriptor(ref GattCharacteristic characteristic) {
			var t = characteristic.GetDescriptorsAsync().AsTask();
			Task.WaitAll(t);
			return t.Result;
		}
		public static GattDescriptorsResult GetBLEDescriptor(ref GattCharacteristic characteristic, Guid descriptorUuid) {
			var t = characteristic.GetDescriptorsForUuidAsync(descriptorUuid).AsTask();
			Task.WaitAll(t);
			return t.Result;
		}
	}
'@


function Get-BLEAdapter {
	[OutputType([Windows.Devices.Bluetooth.BluetoothAdapter])]
	[CmdletBinding(DefaultParameterSetName='Default')]
	param(
		# DeviceID string for the adapter to use.
		[Parameter(Mandatory=$true, Position=0, ParameterSetName='ByDeviceID')]
		[string] $DeviceID,

		# Retrieve all Bluetooth adapters present on the system.
		[Parameter(Mandatory=$true, ParameterSetName='All')]
		[switch] $All
	)

	process {
		if ($PSCmdlet.ParameterSetName -eq 'ByDeviceID') {
			[BLEPS]::GetBLEAdapter($DeviceID)
		} elseif ($PSCmdlet.ParameterSetName -eq 'All' -and $All) {
			$selector = [Windows.Devices.Bluetooth.BluetoothAdapter]::GetDeviceSelector()
			[BLEPS]::GetBLEDeviceInformation($selector) | ForEach-Object { [BLEPS]::GetBLEDevice($_.Id) }
		} else {
			[BLEPS]::GetBLEAdapter()
		}
	}
}

function Get-BLEDevice {
	[OutputType([Windows.Devices.Bluetooth.BluetoothLEDevice])]
	[CmdletBinding(DefaultParameterSetName='All')]
	param(
		# The device's appearance.
		[Parameter(Mandatory=$true, Position=0, ParameterSetName='ByAppearance')]
		[Windows.Devices.Bluetooth.BluetoothLEAppearance] $Appearance,

		# The device's address, expressed as an unsigned long integer (uint64).
		[Parameter(Mandatory=$true, Position=0, ParameterSetName='ByAddress')]
		[UInt64] $BluetoothAddress,

		# The device's connection status.
		[Parameter(Mandatory=$true, Position=0, ParameterSetName='ByConnectionStatus')]
		[Windows.Devices.Bluetooth.BluetoothConnectionStatus] $ConnectionStatus,

		# The device's friendly name.
		[Parameter( Mandatory=$true, Position=0, ParameterSetName='ByDeviceName')]
		[string] $DeviceName,

		# The device's pairing state. A true value indicates the device is paired.
		[Parameter(Mandatory=$true, ParameterSetName='ByPairingState')]
		[switch] $PairingState
	)

	process {
		# Find the right AQS selector to use for our parameter set
		$selector = switch ($PSCmdlet.ParameterSetName) {
			'All' {
				[Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelector()
			}
			'ByAppearance' {
				[Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromAppearance($Appearance)
			}
			'ByAddress' {
				[Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromBluetoothAddress($BluetoothAddress)
			}
			'ByConnectionStatus' {
				[Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromConnectionStatus($ConnectionStatus)
			}
			'ByDeviceName' {
				[Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromDeviceName($DeviceName)
			}
			'ByPairingState' {
				[Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromPairingState($PairingState)
			}
		}

		[BLEPS]::GetBLEDeviceInformation($selector) | ForEach-Object { [BLEPS]::GetBLEDevice($_.Id) }
	}
}

function Get-BLEService {
	[OutputType([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceService])]
	[CmdletBinding()]
	param(
		# A pre-existing BluetoothLEDevice object
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[Windows.Devices.Bluetooth.BluetoothLEDevice[]] $InputObject,

		# The UUID of a target service
		[Parameter(Mandatory=$false)]
		[guid] $ServiceUuid
	)

	process {
		$services = $InputObject | ForEach-Object {
			if ($null -ne $ServiceUuid) {
				[BLEPS]::GetBLEServices([ref]$_, $ServiceUuid)
			} else {
				[BLEPS]::GetBLEServices([ref]$_)
			}
		}

		$services | ForEach-Object {
			if ($_.Status -ne 'Success') {
				Write-Error "Received error status $($_.Status) from GetGattServicesAsync()"
			} else {
				$_.Services
			}
		}
	}
}

function Get-BLECharacteristic {
	[OutputType([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic])]
	[CmdletBinding()]
	param(
		# A pre-existing BluetoothLEDevice object
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceService[]] $InputObject,

		# The UUID of a target characteristic
		[Parameter(Mandatory=$false)]
		[guid] $CharacteristicUuid
	)

	process {
		$characteristics = $InputObject | ForEach-Object {
			If ($null -ne $CharacteristicUuid) {
				[BLEPS]::GetBLECharacteristics([ref]$_, $CharacteristicUuid)
			} Else {
				[BLEPS]::GetBLECharacteristics([ref]$_)
			}
		}

		$characteristics | ForEach-Object {
			if ($_.Status -ne 'Success') {
				Write-Error "Received error status $($_.Status) from GetCharacteristicsAsync()"
			} else {
				$_.Characteristics
			}
		}
	}
}

function Read-BLECharacteristic {
	[Alias('Get-BLECharacteristicData')]
	[CmdletBinding()]
	param(
		# The characteristic to read from.
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic[]] $InputObject,

		# Return data as a stream (System.IO.Stream) instead of a byte array.
		[Parameter(Mandatory=$false)]
		[switch] $AsStream
	)

	begin {
		if ($asStream) {
			$BufferConversionMethod = 'AsStream'
		} else {
			$BufferConversionMethod = 'ToArray'
		}

		$BufferConverter = [System.Runtime.InteropServices.WindowsRuntime.WindowsRuntimeBufferExtensions].GetMethod(
			$BufferConversionMethod,
			[type[]]@([Windows.Storage.Streams.IBuffer] )
		)
	}

	process {
		$values = $InputObject | ForEach-Object { [BLEPS]::ReadBLECharacteristics([ref]$_) }

		$values | ForEach-Object {
			if ($_.Status -ne 'Success') {
				Write-Error "Received error status $($_.Status) from ReadValueAsync()"
			} else {
				$BufferConverter.Invoke($null, @($_.Value))
			}
		}
	}

	end {}
}

function Write-BLECharacteristic {
	[Alias('Set-BLECharacteristicData')]
	[CmdletBinding()]
	param(
		# The characteristic to write to.
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic[]] $InputObject,

		# The data stream to retrieve data from.
		[Parameter(Mandatory=$true, Position=0, ParameterSetName='DataStream')]
		[Alias('Stream')]
		[System.IO.MemoryStream] $DataStream,

		# The byte array to retrieve data from.
		[Parameter(Mandatory=$true, Position=0, ParameterSetName='DataByteArray')]
		[Alias('Byte', 'ByteArray')]
		[byte[]] $DataByteArray,

		# The WinRT IBuffer to retrieve data from.
		[Parameter(Mandatory=$true, Position=0, ParameterSetName='DataBuffer')]
		[Alias('Buffer')]
		[Windows.Storage.Streams.IBuffer] $DataBuffer,

		# The WinRT IBuffer to retrieve data from.
		[Parameter(Mandatory=$true, Position=0, ParameterSetName='String')]
		[string] $String,

		[Parameter(Mandatory=$false, ParameterSetName='String')]
		[System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8,

		[Parameter(Mandatory=$false)]
		[Windows.Devices.Bluetooth.GenericAttributeProfile.GattWriteOption] $WriteOption = 'WriteWithResponse'
	)

	begin {
		# Convert data to an IBuffer if needed
		if ($PSCmdlet.ParameterSetName -eq 'DataByteArray') {
			Write-Verbose 'Converting data byte[] to IBuffer...'
			$DataBuffer = [System.Runtime.InteropServices.WindowsRuntime.WindowsRuntimeBufferExtensions]::AsBuffer($DataByteArray)
		} elseif ($PSCmdlet.ParameterSetName -eq 'DataStream') {
			Write-Verbose 'Converting data MemoryStream to IBuffer...'
			$DataBuffer = [System.Runtime.InteropServices.WindowsRuntime.WindowsRuntimeBufferExtensions]::GetWindowsRuntimeBuffer($DataStream)
		} elseif ($PSCmdlet.ParameterSetName -eq 'String') {
			Write-Verbose 'Converting data string to IBuffer...'
			$DataBuffer = [System.Runtime.InteropServices.WindowsRuntime.WindowsRuntimeBufferExtensions]::AsBuffer($Encoding.GetBytes($String))
		}
	}

	process {
		$results = $InputObject | ForEach-Object { [BLEPS]::WriteBLECharacteristics([ref]$_, $DataBuffer, $WriteOption) }

		$results | ForEach-Object {
			if ($_.Status -ne 'Success') {
				Write-Error "Received error status $($_.Status) from WriteValueWithResultAsync()"
			}
		}
	}

	end {}
}

function Get-BLEDescriptor {
	[CmdletBinding()]
	param(
		# The characteristic to retrieve descriptors for.
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic[]] $InputObject,

		# The UUID of a target descriptor
		[Parameter(Mandatory=$false)]
		[guid] $DescriptorGuid
	)

	process {
		$descriptors = $InputObject | ForEach-Object {
			if ($null -ne $DescriptorGuid) {
				[BLEPS]::GetBLEDescriptor([ref]$_, $DescriptorGuid)
			} else {
				[BLEPS]::GetBLEDescriptor([ref]$_)
			}
		}

		$descriptors | ForEach-Object {
			if ($_.Status -ne 'Success') {
				Write-Error "Received error status $($_.Status) from GetDescriptorsAsync()"
			} else {
				$_.Descriptors
			}
		}
	}
}

# Export our functions
Export-ModuleMember -Function @(
	'Get-BLEAdapter',
	'Get-BLEDevice',
	'Get-BLEService',
	'Get-BLECharacteristic',
	'Read-BLECharacteristic',
	'Write-BLECharacteristic',
	'Get-BLEDescriptor'
)
