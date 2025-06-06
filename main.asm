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

start

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

;;; upper nybble of grid square: object type, affects beam tint
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
MIXTRED	= 0 | 0 | 0 | 1 << (TINTRED - 1)	;1
MIXTYEL	= 0 | 0 | 1 << (TINTYEL - 1) | 0	;2
MIXTORN	= 0 | 0 | MIXTRED | MIXTYEL		;3
MIXTBLU	= 0 | 1 << (TINTBLU - 1) | 0 | 0	;4
MIXTPUR	= 0 | MIXTBLUE | 0 | MIXTRED		;5
MIXTGRN	= 0 | MIXTBLU | MIXTYEL	| 0		;6
MIXTBLK	= 0 | MIXTBLU | MIXTYEL | MIXTRED	;7
MIXTWHT	= 1 << (TINTWHT - 1) | 0 | 0 | 0	;8
MIXT_LR	= MIXTWHT | 0 | 0 | MIXTRED		;9
MIXT_LY	= MIXTWHT | 0 | MIXTYEL	| 0		;10
MIXT_LO	= MIXTWHT | 0 | MIXTYEL | MIXTRED	;11
MIXT_LB	= MIXTWHT | MIXTBLU | 0 | 0		;12
MIXT_LP	= MIXTWHT | MIXTBLU | 0 | MIXTRED	;13
MIXT_LG	= MIXTWHT | MIXTBLU | MIXTYEL | 0	;14
MIXTGRY	= MIXTRED | MIXTYEL | MIXTBLU | MIXTWHT ;15
MIXTOFF	= 1 << (ABSORBD - 1)			;128

commodc	.byte	VIDEOBG
	.byte	VIDEOR				;1
	.byte	VIDEOY				;2
	.byte	VIDEOO				;3
	.byte	VIDEOB				;4
	.byte	VIDEOP				;5
	.byte	VIDEOG				;6
	.byte	VIDEOK				;7
	.byte	VIDEOW				;8
	.byte	VIDEOLR				;9
	.byte	VIDEOLY				;10
	.byte	VIDEOLO				;11
	.byte	VIDEOLB				;12
	.byte	VIDEOLP				;13
	.byte	VIDEOLG				;14
	.byte	VIDEOGY				;15

HIDGRID	= vararea + $00
var2	= vararea + $50

;visualz	hal_vis
	rts

;inputkb	hal_inp
	rts

main	tsx

pre_end
.align $10
vararea
.end

