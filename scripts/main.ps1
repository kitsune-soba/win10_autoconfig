Set-StrictMode -Version Latest
Start-Transcript -Path ("$PSScriptRoot\win10_autoconfig_$((Get-Date).ToString("yyyyMMdd-HHmmss")).log")

. .\functions.ps1

# OSを確認
$platform = [System.Environment]::OSVersion.Platform
$majorVersion = [System.Environment]::OSVersion.Version.Major
$onWindows10 = ($platform -eq [System.PlatformID]::Win32NT) -and ($majorVersion -eq 10)
if (!$onWindows10) {
	Write-Output "実行を中止します。（このスクリプトは Windows 10 で動作します。）"
	Stop-Transcript
	return
}

# winget がインストールされているか確認
if (!(Get-Command("winget"))) {
	Write-Output "実行を中止します。（winget がインストールされている必要があります。）"
	Stop-Transcript
	return
}

# 管理者権限を持っているか確認
$adminRights = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$adminRights) {
	Write-Output "実行を中止します。（管理者権限が必要です。）"
	Stop-Transcript
	return
}

# 実行前の意思確認
$answer = Read-Host(@"
!!!! IMPORTANT !!!!!
このスクリプトは、作者の個人的なニーズに基づいて Windows の設定を変更したり、ソフトウェアを追加/削除/停止したりします。
スクリプトに目を通して何が起こるかを理解しているのでなければ、このスクリプトを実行しないでください。
通常、あなたは実行する前に自身のニーズに合わせてスクリプトを編集する必要があります。
また、実行前にシステムをバックアップすることを推奨します。
作者は、このスクリプトを使用したことによる如何なる結果に対しても責任を負いません。
実行しますか？ [y/N]
"@)
if (!(meansYes($answer))) {
	Write-Output "実行を中止します。"
	Stop-Transcript
	return
}

# コンピュータ名を変更
$answer = Read-Host("コンピュータ名を変更しますか？ [y/N]")
if (meansYes($answer)) {
	$computerName = Read-Host("新しいコンピュータ名を入力してください")
	Rename-Computer -NewName $computerName -Force
}

# ==============================================================================
Write-Output "`n======== セキュリティおよびプライバシー ========"
# システムのプロパティ > リモート
SetEntry "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" "fAllowToGetHelp" DWord 0 # 「このコンピューターへのリモート アシスタンス接続を許可する」を無効化
# 設定 > システム > 通知とアクション
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" DWord 0 # 「ロック画面に通知を表示する」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" "LockScreenToastEnabled" DWord 0 # 「ロック画面に通知を表示する」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" DWord 0 # 「ロック画面にリマインダーと VoIP の着信を表示する」を無効化
# 設定 > プライバシー > 全般
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" DWord 0 # 「アプリのアクティビティに基づいてユーザーに併せた広告を表示するために、広告識別子の使用をアプリに許可します。（オフにすると ID がリセットされます。）」を無効化
RemoveEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Id" # 「アプリのアクティビティに基づいてユーザーに併せた広告を表示するために、広告識別子の使用をアプリに許可します。（オフにすると ID がリセットされます。）」を無効化
SetEntry "HKCU:\Control Panel\International\User Profile" "HttpAcceptLanguageOptOut" DWord 1 # 「Web サイトが言語リストにアクセスできるようにして、地域に適したコンテンツを表示する」を無効化
RemoveEntry "HKCU:\SOFTWARE\Microsoft\Internet Explorer\International" "AcceptLanguage" # 「Web サイトが言語リストにアクセスできるようにして、地域に適したコンテンツを表示する」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" DWord 0 # 「Windows 追跡アプリの起動を許可して、スタート画面と検索結果の質を向上する」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338393Enabled" DWord 0 # 「設定アプリでおすすめのコンテンツを表示する」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" DWord 0 # 「設定アプリでおすすめのコンテンツを表示する」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353696Enabled" DWord 0 # 「設定アプリでおすすめのコンテンツを表示する」を無効化
# 設定 > プライバシー > 診断 ＆ フィードバック
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" Dword 0 # 「エクスペリエンス調整」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" Dword 0 # 「フィードバックの間隔」を「常にオフ」に設定
# 設定 > プライバシー > アプリのアクセス許可（の各項目）
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" String "Deny" # 「このデバイスの位置情報はオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" "Value" String "Deny" # 「このデバイスのカメラへのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" "Value" String "Deny" # 「このデバイスのマイクへのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation" "Value" String "Deny" # 「このデバイスのアカウント情報へのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts" "Value" String "Deny" # 「このデバイスの連絡先へのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments" "Value" String "Deny" # 「このデバイスのカレンダーへのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCall" "Value" String "Deny" # 「このデバイスの通話アクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory" "Value" String "Deny" # 「このデバイスの通話履歴へのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email" "Value" String "Deny" # 「このデバイスの電子メールへのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks" "Value" String "Deny" # 「このデバイスのタスクへのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\chat" "Value" String "Deny" # 「このデバイスのメッセージングへのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios" "Value" String "Deny" # 「このデバイスの無線制御アクセスはオフになっています」に設定
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync" "Value" String "Deny" # 「ペアリングされていないデバイスとの通信」をオフに設定
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" DWord 1 # 「アプリのバックグラウンド実行を許可する」をオフに設定
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BackgroundAppGlobalToggle" DWord 0 # 「アプリのバックグラウンド実行を許可する」をオフに設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" "Value" String "Deny" # 「このデバイスのアプリ診断情報へのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary" "Value" String "Deny" # 「このデバイスのドキュメント ライブラリへのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary" "Value" String "Deny" # 「このデバイスのピクチャ ライブラリへのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary" "Value" String "Deny" # 「このデバイスのビデオ ライブラリへのアクセスはオフになっています」に設定
SetEntry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\broadFileSystemAccess" "Value" String "Deny" # 「このデバイスのファイル システムへのアクセスはオフになっています」に設定

# ==============================================================================
Write-Output "`n======== UI ========"
# コントロール パネル
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" "StartupPage" DWord 1 # 「表示方法:」を「小さいアイコン」に設定
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" "AllItemsIconView" DWord 1 # 「表示方法:」を「小さいアイコン」に設定
# フォルダー オプション > 全般
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" DWord 1 # 「エクスプローラーで開く」を「PC」に設定
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" DWord 0 # 「最近使ったファイルをクイック アクセスに表示する」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowFrequent" DWord 0 # 「よく使うフォルダーをクイック アクセスに表示する」を無効化
# フォルダー オプション > 表示
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "AutoCheckSelect" DWord 0 # 「チェックボックスを使用して項目を選択する」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" DWord 1 # 「隠しファイル、隠しフォルダー、および隠しドライブを表示する」を有効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "IconsOnly" DWord 1 # 「常にアイコンを表示し、縮小版は表示しない」を有効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideDrivesWithNoMedia" DWord 0 # 「空のドライブは表示しない」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" DWord 0 # 「登録されている拡張子は表示しない」を無効化
# 設定 > 個人用設定 > 背景
SetEntry "HKCU:\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" "BackgroundType" DWord 1 # 「背景」を「単色」に設定
SetEntry "HKCU:\Control Panel\Desktop" "WallPaper" String "" # 「背景」を「単色」に設定
SetEntry "HKCU:\Control Panel\Colors" "Background" String "74 84 89" # 「背景色の選択」を「ダークグレー」に設定
# 設定 > 個人用設定 > 色
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" DWord 0 # 「色を選択する」を「ダーク」に設定
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" DWord 0 # 「色を選択する」を「ダーク」に設定
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" DWord 0 # 「透明効果」を無効化
SetEntry "HKCU:\Control Panel\Desktop" "AutoColorization" DWord 0 # 「背景から自動的にアクセント カラーを選ぶ」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\DWM" "ColorPrevalence" DWord 1 # 「タイトル バーとウィンドウの境界線」を有効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "ColorPrevalence" DWord 0 # 「スタート メニュー、タスク バー、アクション センター」を無効化（アクセントカラーを表示しない）
# 設定 > 個人用設定 > タスクバー
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarSmallIcons" DWord 1 # 「小さいタスク バー ボタンを使う」を有効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "DisablePreviewDesktop" DWord 1 # 「タスク バーの端にある [デスクトップの表示] ボタンにマウスカーソルを置いたときに、プレビューを使用してデスクトップをプレビューする」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarGlomLevel" DWord 2 # 「タスク バー ボタンを結合する」を「結合しない」に設定
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "EnableAutoTray" DWord 0 # タスク バーに表示するアイコンを選択します > 「常にすべてのアイコンを通知領域に表示する」を有効化
# タスクバーのコンテキストメニュー
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" DWord 0 # 「タスク ビュー ボタンを表示」を無効化

# ==============================================================================
Write-Output "`n======== キーボードとマウス ========"
# コントロール パネル > キーボード > 速度
SetEntry "HKCU:\Control Panel\Keyboard" "KeyboardDelay" String 0 # 「表示までの待ち時間」を最短に設定 [0（短）, 1, 2, 3（長）]
# コントロール パネル > マウス > ボタン
SetEntry "HKCU:\Control Panel\Mouse" "DoubleClickSpeed" String 200 # 「ダブルクリックの速度」を最速にする
# 設定 > 時刻と言語 > 言語 > （優先する言語内の）日本語 > オプション > レイアウトを変更する > 「ハードウェア キーボード レイアウトの変更」を「英語キーボード(101/102キー) に設定」（日本語環境の Windows でUS配列キーボードを使うための設定）
#SetEntry "HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters" "LayerDriver JPN" String "kbd101.dll"
#SetEntry "HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters" "OverrideKeyboardIdentifier" String "PCAT_101KEY"
#SetEntry "HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters" "OverrideKeyboardSubtype" DWord 0
#SetEntry "HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters" "OverrideKeyboardType" DWord 7
# 設定 > 時刻と言語 > 言語 > （優先する言語内の）日本語 > オプション > （キーボード内の）Microsoft IME > オプション > キーとタッチのカスタマイズ
SetEntry "HKCU:\SOFTWARE\Microsoft\IME\15.0\IMEJP\MSIME" "IsKeyAssignmentEnabled" DWord 1 # 「各キーに好みの機能を割り当てる」を有効化
SetEntry "HKCU:\SOFTWARE\Microsoft\IME\15.0\IMEJP\MSIME" "KeyAssignmentCtrlSpace" DWord 2 # 「Ctrl + Space」を「IME-オン/オフ」に設定
# （GUIの設定項目なし）マウスポインタの加速を無効化
SetEntry "HKCU:\Control Panel\Mouse" "MouseSpeed" String 0
SetEntry "HKCU:\Control Panel\Mouse" "MouseThreshold1" String 0
SetEntry "HKCU:\Control Panel\Mouse" "MouseThreshold2" String 0
# （GUIの設定項目なし）左 Ctrl と Caps Lock を入れ替える
#SetEntry "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" "Scancode Map" Binary ([byte[]](`
#	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, `
#	0x03, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x3a, 0x00, `
#	0x3a, 0x00, 0x1d, 0x00, 0x00, 0x00, 0x00, 0x00))

# ==============================================================================
Write-Output "`n======== 動作の安定性 ========"
# コントロール パネル > 電源オプション > 電源ボタンの動作を選択する
SetEntry "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" DWord 0 # 「高速スタートアップを有効にする（推奨）」を無効化

# ==============================================================================
Write-Output "`n======== パフォーマンス ========"
# フォルダー オプション > 検索
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Search\Preferences" "WholeFileSystem" DWord 1 # ファイル・フォルダの検索にインデックスを使用しない
# システムのプロパティ > 詳細設定 > （パフォーマンスの）設定 > 詳細設定 > （仮想メモリの）変更
SetEntry "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PagingFiles" MultiString "" # 全てのドライブを「ページング ファイルなし」に設定

# ==============================================================================
Write-Output "`n======== 不要な機能の停止 ========"
# 設定 > システム > 通知とアクション
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-310093Enabled" DWord 0 # 「新機能とおすすめを確認するために、更新の後と、サインイン時にときどき、[Windows へようこそ] の情報を表示する」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" DWord 0 # 「Windows 最大限に活用するためのデバイス設定の完了方法を提案する」を無効化
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" DWord 0 # 「Windows を使う上でのヒントやお勧めの方法を取得する」を無効化
# 設定 > 個人用設定 > ロック画面
SetEntry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenOverlayEnabled" DWord 0 # 「ロック画面に、Windows と Cortana のトリビアやヒントなどの情報を表示する」を無効化

# ==============================================================================
Write-Output "`n======== ソフトウェアのインストール ========"
# MyDocuments/shortcuts ディレクトリを作ってパスを通す。
# このディレクトリにインストールされたソフトウェアのショートカットが作られ、ターミナルから起動できるようになる。
$shortcuts = [System.Environment]::GetFolderPath("MyDocuments") + "\shortcuts"
if (!(Test-Path($shortcuts))) { New-Item $shortcuts -type Directory | Out-Null }
AddUserPath($shortcuts)

# CLI
InstallSoftware "Microsoft.PowerShell"
InstallSoftware "Microsoft.WindowsTerminal" # インストールした時点でパスが通っている（起動コマンド：wt）
# 開発/制作
#InstallSoftware "Git.Git" # インストールした時点でパスが通っている（起動コマンド：git）
#InstallSoftware "Microsoft.VisualStudioCode"  # インストールした時点でパスが通っている（起動コマンド：code）
#InstallSoftware "Microsoft.VisualStudio.2022.Community" "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe", $shortcuts, "vs2022"
#InstallSoftware "UnityTechnologies.UnityHub" "C:\Program Files\Unity Hub\Unity Hub.exe" $shortcuts "unity"
#InstallSoftware "BlenderFoundation.Blender" # 実行ファイルのパスにバージョン番号が含まれるため起動コマンドの作成は諦める（アップデートでショートカットのリンクが切れる）
#InstallSoftware "GIMP.GIMP" # 実行ファイルのパスにバージョン番号が含まれるため起動コマンドの作成は諦める（アップデートでショートカットのリンクが切れる）
# メディア再生
#InstallSoftware "VideoLAN.VLC" "C:\Program Files\VideoLAN\VLC\vlc.exe" $shortcuts "vlc"
#InstallSoftware "PeterPawlowski.foobar2000" "C:\Program Files (x86)\foobar2000\foobar2000.exe" $shortcuts "fb2k"
#InstallSoftware "AndreWiethoff.ExactAudioCopy" "C:\Program Files (x86)\Exact Audio Copy\EAC.exe" $shortcuts "eac"
# その他
InstallSoftware "7zip.7zip" "C:\Program Files\7-Zip\7z.exe" $shortcuts "7z"
InstallSoftware "Notepad++.Notepad++" "C:\Program Files\Notepad++\notepad++.exe" $shortcuts "npp"
InstallSoftware "VivaldiTechnologies.Vivaldi" "$([System.Environment]::GetFolderPath("LocalApplicationData"))\Vivaldi\Application\vivaldi.exe" $shortcuts "vivaldi"
#InstallSoftware "ClawsMail.ClawsMail" "C:\Program Files\Claws Mail\claws-mail.exe" $shortcuts "claws" SetClawsMailToDarkTheme
#InstallSoftware "IDRIX.VeraCrypt" "C:\Program Files\VeraCrypt\VeraCrypt.exe" $shortcuts "vera"
#InstallSoftware "Dropbox.Dropbox"

# ==============================================================================
Write-Output "`n======== サービスを停止・無効化 ========"
# リソース節約のために停止する
StopAndDisableService("SysMain") # 使用頻度の高いプログラムを予めメモリ上にロードする
StopAndDisableService("WSearch") # 検索インデックス
StopAndDisableService("fhsvc") # ファイル履歴
# セキュリティリスク低減のために停止する
StopAndDisableService("AxInstSV") # ActiveX インストーラ
# 不要なため停止する
StopAndDisableService("Fax") # Fax
StopAndDisableService("RetailDemo") # 市販デモサービス
StopAndDisableService("WpcMonSvc") # 保護者による制限
# 他の色々なサービスを停止する。通常は実行しなくてよい。
#. .\extra.ps1; StopServicesNervously

# ==============================================================================
Write-Output "`n======== Windows の機能を無効化 ========"
DisableWindowsFeature("Internet-Explorer-Optional-amd64") # Internet Explorer 11
DisableWindowsFeature("MicrosoftWindowsPowerShellV2") # Windows PowerShell 2.0
DisableWindowsFeature("MicrosoftWindowsPowerShellV2Root") # Windows PowerShell 2.0
DisableWindowsFeature("Printing-Foundation-InternetPrinting-Client") # インターネット印刷クライアント
DisableWindowsFeature("SMB1Protocol-Deprecation") # SMB 1.0
DisableWindowsFeature("SMB1Protocol") # SMB 1.0
DisableWindowsFeature("SMB1Protocol-Client") # SMB 1.0
DisableWindowsFeature("SMB1Protocol-Server") # SMB 1.0
DisableWindowsFeature("WindowsMediaPlayer") # Windows Media Player

# ==============================================================================
Write-Output "`n======== ソフトウェアのアンインストール ========"
UninstallSoftware("LinkedIn")
UninstallSoftware("Disney+")
UninstallSoftware("Cortana")
UninstallSoftware("MSN 天気")
UninstallSoftware("問い合わせ")
UninstallSoftware("Microsoft ヒント")
UninstallSoftware("ペイント 3D")
UninstallSoftware("3D ビューアー")
UninstallSoftware("Microsoft Solitaire Collection")
UninstallSoftware("Office") # MicrosoftOfficeHub
UninstallSoftware("Microsoft 付箋")
UninstallSoftware("OneNote for Windows 10")
UninstallSoftware("Microsoft People")
UninstallSoftware("切り取り & スケッチ")
UninstallSoftware("Skype")
UninstallSoftware("Microsoft Pay")
UninstallSoftware("Windows アラーム & クロック")
UninstallSoftware("Windows カメラ")
UninstallSoftware("フィードバック Hub")
UninstallSoftware("Windows マップ")
UninstallSoftware("Windows ボイス レコーダー")
UninstallSoftware("Xbox TCUI") # Xbox 関連は、アンインストールすると Win + G による動画キャプチャが働かなくなるかも知れない（未確認）
UninstallSoftware("Xbox コンソール コンパニオン")
UninstallSoftware("Xbox Game Bar Plugin")
UninstallSoftware("Xbox Game Bar")
UninstallSoftware("Xbox Identity Provider")
UninstallSoftware("Xbox Game Speech Window")
UninstallSoftware("スマホ同期")
UninstallSoftware("Groove ミュージック")
UninstallSoftware("映画 & テレビ")
UninstallSoftware("Microsoft OneDrive")
UninstallSoftware("Spotify Music")
UninstallSoftware("メール/カレンダー")
UninstallSoftware("OneNote for Windows 10")

Write-Output("`n完了！`n")

# 再起動
$answer = Read-Host("再起動するまで一部の設定が反映されない可能性があります。`n今すぐ再起動しますか？ [y/N]")
Stop-Transcript
if (meansYes($answer)) { Restart-Computer }

# ==============================================================================
# TODO 本当はこれらも可能な範囲で自動化したい。
# 
# - 設定 > 更新とセキュリティ > Windows Update で、新しい更新が無くなるまで更新を繰り返す
# - ドライバをインストールする（グラボ等）
# - 設定 > 個人用設定 > スタート で不要な機能を全て無効化
# - 設定 > プライバシー > 手書き入力と入力の個人用設定 の「あなたに関する情報の収集」を無効化する
# - フォルダー オプション > 全般 > クリック方法 を「シングルクリックで選択肢、ダブルクリックで開く」に設定
# - コントロール パネル > マウス > ポインター オプション > 速度 の「ポンターの速度を選択する」を好きな速度に設定（端末によって設定したい値が異なるため敢えて自動化しない）
# - システムのプロパティ > 詳細設定 > （パフォーマンスの）設定 > 視覚効果 > カスタム で「スクリーン フォントの縁を滑らかにする」以外を全て無効化
# - タスク マネージャー > スタートアップ で不要なものを全て「無効」に設定する
# - タスク バーの位置や幅をいい感じにする
# - スタート メニュー内の不要なプリインストールアプリを削除し、全てのタイルを消し、幅を狭くする
# - エクスプローラの表示を常に「詳細」にして、表示する項目を適宜設定する
# - インストールされた Claws Mail 4.0.0-1 はそのままでは起動できない（msvcr100.dll が見つからない）ため、<https://www.microsoft.com/en-us/download/details.aspx?id=26999> から vcredist_x64.exe をダウンロード（英語版を選ばないとダメかも？未確認）してインストールする。
#   （なお、ここでインストールする Microsoft Visual C++ 2010 Service Pack 1 Redistributable Package MFC Security Update はサポートが終了しているようで、インストールされたままにしておきたくない場合は System32 内に作られた msvcr100.dll を ClawsMail のインストール先に移した後にアンインストールしてしまってよい。）
