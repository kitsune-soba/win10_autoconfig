# win10_autoconfig

## 概要

Windows 10 の諸々の設定を行う。設定内容はスクリプトを参照。  
これはレジストリ等を大いに書き換える闇の魔術であり、たとえ Windows が破壊されようとも生き残れる者のみがこれに触れてよい。

## 動作環境

- Windows 10（主に Windows 10 Home 21H2 およびこれに初めから入っている Windows PowerShell 5 で動作確認した。）
- winget がインストールされていること

## 使い方

1. 全てのスクリプトをダウンロードする
1. スクリプト（主に main.ps1）に目を通し、利用者のニーズに合わせて設定内容を書き換える
1. 管理者権限を持った PowerShell で main.ps1 を実行する

## 備考

「このシステムではスクリプトの実行が無効になっているため、ファイル win10_autoconfig.ps1 を読み込むことができません。」と怒られて実行できない場合は、先に `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process` を実行する。
