# SHARP SM-B-80TEにSD-Cardとのロード、セーブ機能

![TITLE](https://github.com/yanataka60/SMB80TE_SD/blob/main/JPEG/SMB80TE.JPG)

　シリアル同期通信によりSM-B-80TEとSD_ACCESS(ARDUINO+SD-CARD)とのロード、セーブを提供するルーチンです。

## 必要なもの
　Z80PIO 1個(標準搭載のZ80PIOとは別のZ80PIOが必要)

　SD_ACCESS基板(「SD_ACCESS」リポジトリ参照)

　2716 1個(MONITOR ROMを差し替えるなら2716 2個)

　ピンヘッダ、フラットケーブル、ブレッドボード・ジャンパーワイヤ等(SD_ACCESS基板の接続方法により適宜用意してください)

## 接続方法
SD_ACCESS(ARDUINO+SD-CARD)と拡張Z80PIOを接続します。拡張Z80PIO外部端子から接続する例を示します。

SD_ACCESS(ARDUINO+SD-CARD)については、「SD_ACCESS」リポジトリを参照してください。

|Arduino(SD_ACCESS)|拡張Z80PIO外部端子(SM-B-80TE)|
| ------------ | ------------ |
|5V|B8　5V|
|GND|B7　GND|
|9(FLG:output)|A4　PORTC BIT1(CHK:input)|
|8(OUT:output)|B4　PORTC BIT0(IN:input)|
|7(CHK:input)|A3　PORTC BIT3(FLG:output)|
|6(IN:input)|B3　PORTC BIT2(OUT:output)|

　今回はTK-85用に用意したSD_ACCESS(ARDUINO+SD-CARD)を流用して繋いでいます。

![SD-Cardアダプタ](https://github.com/yanataka60/SMB80TE_SD/blob/main/JPEG/SD-CARD.JPG)

　SM-B-80TE専用のSD_ACCESS基板を作ってみました。

　基板データは、Kicadフォルダにあります。

#### 部品
|番号|品名|数量|備考|
| ------------ | ------------ | ------------ | ------------ |
|J1|細ピンヘッダ又は基板用リードフレーム|1|秋月電子通商 PHA-1x40SG又はSHP-001|
||J2、J3のいずれか|||
|J2|Micro_SD_Card_Kit|1|秋月電子通商 AE-microSD-LLCNV|
|J3|MicroSD Card Adapter|1|Arduino等に使われる5V電源に対応したもの|
|U2|Arduino_Pro_Mini_5V|1||
||40PinICソケット|1||

![SD-BOARD1](https://github.com/yanataka60/SMB80TE_SD/blob/main/JPEG/SD-BORAD(1).JPG)

![SD-BOARD2](https://github.com/yanataka60/SMB80TE_SD/blob/main/JPEG/SD-BORAD(2).JPG)

## ROMの差し替え

file_trans_SMB80TE.binを2716に書き込み、SM-B-80TEのIC3 ROMソケットに挿し込みます。

file_trans_SMB80TE.binのSD用LOADルーチン(8800H)、SAVEルーチン(8803H)を直接実行することでSDへのLOAD、SAVEが行えますが、MONITOR-ROMにパッチを当てることでSHIFT+A(SD-LOAD)、SHIFT+B(SD-SAVE)で使えるようにすると便利です。

　MONITOR-ROMの内容を読み出し、バイナリエディタ等で以下を修正し、2716に書き込み、MONITOR-ROMと差し替えます。

|ADDRESS(実ADDRESS)|変更前|変更後|
| ------------ | ------------ | ------------ |
|0060(8060)|FE|C3|
|0061(8061)|0C|06|
|0062(8062)|CA|88|

## SD-CARD
　FAT16又はFAT32が認識できます。

## 扱えるファイル
　拡張子btkとなっているバイナリファイルです。

　ファイル名は0000～FFFFまでの16進数4桁を付けてください。(例:1000.btk)

　この16進数4桁がSM-B-80TEからSD-Card内のファイルを識別するファイルNoとなります。

　btkの構造は、バイナリファイル本体データの先頭に開始アドレス、終了アドレスの4Byteのを付加した形になっています。

　パソコンのクロスアセンブラ等でSM-B-80TE用の実行binファイルを作成したらバイナリエディタ等で先頭に開始アドレス、終了アドレスの4Byteを付加し、ファイル名を変更したものをSD-Cardのルートディレクトリに保存すればSM-B-80TEから呼び出せるようになります。

## 操作方法
　異常が無いと思われるのにエラーとなってしまう場合にはSD-CardアダプタのArduinoとSM-B-80TEの両方をリセットしてからやり直してみてください。

### Load
(直接実行する場合)8800H

(MONITOR-ROMを差し替えた場合)SHIFT+A

　ADDRESS LEDに「L-F」と表示されるのでファイルNo(xxxx)を16進数4桁で入力してWRキーを押します。

　　　xxxx.BTKをBTKヘッダ情報で示されたアドレスにロードします。ただし、07B0H～07FFHまでの範囲はライトプロテクトされます。

　正常にLoadが完了するとアドレス部にスタートアドレス、データ部にエンドアドレスが表示されます。スタートアドレスが実行開始アドレスであればそのままRUNキーを押すことでプログラムが実行できます。

　「F0F0F0F0F0」と表示された場合はSD-Card未挿入、「F1F1F1F1F1」と表示された場合はファイルNoのファイルが存在しない場合です。確認してください。

### Save
(直接実行する場合)8803H

(MONITOR-ROMを差し替えた場合)SHIFT+B

　ADDRESS LEDに「S-F」と表示されるのでファイルNo(xxxx)を16進数4桁で入力してWRキーを押します。

　ADDRESS LEDに「S-S」と表示されるのでSAVEしたい範囲のSTART ADDRESSを16進数4桁で入力してWRキーを押します。

　ADDRESS LEDに「S-E」と表示されるのでSAVEしたい範囲のEND ADDRESSを16進数4桁で入力してWRキーを押します。

　正常にSaveが完了するとアドレス部にスタートアドレス、データ部にエンドアドレスが表示されます。

　「FFFFFFFF」と表示された場合はSD-Card未挿入です。確認してください。
