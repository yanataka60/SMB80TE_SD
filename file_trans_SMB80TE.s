PIOAD	EQU		0D0h		;PIO A DATA
PIOAC	EQU		0D1h		;PIO A CONTROL
PIOBD	EQU		0D2h		;PIO B DATA
PIOBC	EQU		0D3h		;PIO B CONTROL
PIOCD	EQU		0D4h		;PIO C DATA
PIOCC	EQU		0D5h		;PIO C CONTROL
PIODD	EQU		0D6h		;PIO D DATA
PIODC	EQU		0D7h		;PIO D CONTROL
LED		EQU		0DAh		;LED
SYS		EQU		0D8H		;SYSTEM CONTROL
INT		EQU		0D9h		;SYSTEM MNI PORT
MODE	EQU		07CCh		;USER PROGRAM MODE
STACK	EQU		07CCh		;MONITOR STACK
USER	EQU		079Ah		;USER STACK
SEGBUF	EQU		07CDh		;SEGMENT BUFFER
DISBUF	EQU		07D5h		;DISPLAY BUFFER
FLAG	EQU		07DDh		;CHATTERING FLAG
DATA	EQU		07DFh		;DATA REG.
EADRS	EQU		07DFH		;(DATA)LOAD SAVE END ADDRESS
ADDR	EQU		07E1h		;ADDRESS REG.
SADRS	EQU		07E1H		;(ADDR)LOAD SAVE START ADDRESS
SAVE	EQU		07E3h		;USER REG. SAVE AREA
FNAME	EQU		07E9H
SADIN	EQU		07EBH
EADIN	EQU		07EDH
BCOUNT	EQU		07FDh		;BREAK COUNTER
BADDR	EQU		07FEh		;BREAK ADDRESS
MONST	EQU		8031H		;MONITOR RETURN ADDRESS
DISP1	EQU		8436h
DISP2	EQU		843bh
SEGCON	EQU		8465h
KEYIN	EQU		8482h
SCAN	EQU		84C3h
MIN		EQU		0F850H      ;WORK -(07B0H)LOAD除外START ADDRES
MAX		EQU		0F800H      ;WORK -(07FFH+1)LOAD除外END ADDRESS

;D4H Z80PIO PORTC
;7 OUT
;6 OUT
;5 OUT
;4 OUT
;3 OUT	FLG
;2 OUT	送信データ
;1 IN	CHK
;0 IN	受信データ

		
		ORG		8800H

;8800Hから実行でSD_LOAD
		JP		SDLOAD
;8803Hから実行でSD_SAVE
		JP		SDSAVE

;8806H MONITOR修正するなら8060HからここへJUMPさせる
		CP		0CH
		JP      Z,8638h
		CP		0AH
		JP		Z,SDLOAD
		CP		0BH
		JP		Z,SDSAVE
		RET
		

;受信ヘッダ情報をセットし、SDカードからLOAD実行
;FNAME <- 0000H～FFFFHを入力。
;         ファイルネームは「xxxx.BTK」となる。
SDLOAD:	CALL	INIT

;******************* LOAD FILE NAME 入力 ***********************
		CALL	TCLR
		LD		IX,L_F
		CALL	TINP
		LD		DE,FNAME	;LOAD FILE NAMEをHL退避エリアに退避
		CALL	TSTR

		LD		A,81H
		CALL	SNDBYTE		;LOADコマンド81Hを送信
		CALL	RCVBYTE		;状態取得(00H=OK)
		AND		A			;00以外ならERROR
		JP		NZ,SVERR
TKMODE5:LD		DE,FNAME
TKMD5:	LD		A,(DE)		;FNAME取得
		CALL	SNDBYTE
		INC		DE
		LD		A,(DE)
		CALL	SNDBYTE
		CALL	RCVBYTE		;状態取得(00H=OK)
		AND		A			;00以外ならERROR
		JP		NZ,SVERR
		CALL	HDRCV		;ヘッダ情報受信
		CALL	DBRCV		;データ受信
		JP		MONRET		;MONITOR復帰

;ヘッダ受信
HDRCV:	LD		HL,SADRS+1	;SADRS取得
		CALL	RCVBYTE
		LD		(HL),A
		DEC		HL
		CALL	RCVBYTE
		LD		(HL),A
		LD		HL,EADRS+1	;EADRS取得
		CALL	RCVBYTE
		LD		(HL),A
		DEC		HL
		CALL	RCVBYTE
		LD		(HL),A
		RET

;データ受信
DBRCV:	LD		DE,(EADRS)
		LD		HL,(SADRS)
DBRLOP:	CALL	DISP2
		CALL	RCVBYTE
		LD		B,A
		CALL	JOGAI		;WORKエリアを識別して書き込みSKIP
		AND		A
		JP		NZ,SKIP
		LD		A,B
		LD		(HL),A
		CALL	ADRSDSP
SKIP:	LD		A,H
		CP		D
		JP		NZ,DBRLP1
		LD		A,L
		CP		E
		JP		Z,DBRLP2	;HL = DE までLOOP
DBRLP1:	INC		HL
		JP		DBRLOP
DBRLP2:	RET
		
;SAVE、LOAD中経過表示
ADRSDSP:
		PUSH	HL
		PUSH	DE
		PUSH	AF
		EX		DE,HL		;DATA <- 現在ADRS
		LD		HL,DATA
		LD		(HL),E
		INC		HL
		LD		(HL),D
		CALL	DISP1
		CALL	SCAN
		POP		AF
		POP		DE
		POP		HL
		RET

;SAVE、LOADエラー終了処理(F0H又はFFHをLEDに表示)
ERRDSP:	LD		HL,DATA
		LD		(HL),A
		INC		HL
		LD		(HL),A
		INC		HL
		LD		(HL),A
		INC		HL
		LD		(HL),A
		CALL	DISP1
		CALL	SCAN
		RET

;送信ヘッダ情報をセットし、SDカードへSAVE実行
;FNAME <- 0000H～FFFFHを入力。
;         ファイルネームは「xxxx.BTK」となる。
;SADIN <- 保存開始アドレス
;EADIN <- 保存終了アドレス

SDSAVE:	CALL	INIT

;******************* SAVE FILE NAME 入力 ***********************
		CALL	TCLR
		LD		IX,S_F
		CALL	TINP
		LD		DE,FNAME	;SAVE FILE NAMEをHL退避エリアに退避
		CALL	TSTR

;******************* SAVE START ADDRESS 入力 ***********************
		CALL	TCLR
		LD		IX,S_S
		CALL	TINP
		LD		DE,SADIN	;SAVE START ADDRESSをDE退避エリアに退避
		CALL	TSTR

;******************* SAVE END ADDRESS 入力 ***********************
		CALL	TCLR
		LD		IX,S_E
		CALL	TINP
		LD		DE,EADIN	;SAVE END ADDRESSをBC退避エリアに退避
		CALL	TSTR

		LD		A,80H
		CALL	SNDBYTE		;SAVEコマンド80Hを送信
		CALL	RCVBYTE		;状態取得(00H=OK)
		AND		A			;00以外ならERROR
		JP		NZ,SVERR
TKMODE4:
		LD		DE,FNAME
TKMD4:	
		LD		A,(DE)		;FNAME取得
		INC		DE
		LD		A,(DE)
		CALL	HDSEND		;ヘッダ情報送信
		CALL	RCVBYTE		;状態取得(00H=OK)
		AND		A			;00以外ならERROR
		JP		NZ,SVERR
		CALL	DBSEND		;データ送信
SDSV3:
;		CALL	OKDSP		;SAVE情報表示
MONRET:	JP		MONST		;MONITOR復帰

SVERR:	CALL	ERRDSP		;FFH:FILE OPEN ERROR F0H:SDカード初期化ERROR
		JP		MONST		;F1H;FILE存在ERROR

;ヘッダ送信
HDSEND:	LD		B,06H
		LD		HL,FNAME	;FNAME送信、SADRS送信、EADRS送信
HDSD1:	LD		A,(HL)
		CALL	SNDBYTE
		INC		HL
		DEC		B
		JP		NZ,HDSD1
		RET

;データ送信
;SADRSからEADRSまでを送信
DBSEND:	LD		DE,(SADIN)
		LD		HL,ADDR
		LD		(HL),E
		INC		HL
		LD		(HL),D
		EX		DE,HL
		LD		DE,(EADIN)
DBSLOP:	LD		A,(HL)
		CALL	ADRSDSP
		CALL	SNDBYTE
		LD		A,H
		CP		D
		JP		NZ,DBSLP1
		LD		A,L
		CP		E
		JP		Z,DBSLP2	;HL = DE までLOOP
DBSLP1:	INC		HL
		JP		DBSLOP
DBSLP2:	RET

;1BYTE送信
;Aレジスタの内容を下位BITから送信
SNDBYTE:PUSH 	BC
		LD		B,08H
SBLOP1:	RRCA				;最下位BITをCフラグへ
		PUSH	AF
		JP		NC,SBRES	;Cフラグ = 0
SBSET:	LD		A,01H		;Cフラグ = 1
		JP		SBSND
SBRES:	LD		A,00H
SBSND:	CALL	SND1BIT		;1BIT送信
		POP		AF
		DEC		B
		JP		NZ,SBLOP1	;8BIT分LOOP
		POP		BC
		RET
		
;1BIT送信
;Aレジスタ(00Hor01H)を送信する
SND1BIT:
		CP		01H
		IN		A,(PIOCD)
		JR		Z,SB1
		AND		0FBH		;送信データ0
		JR		SB2
SB1:	OR		04H			;送信データ1
SB2:	OUT		(PIOCD),A	;PORTC BIT2 <-送信データ
		IN		A,(PIOCD)
		OR		08H
		OUT		(PIOCD),A	;PORTC BIT3 <- 1
		CALL	F1CHK		;PORTC BIT1が1になるまでLOOP
		IN		A,(PIOCD)
		AND		0F7H
		OUT		(PIOCD),A	;PORTC BIT3 <- 0
		CALL	F2CHK		;PORTC BIT1が0になるまでLOOP
		RET
		
;1BYTE受信
;受信DATAをAレジスタにセットしてリターン
RCVBYTE:PUSH 	BC
		LD		C,00H
		LD		B,08H
RBLOP1:	CALL	RCV1BIT		;1BIT受信
		AND		A			;A=0?
		LD		A,C
		JP		Z,RBRES		;0
RBSET:	INC		A			;1
RBRES:	RRCA				;Aレジスタ右SHIFT
		LD		C,A
		DEC		B
		JP		NZ,RBLOP1	;8BIT分LOOP
		LD		A,C			;受信DATAをAレジスタへ
		POP		BC
		RET
		
;1BIT受信
;受信BITをAレジスタに保存してリターン
RCV1BIT:CALL	F1CHK		;PORTC BIT1が1になるまでLOOP
		IN		A,(PIOCD)
		OR		08H
		OUT		(PIOCD),A	;PORTC BIT2 <- 1
		IN		A,(PIOCD)	;PORTC BIT0 <- 受信データ
		AND		01H
		PUSH	AF
		CALL	F2CHK		;PORTC BIT1が0になるまでLOOP
		IN		A,(PIOCD)
		AND		0F7H
		OUT		(PIOCD),A	;PORTC BIT2 <- 0
		POP		AF			;受信DATAセット
		RET
		
;BUSYをCHECK(1)
; PORTC BIT1が1になるまでLOP
F1CHK:	IN		A,(PIOCD)
		AND		02H			;PORTC BIT1 = 1?
		JP		Z,F1CHK
		RET

;BUSYをCHECK(0)
; PORTC BIT1が0になるまでLOOP
F2CHK:	IN		A,(PIOCD)
		AND		02H			;PORTC BIT1 = 0?
		JP		NZ,F2CHK
		RET

;WORKエリアを識別
;07B0H～07FFHはLOADデータの書込みをSKIP
JOGAI:	PUSH	HL
		PUSH	DE
		EX		DE,HL
JOGAI_TK:
		LD		HL,MIN
		ADD		HL,DE
		JP		NC,JGOK		;MIN未満ならOK
		LD		HL,MAX
		ADD		HL,DE
		JP		NC,JGERR	;MAX未満ならSKIP
JGOK:	XOR		A			;OKならAレジスタ=0
		JP		JGRTN
JGERR:	LD		A,01H		;SKIP範囲ならAレジスタ=1
		JP		JGRTN
JGRTN:	POP		DE
		POP		HL
		RET

;Z80PIO初期化
INIT:
;出力BITをリセット
INIT2:	LD		A,0CFH			;モード3セット
		OUT		(PIOCC),A
		LD		A,03H			;BIT0～1を入力、BIT2～6は出力
		OUT		(PIOCC),A
		RET
		
;************************* FILE NAME等データ入力 ***************
TINP:
LP1:	
		CALL	DISP1
		CALL	TDSP
		CALL	SCAN
		CALL	KEYIN
		CP		10H
		JR		NC,LP2		;0～F以外のキーが押されたら終了
		LD		HL,DATA
		RLD
		INC		HL
		RLD
		JR		LP1
LP2:	RET

;************************* LED DATA部表示クリア ******************
;データ表示部に表示するデータを0000にクリア
TCLR:
		XOR		A
		LD		HL,DATA
		LD		(HL),A
		INC		HL
		LD		(HL),A
		CALL	DISP2
		RET
		
;************************* 入力データ TITLE 表示 *******************
;IX <- 表示データADDRESS
;HL <- SEGBUF+7
;ADDRESS表示部にメッセージデータをセット
TDSP:
		PUSH	IX
		LD		B,04H
		LD		HL,SEGBUF+7
TDSP1:	LD		A,(IX)
		LD		(HL),A
		INC		IX
		DEC		HL
		DJNZ	TDSP1
		POP		IX
		RET

;************************* FILE NAME等入力データ退避 ******************
;DE <- 退避アドレス
;HL <- DATA
;DATA表示部に入力した16進4桁の数値を(DE)に退避
TSTR:
		LD		HL,DATA
		LD		A,(HL)
		LD		(DE),A
		INC		HL
		INC		DE
		LD		A,(HL)
		LD		(DE),A
		RET

;************************* TITLE DATA ********************************
L_F:	DB		38h,40h,71h,00h		;'L-F' LOAD FILE NAME
S_F:	DB		6Dh,40h,71h,00h		;'S-F' SAVE FILE NAME
S_S:	DB		6Dh,40h,6Dh,00h		;'S-S' SAVE START ADDRESS
S_E:	DB		6Dh,40h,79h,00h		;'S-E' SAVE END ADDRESS

		END
