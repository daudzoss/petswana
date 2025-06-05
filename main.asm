.include "6502apcs.inc"

.if BASIC
*	= BASIC+1
.else
*	= $0002+1
COPIED2	= $0400
	.word	(+), 3
	.text	$81,$41,$b2,$30	; FOR A = 0
	.text	$a4		; TO prefld-start
	.text	format("%4d",pre_end-start)
	.text	$3a,$dc,$30	; : BANK 0
	.text	$3a,$42,$b2,$c2	; : B = PEEK
	.text	$28		; ( start
	.text	format("%2d",COPIED2)
	.text	$aa,$41,$29,$3a	; + A ) :
	.text	$dc,$31,$35,$3a	; BANK 1 5 :
	.text	$97		; POKE start
	.text 	format("%2d",COPIED2)
	.text	$aa,$41,$2c,$42	; + A , B
	.text	$3a,$82,$00	; : NEXT
.endif
+	.word	(+),2055
	.text	$9e
	.null	format("%4d",main)
+	.word	0
.if !BASIC
*	= COPIED2
.endif

TP	= 6
LT	= 4
BT	= 2
;RT	= 0
NOBOUNC	= %00			; can't bounce off something that's not there
EVBOUNC	= %01			; as if off a wall running top right,bottom left
RABOUNC	= %10			; whence ye came
ODBOUNC	= %11			; as if off a wall running top left,bottom right

;;; from top|left|bot|right; see object shapes below
bounces	.byte	NOBOUNC x 4
bounce1	.byte	(RABOUNC << TP) | (RABOUNC << LT) | (EVBOUNC << BT) | EVBOUNC;RT
bounce2	.byte	(RABOUNC << TP) | (ODBOUNC << LT) | (ODBOUNC << BT) | RABOUNC;RT
bounce3	.byte	(EVBOUNC << TP) | (EVBOUNC << LT) | (RABOUNC << BT) | RABOUNC;RT
bounce4	.byte	(ODBOUNC << TP) | (RABOUNC << LT) | (RABOUNC << BT) | ODBOUNC;RT
bounce5	.byte	(RABOUNC << TP) | (NOBOUNC << LT) | (RABOUNC << BT) | NOBOUNC;RT
bounce6	.byte	(NOBOUNC << TP) | (RABOUNC << LT) | (NOBOUNC << BT) | RABOUNC;RT
bounce7	.byte	RABOUNC x 4

;;; lower nybble of grid square: object shape, indexes bounce[]
BLANK	= 0
CHAMFBR	= 1
CHAMFBL	= 2
CHAMFTL	= 3
CHAMFTR = 4
;BOREDLR	= 5
;BOREDTB	= 6
SQUARE	= 7

;;; upper nybble of grid square: object type
UNTINTD	= 0			; no color change
TINTRED	= 1
TINTYEL	= 2
TINTBLU	= 3
TINTWHT	= 4
ABSORBD	= 8			; no further travel
;UNTINTD = UNTINTD << 4
OBJTRED = TINTRED << 4
OBJTYEL	= TINTYEL << 4
OBJTBLU	= TINTBLU << 4
OBJTWHT	= TINTWHT << 4
BEAMOFF	= ABSORBD << 4

;;; beam spectrum bit values
;UNTINTD = 0
MIXTRED	= 1 << (TINTRED - 1)
MIXTYEL	= 1 << (TINTYEL - 1)
MIXTBLU	= 1 << (TINTBLU - 1)
MIXTWHT = 1 << (TINTWHT - 1)
MIXTOFF = 1 << (ABSORBD - 1)
MIXTORN	= MIXTRED | MIXTYEL
MIXTPUR	= MIXTRED | MIXTBLU
MIXTPNK	= MIXTRED | MIXTWHT
MIXTGRN = MIXTYEL | MIXTBLU
MIXTLMN	= MIXTYEL | MIXTWHT
MIXTSKY	= MIXTBLU | MIXTWHT
MIXTBRN	= MIXTRED | MIXTYEL | MIXTBLU
MIXT_LO	= MIXTRED | MIXTYEL | MIXTWHT
MIXT_LG	= MIXTYEL | MIXTBLU | MIXTWHT
MIXTGRY	= MIXTRED | MIXTYEL | MIXTBLU | MIXTWHT

var1	= vararea + $00

start

extern visualz

extern kbinput	

main	


