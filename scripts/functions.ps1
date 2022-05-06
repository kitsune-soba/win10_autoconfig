# [y/N] に対して y が入力されたか確認する
function meansYes([string]$answer) {
	return ($answer -eq "y") -or ($answer -eq "Y")
}

# レジストリのエントリの情報を取得する
function GetEntry([string]$key, [string]$entry) {
	$keyExist = $entryExist = $false
	$type = $value = $null

	$keyItem = Get-Item -Path $key -ErrorAction SilentlyContinue
	if ($null -ne $keyItem) {
		$keyExist = $true

		if ($keyItem.GetValueNames().Contains($entry)) {
			$entryExist = $true
			$type = $keyItem.GetValueKind($entry)
			$value = $keyItem.GetValue($entry, "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
		}
	}

	return $keyExist, $entryExist, $type, $value
}

# レジストリのエントリを設定する
function SetEntry([string]$key, [string]$entry, [Microsoft.Win32.RegistryValueKind]$type, $value) {
	$keyExist, $entryExist, $originalType, $originalValue = GetEntry $key $entry
	$sameEntry = ($type -eq $originalType) -and ([string]$value -eq [string]$originalValue) # 値が配列の場合でも比較できるように、文字列に変換して比較する

	# エントリを設定
	$entryString = "[key=$key, entry=$entry, type=$type, value=$value]"
	if (!$keyExist) {
		# 指定されたキーが存在しないため、キーとエントリを新規作成する
		Write-Output "New key/entry: $entryString"
		New-Item -Path $key -Force | Out-Null
		New-ItemProperty -Path $key -Name $entry -PropertyType $type -Value $value | Out-Null
	}
	elseif (!$entryExist) {
		# 指定されたエントリが存在しないため、エントリを新規作成する
		Write-Output "New entry:     $entryString"
		New-ItemProperty -Path $key -Name $entry -PropertyType $type -Value $value | Out-Null
	}
	elseif (!$sameEntry){
		# 指定されたエントリは存在するが型および/または値が指定されたものと異なるため、エントリを変更する
		Write-Output "Modify:        $entryString from [type=$originalType, value=$originalValue]"
		Set-ItemProperty -Path $key -Name $entry -Type $type -Value $value | Out-Null
	}
	else {
		# 既に希望通りのエントリが存在するため何もしない
		Write-Output "Skip:          $entryString"
	}
}

# レジストリのエントリを削除する
function RemoveEntry([string]$key, [string]$entry) {
	$keyExist, $entryExist, $type, $value = GetEntry $key $entry

	# エントリを削除
	if ($keyExist -and $entryExist)
	{
		# エントリを削除
		Write-Output "Remove:        [key=$key, entry=$entry, type=$type, value=$value]"
		Remove-ItemProperty -Path $key -Name $name
	} else {
		# キーまたはエントリが存在しないため何もしない
		Write-Output "Skip (Remove): [key=$key, entry=$entry]"
	}
}

# サービスを停止・無効化する
function StopAndDisableService([string]$name) {
	# サービスの情報を取得
	$service = Get-Service -Name $name -ErrorAction SilentlyContinue
	if ($null -ne $service) {
		$serviceName = $service.ServiceName
		$displayName = $service.DisplayName
		$canStop = $service.CanStop
		$disabled = $service.StartType -eq [System.ServiceProcess.ServiceStartMode]::Disabled
	}

	# サービスを停止・無効化
	if ($null -eq $service) {
		Write-Output "Not found:     $name"
	} elseif ($canStop -and !$disabled) {
		Write-Output "Stop, Disable: $serviceName ($displayName)"
		Stop-Service $service
		Set-Service -Name $serviceName -StartupType Disabled
	} elseif ($canStop) {
		Write-Output "Stop:          $serviceName ($displayName)"
		Stop-Service $service
	} elseif (!$disabled) {
		Write-Output "Disable:       $serviceName ($displayName)"
		Set-Service -Name $serviceName -StartupType Disabled
	} else {
		Write-Output "Skip:          $serviceName ($displayName)"
	}
}

# Windows の機能を無効化する
function DisableWindowsFeature([string]$featureName) {
	Write-Output "Disable `"$featureName`""
	Disable-WindowsOptionalFeature -Online -NoRestart -FeatureName $featureName
}

# ソフトウェアをインストールする
function InstallSoftware([string]$id, [string]$exePath = $null, [string]$shortcutsDirectory = $null, [string]$shortcutName = $null, $postEvent = $null) {
	Write-Output "Install $id ..."
	winget install --id $id -e -s winget
	$installed = $LastExitCode -eq 0

	# コマンドで起動できるようにショートカットを作成
	if ($installed -and !([string]::IsNullOrEmpty($exePath)) -and !([string]::IsNullOrEmpty($shortcutsDirectory)) -and !([string]::IsNullOrEmpty($shortcutName))) {
		Write-Output "Create shortcut command: $shortcutName"
		New-Item -ItemType SymbolicLink -Path $shortcutsDirectory -Name $shortcutName -Value $exePath -Force | Out-Null
	}

	if ($installed -and ($postEvent -ne $null)) {
		& $postEvent
	}

	Write-Output "----------------------------------------"
}

# ソフトウェアをアンインストールする
function UninstallSoftware([string]$name) {
	Write-Output "Uninstall $name ..."
	winget uninstall --name $name
}

# ユーザの環境変数PATHにパスを追加する
function AddUserPath([string]$fullPath) {
	$userPaths = [System.Environment]::GetEnvironmentVariable("PATH", "User")
	if ($userPaths.IndexOf($fullPath) -eq -1) {
		Write-Output "Add `"$fullPath`" to the `"Path`" user environment variable."
		[System.Environment]::SetEnvironmentVariable("PATH", $userPaths + ";" + $fullPath, "User")
	}
}

# Claws Mail をダークテーマにする
function SetClawsMailToDarkTheme() {
	$gtk3Settings = "$([System.Environment]::GetFolderPath("LocalApplicationData"))/gtk-3.0/settings.ini"
	if (Test-Path($gtk3Settings))
	{
		$answer = Read-Host("$gtk3Settings が既に存在します。Claws Mail をダークテーマに設定するために上書きしますか？ [y/N]")
		if (!(meansYes($answer))) { return }
	}

	# Claws Mail のインストール先にテーマを保存する
	$themeDestination = "C:/Program Files/Claws Mail/share/themes/Aritim-Dark-GTK"
	if (Test-Path($themeDestination)) { Remove-Item $themeDestination -Recurse }
	$tempDir = "$([System.Environment]::GetFolderPath("LocalApplicationData"))/Temp/aritim-dark"
	New-Item $tempDir -type Directory | Out-Null
	Invoke-WebRequest "https://github.com/Mrcuve0/Aritim-Dark/archive/refs/heads/master.zip" -Outfile "$tempDir/master.zip"
	Expand-Archive -Path "$tempDir/master.zip" -DestinationPath "$tempDir/master"
	Move-Item "$tempDir/master/Aritim-Dark-master/GTK" -Destination $themeDestination
	Remove-Item $tempDir -Recurse

	# ユーザの GTK3 テーマを設定する
	$utf8NoBom = New-Object System.Text.UTF8Encoding $False
	[System.IO.File]::WriteAllLines($gtk3Settings, "[Settings]`ngtk-theme-name=Aritim-Dark-GTK", $utf8NoBom) # Windows 10 に初めから入っている Windows PowerShell 5 でBOM無しUTF8を出力するため、このように書く
}
