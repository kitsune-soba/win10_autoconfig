# 場合によって停止しても良さそうなサービスを神経質気味に停止する。
# 使い方が明確な端末でセキュリティ上の懸念を少しでも減らしたい場合や、極端にスペックの低い端末を気休め程度でも何とかしようと試みる場合以外は、これは実行しなくてよい。
# なお、Windows のサービスを網羅的に調査できているとは言い難く、サービスの選定が偏っている可能性がある。
function StopServicesNervously {
	# 無線LAN
	#StopAndDisableService("WlanSvc") # IEEE 802.11
	#StopAndDisableService("RmSvc") # 無線管理サービス
	# Bluetooth
	#StopAndDisableService("BluetoothUserService_*") # ワイルドカードを使えるか未確認
	#StopAndDisableService("BTAGService")
	#StopAndDisableService("bthserv")
	# 診断・エラーレポート
	StopAndDisableService("DiagTrack") # 診断情報や使用状況を収集して Microsoft に送る
	StopAndDisableService("WerSvc") # Windows Error Reporting Service
	StopAndDisableService("wercplsupport") # 「問題の報告と解決策」でレポートを送信する
	# P2P
	StopAndDisableService("p2pimsvc")
	StopAndDisableService("p2psvc")
	StopAndDisableService("PNRPAutoReg")
	StopAndDisableService("PNRPsvc")
	# リモートデスクトップ
	StopAndDisableService("SessionEnv")
	StopAndDisableService("TermService")
	StopAndDisableService("UmRdpService")
	# モバイルデバイス・データ通信
	StopAndDisableService("dmwappushservice") # デバイス管理ワイヤレスアプリケーションプロトコル（WAP）プッシュメッセージルーティングサービス
	StopAndDisableService("DusmSvc") # データ通信量の管理
	StopAndDisableService("icssvc") # モバイルホットスポットサービス
	StopAndDisableService("lfsvc") # ジオロケーション
	StopAndDisableService("PhoneSvc") # 電話の状態を管理
	StopAndDisableService("SEMgrSvc") # NFC等での支払いの管理
	# ネットワーク・リモート
	StopAndDisableService("DeviceAssociationService") # ホームグループへ参加するための機能
	StopAndDisableService("DoSvc") # Windows Update などでダウンロードしたデータを他の端末に配信する
	StopAndDisableService("FDResPub") # ネットワーク探索
	StopAndDisableService("fdPHost") # ネットワーク探索（依存関係のため FDResPub より後に停止する）
	StopAndDisableService("LanmanServer") # ファイルや印刷を共有するためのサーバ
	StopAndDisableService("MSiSCSI") # iSCSI セッションの管理
	StopAndDisableService("NetTcpPortSharing") # TCP ポートを共有する機能
	StopAndDisableService("RemoteRegistry") # リモートからのレジストリ変更
	StopAndDisableService("SSDPSRV") # SSDP
	StopAndDisableService("TrkWks") # ネットワーク内またはコンピューターの NTFS ボリューム間のリンクを管理する
	StopAndDisableService("upnphost") # UPnP のホスティング
	StopAndDisableService("WMPNetworkSvc") # Windows Media Player ライブラリのネットワーク共有
	# Xbox（注意：Xbox のサービスを全て止めると Win + G による動画キャプチャが働かない模様。どれを生かしておけばキャプチャできるかは未確認。）
	StopAndDisableService("XblAuthManager")
	StopAndDisableService("XblGameSave")
	StopAndDisableService("XboxGipSvc")
	StopAndDisableService("XboxNetApiSvc")
	# 外部接続（あるいは内蔵）機器
	#StopAndDisableService("FrameServer") # カメラフレームサーバー
	#StopAndDisableService("Spooler") # 印刷スプーラ
	# その他
	StopAndDisableService("CertPropSvc") # スマートカードから証明書を読み取る
	StopAndDisableService("diagnosticshub.standardcollector.service") # ETW イベントを収集
	StopAndDisableService("KtmRm") # 分散トランザクションの管理
	StopAndDisableService("MSDTC") # 分散トランザクションの管理
	StopAndDisableService("TokenBroker") # アプリとサービスにシングルサインオンを提供する
}
