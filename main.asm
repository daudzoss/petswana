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

;;; 10x8 playfield: labeled 1-10 on top, 11-18 on right, A-H on left, I-R on bot
GRIDW	= $0a
GRIDH	= $08
GRIDSIZ	= GRIDW*GRIDH

;;; a cell in a grid has a 7-bit state, representing the residing object portion
;;;	7	6	5	4	|		2	1	0
;;; {UNTINTD=0;TINT*=1,2,3,4;ABSORBD=8}     0  {BLANK=0;CHAMF*=1,2,3,4;SQUARE=7}

;;; the wavefront of a beam has a 7-bit state, in addition to its x and y coords
;;; 	7	6		4	|	3	2	1	0
;;; {FROM_*=0,1,2,3}	0	{UNTINTD=0;MIXT*=1,2,3,...13,14,15;MIXTOFF=16}

;;; binary pairs corresponding to the cardinal beam travel directions
FROM_RT	= %00			; moving right to left, beam hits a cell's right
FROM_BT	= %01			;   "    bottom to top,   "    "  "   "   bottom
FROM_LT	= %10			;   "    left to right,   "    "  "   "   left
FROM_TP	= %11			;   "    top to bottom,   "    "  "   "   top
TP	= 2*FROM_TP
LT	= 2*FROM_LT
BT	= 2*FROM_BT
RT	= 2*FROM_RT
MASK_RT	= 0 | 0 | 0 | (%11 << RT)
MASK_BT	= 0 | 0 | (%11 << BT) | 0
MASK_LT	= 0 | (%11 << LT) | 0 | 0
MASK_TP	= (%11 << TP) | 0 | 0 | 0

;;; exclusive-or values to bounce an incident beam back perpendicularly or by 45
NOBOUNC	= %00			; don't bounce off something that's not there
EVBOUNC	= %01			; as if off a wall running top right,bottom left
RABOUNC	= %10			; whence ye came
ODBOUNC	= %11			; as if off a wall running top left,bottom right
TWRD_RT	= RABOUNCE ^ FROM_RT
TWRD_BT	= RABOUNCE ^ FROM_BT
TWRD_LT	= RABOUNCE ^ FROM_LT
TWRD_TP	= RABOUNCE ^ FROM_TP

;;; from top|left|bot|right, corresponding to the possible cell shapes 0-7 below
bounces	.byte	NOBOUNC x 4
bounce1	.byte	(RABOUNC << TP) | (RABOUNC << LT) | (EVBOUNC << BT) | EVBOUNC;RT
bounce2	.byte	(RABOUNC << TP) | (ODBOUNC << LT) | (ODBOUNC << BT) | RABOUNC;RT
bounce3	.byte	(EVBOUNC << TP) | (EVBOUNC << LT) | (RABOUNC << BT) | RABOUNC;RT
bounce4	.byte	(ODBOUNC << TP) | (RABOUNC << LT) | (RABOUNC << BT) | ODBOUNC;RT
bounce5	.byte	(RABOUNC << TP) | (NOBOUNC << LT) | (RABOUNC << BT) | NOBOUNC;RT
bounce6	.byte	(NOBOUNC << TP) | (RABOUNC << LT) | (NOBOUNC << BT) | RABOUNC;RT
bounce7	.byte	RABOUNC x 4

;;; lower nybble of a grid square affects incident beam path, indexing bounces[]
BLANK	= 0			; nothing in the cell to block an incident beam
CHAMFBR	= 1			; triangular reflector, chamfer at bottom right
CHAMFBL	= 2			;      "        "     , chamfer at bottom left
CHAMFTL	= 3			;      "        "     , chamfer at top left
CHAMFTR = 4			;      "        "     , chamfer at top right
;BOREDLR	= 5			; transmits left-right but rebounds top-bottom
;BOREDTB	= 6			; transmits top-bottom but rebounds left-right
SQUARE	= 7			; cell filled in so all four sides will rebound

;;; upper nybble of grid square absorbs/reflects beam, optionally imparting tint
UNTINTD	= 0
TINTRED	= 1
TINTYEL	= 2
TINTBLU	= 3
TINTWHT	= 4
ABSORBD	= 8
OBJTUNT	= UNTINTD << 4		; no tint change: blank cell or transparent refl
OBJTRED = TINTRED << 4		; a red-tinted object sets beam TINTRED-1th bit
OBJTYEL	= TINTYEL << 4		; " yellow- "     "     "    "  TINTYEL-1th  "
OBJTBLU	= TINTBLU << 4		; " blue-   "     "     "    "  TINTBLU-1th  "
OBJTWHT	= TINTWHT << 4		; " white-  "     "     "    "  TINTWHT-1th  "
BEAMOFF	= ABSORBD << 4		; perfect blackbody, no further travel of a beam

;;; beam spectrum bit values, reflecting a tint mixture after multiple rebounds
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
MIXTOFF	= 1 << 4				;16

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
TRYGRID	= vararea + GRIDSIZ
var2	= vararea + 2*GRIDSIZ

inigrid	lda	#0		;inline inigrid(uint1_t c) {
	ldy	#GRIDSIZ	; for (register uint8_t y = GRIDSIZ; y; y--) {
-	bcc	+		;  if (c)
	sta	HIDGRID-1,y	;   HIDGRID[y-1] = 0;
	bcs	++		;  else
+	sta	TRYGRID-1,y	;   TRYGRID[y-1] = 0;
+	dey			;
	bne	-		; }
	rts			;} // inigrid()

rotshap				;} // rotshap (new x in a, new y in y)

DRW_CEL	= 1<<0			;
DRW_TRY	= 1<<3			;
DRW_HID	= 1<<4			;
DRW_MSG	= 1<<5			;
DRW_LBL	= 1<<6			;
DRW_MSH	= 1<<7			;
DRW_ALL	= DRW_MSH|DRW_LBL|DRW_MSG|DRW_HID|DRW_TRY
vis_cel	.byte	DRW_CEL		;
vis_try	.byte	DRW_TRY		;
vis_hid	.byte	DRW_HID		;
vis_msg	.byte	DRW_MSG		;
vis_lbl	.byte	DRW_LBL		;
vis_msh	.byte	DRW_MSH		;

visualz	pha	;//V0LOCAL=what	;void visualz(register uint8_t a, uint4_t x0,
	bit	vis_msh		;                                 uint4_t y0) {
	beq	+		; if (a & DRW_MSH) {
	FUNCALL			;
	jsr	hal_msh		;  hal_msh(a);
	FUNRETN			;
 jmp ++++++
	lda @w	V0LOCAL		; }
+	bit	vis_lbl		;
	beq	+		; if (a & DRW_LBL) {
	FUNCALL			;
	jsr	hal_lbl		;  hal_lbl(a);
	FUNRETN			;
 jmp +++++
	lda @w	V0LOCAL		; }
+	bit	vis_msg		;
	beq	+		; if (a & DRW_MSG) {
	FUNCALL			;
	jsr	hal_msg		;  hal_msg(a);
	FUNRETN			;
 jmp ++++
	lda @w	V0LOCAL		; }
+	bit	vis_hid		;
	beq	+		; if (a & DRW_HID) {
	FUNCALL			;
	jsr	hal_hid		;  hal_hid(a);
	FUNRETN			;
 jmp +++
	lda @w	V0LOCAL		; }
+	bit	vis_try		;
	beq	+		; if (a & DRW_TRY) {
	FUNCALL			;
	jsr	hal_try		;  hal_try(a);
	FUNRETN			;
 jmp ++
	lda @w	V0LOCAL		; }
+	bit	vis_cel		;
	beq	+		; if (a & DRW_CEL) {
	lda	A1FUNCT		;
	sta @w	V0LOCAL	;//y0	;
	lda	A0FUNCT		;
	pha	;//V1LOCAL=x0	;
	FUNCALL			;
	jsr	hal_cel		;  hal_cel(x0, y0);
	FUNRETN			;
 jmp +
+	POPVARS			; }
	rts			;} // visualz()

.if SCREENW >= $28
.elsif SCREENW >= $16
.else
.endif ;//FIXME:move this line to after the code below
putchar	tay			;inline void putchar(register uint8_t a) {
	txa			; // a stashed in y
	pha			; // x stashed in a, then on stack
	tya			; // a restored from y
	jsr	$ffd2		; (* ((*)()) 0xffd2)(a);
	pla			;
	tax			; // x restored from stack by way of a
	rts			;} // putchar()

rule	.macro	temp,lj,mj,rj	;#define rule(temp,ljoin,mjoin,rjoin) {        \
	lda	#$0d		;                                              \
	jsr	$ffd2		; putchar('\n');                               \
	lda	#\ljoin		;                                              \
	jsr	$ffd2		; putchar(ljoin);                              \
	lda	#$60		;                                              \
	jsr	$ffd2		; putchar('-');                                \
	ldy	#GRIDW		;                                              \
	cpy	#3		;                                              \
	bcc	+		; if (GRIDW > 2) {                             \
	dey			;                                              \
	dey			;                                              \
-	sty @w	\temp		;  for (*temp = GRIDW - 2; *temp; --*temp) {   \
	lda	#\mjoin		;                                              \
	jsr	$ffd2		;   putchar(mjoin);                            \
	lda	#$60		;                                              \
	jsr	$ffd2		;   putchar('-');                              \
	ldy @w	\temp		;                                              \
	dey			;                                              \
	bne	-		;  }                                           \
+	lda	#\mjoin		; }                                            \
	jsr	$ffd2		; putchar(mjoin);                              \
	lda	#$60		;                                              \
	jsr	$ffd2		; putchar('-');                                \
	lda	#\rjoin		;                                              \
	jsr	$ffd2		; putchar(rjoin);                              \
	.endm			;} // rule

putgrid	.macro	gridarr		;#define putgrid(gridarr) {                    \
	pha	;//V0LOCAL=i	;void hal_(void) {                             \
	pha	;//V1LOCAL=r	; uint8_t i, r;                                \
;	txa			;                                              \
;	pha	;//V2LOCAL=x	; uint8_t V2LOCAL = x;                         \
	rule	ZP,$b0,$b2,$ae	; rule(ZP, 0xb0, 0xb2, 0xae);                  \
	ldy	#0		;                                              \
	sty @w	V0LOCAL	;//i	; i = 0;                                       \
	lda	#GRIDH		;                                              \
	sta @w	V1LOCAL	;//r	; for (r = GRIDH; r; r--) {                    \
-	lda	#$0d		;  register uint8_t y;                         \
	jsr	putchar		;                                              \
-	lda	#$7d		;  for (putchar('\n');(y=i)<GRIDSIZ;i+=GRIDH) {\
	jsr	putchar		;   putchar('|');
	lda @w	V0LOCAL	;//i	;	
	tay			;
	clc			;
	adc	#GRIDH		;
	sta @w	V0LOCAL	;//i	;
	cmp	#GRIDSIZ	;
	bcs	+++		;
	lda	\gridarr,y	;
	pha	;//V2LOCAL=temp	;   int8_t temp = gridarr[y];
	bpl	+		;   if (temp < 0) { // absorber, drawn as black
	ldy	#VIDEOK		;
	lda	petscii,y	;
	jsr	putchar		;    putchar(petscii[VIDEOK]);
	jmp	++		;
	beq	++		;   } else if (temp > 0) {
+	lsr			;
	lsr			;
	lsr			;
	lsr			;
	and	#$03		;
	tay			;    y = (temp & 0x70) >> 4;
	
	rule	ZP,$ab,$7b,$b3	;  rule(ZP, 0xab, 0x7b, 0xb3);
	dec @w	V1LOCAL	;//r	;
	bne	-		; }


;	pla			;
;	tax			;
	POPVARS			;
	.endm			;} // putgrid

petscii	.byte	$,$,$,$		;
	.byte	$,$,$,$		;
	.byte	$,$,$,$		;
	.byte	$,$,$,$		;
hal_try putgrid	HID_GRID	;
	rts			;
hal_hid
hal_msg
hal_lbl
hal_msh
	rts			;
hal_cel
	rts

inputkb
	POPVARS
	rts

hal_inp

main	tsx			;
	;; set background color
	sec			;
	jsr	inigrid		;
	clc			;
	jsr	inigrid		;
	FUNCALL			;
	lda	#DRW_ALL	;
	jsr	visualz		;
	FUNRETN			;
	rts			;

pre_end
.align $10
vararea
.end

