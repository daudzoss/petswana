.include "6502apcs.inc"

;;; we generally use "tint" for the beam, initially transparent, moving through
;;;  a grid and changing properties along the way;"color" for a commodore screen

;;; "#define x(a,b) {}" without a return type: macro expansion in situ
;;; "inline register uint8_t" return type: returned in A and/or Y (non-APCS jsr)
;;; "register uint8_t" return type: returned in Y
;;; "uint8_t" return type: stuffed back into A0LOCAL of caller

;;; "lda #1 : ldy #2 : jsr f" function taking args in, and returning in, A and Y
;;; "ldy #1 : jsrAPCS f" function taking an arg in A=Y and returning value in Y
;;; "ldy #1 : jsrAPCS f,lda,#2" function taking args in A and Y and returning Y
;;;
;;; in the first jsrAPCS example, the flags at the entry into f() are set per Y
;;; in the second jsrAPCS example, the  "    "  "    "     "   "   "   "   "  A

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

;;; 10x8 playfield: labeled 1-10 on top, 11-18 on right, A-H on left, I-R on bot
GRIDW	= $0a
GRIDH	= $08
GRIDSIZ	= GRIDW*GRIDH		; sizeof(HIDGRID); sizeof(TRYGRID);
ANSWERS	= 2*GRIDH + 2*GRIDW	; sizeof(PORTALS); sizeof(PORTINT);

HIDGRID	= vararea + $00
TRYGRID	= vararea + GRIDSIZ
PORTALS	= vararea + 2*GRIDSIZ
PORTINT	= vararea + 2*GRIDSIZ + ANSWERS
OTHRVAR	= vararea + 2*GRIDSIZ + 2*ANSWERS

;;; HIDGRID[] and TRYGRID[]:
;;; a cell in a grid has a 7-bit state, representing the residing object portion
;;;	7	6	5	4	|	3	2	1	0
;;; {UNTINTD=0;TINT*=1,2,3,4;ABSORBD=8}	{marker in TRY}	{BLANK=0;CHAMF;SQUARE=7}

;;; PORTALS[]:
;;; each of the ANSWERS indices indicates which index a beam shone into the grid
;;; there exits, itself in case of bouncing perpendicularly back off an obstacle
;;; 0 if not yet tested
;;; or <0 if absorbed before bouncing (in which case bit 4 of its PORTINT[] == 0
;;;	7	6	5	4	|	3	2	1	0
;;; {ABSORBD}		{33~50 for A~R,                         1~18 for 1~18}

;;; PORTINT[]:
;;; each of the ANSWERS indices indicates which tint enters/exits from there

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

start

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
;;; 
;;; an X marker in TRYGRID (0x08) confirming no obstacle actually would block a
;;; beam but we only trace beams inside HIDGRID; TRYGRID markers are effectively
;;; apertures cut in a TRYGRID cell that allow HIDGRID to show through as X or O
BLANK	= 0			; nothing in the cell to block an incident beam
CHAMFBR	= 1			; triangular reflector, chamfer at bottom right
CHAMFBL	= 2			;      "        "     , chamfer at bottom left
CHAMFTL	= 3			;      "        "     , chamfer at top left
CHAMFTR = 4			;      "        "     , chamfer at top right
;BOREDLR	= 5			; transmits left-right but rebounds top-bottom
;BOREDTB	= 6			; transmits top-bottom but rebounds left-right
SQUARE	= 7			; cell filled in so all four sides will rebound

SOBLANK	= 8			; marker (in TRYGRID only) that blank confirmed
SOFILLD	= 9			; marker (in TRYGRID only) that object confirmed

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

main	tsx	;//req'd by APCS;int main(void) {
.if SCREENW && SCREENH
	lda	#VIDEOBG	; if (SCREENW && SCREENH) // addressable screen
	sta	BKGRNDC		;  BKGRNDC = VIDEOBG;
.endif
	lda	#$00		; for (register uint8_t y = ANSWERS; y; y--) {
	ldy	#ANSWERS	;  // bits 5~0 where a beam into this one exits
-	sta	PORTALS-1,y	;  PORTALS[y-1] = 0; // no beam entry/exit yet
	sta	PORTINT-1,y	;  // bits 3~0 tint reflected, or bit 4 absorbed
	dey			;  PORTALS[y-1] = 0; // no beam entry/exit yet
	bne	-		; }
	clc	;TRYGRID	;
	jsr	inigrid		;
	jsrAPCS	rndgrid		;
	lda	#DRW_ALL|DRW_HID;
	jsrAPCS	visualz		;
	rts			;} // main()
	
;;; when the beam is about to leave the cell a[6:0],
;;; travelling in the direction c:a[7],
;;; return nonzero if it will exit the grid and processing should stop
portal	pha	;//gridi	;register uint6_t portal(register uint9_t a){//!
	ror			; uint8_t gridi = a & 0xff;
	and	#%1100 .. %0000	;
	pha	;//travd	; uint8_t travd = (a >> 1) & 0xc0; //FROM_* << 6
	ldy	#0		; register uint8_t y = 0;
	lda @w	V0LOCAL	;//gridi;
	and	#%0111 .. %1111	;
	sta @w	V0LOCAL	;//gridi; gridi &= 0x7f; // no more H/V bit in bit 7?
	
	bne	+++		; if (gridi == 0) { // upper-left corner
	lda @w	V1LOCAL	;//travd;
	bne	+		;  if ((travd >> 6) == FROM_RT)
	ldy	#'a' ^ $60	;   return y = 0x21; // A
	jmp	portaly		;
+	cmp	#FROM_BT << 6	;
	beq	+		;
	jmp	portaly		;  else if ((travd >> 6) == FROM_BT)
+	ldy	#1		;   return y = 0x01; // 1
	jmp	portaly		;  else return y = 0;

+	cmp	#7		;
	bne	+++		; } else if (gridi == 7) { // lower-left corner
	lda @w	V1LOCAL	;//travd;
	bne	+		;  if ((travd >> 6) == FROM_RT)
	ldy	#'h' ^ $60	;   return y = 0x28; // H
	jmp	portaly		;
+	cmp	#FROM_TP << 6	;
	beq	+		;
	jmp	portaly		;  else if ((travd >> 6) == FROM_TP)
+	ldy	#'i' ^ $60	;   return y = 0x29; // I
	bne	portaly		;  else return y = 0;

+	cmp	#$48		;
	bne	++		; } else if (gridi == 72) {// upper-right corner
	lda @w	V1LOCAL	;//travd;
	cmp	#FROM_LT << 6	;
	bne	+		;  if ((travd >> 6) == FROM_LT)
	ldy	#$0b		;   return y = 11; // 11
	bne	portaly		;
+	cmp	#FROM_BT << 6	;
	bne	portaly		;  else if ((travd >> 6) == FROM_BT)
	ldy	#$0a		;   return y = 10; // 10
	bne	portaly		;

+	cmp	#$4f		;
	bne	++		; } else if (gridi == 79) {// lower-right corner
	lda @w	V1LOCAL	;//travd;
	cmp	#FROM_LT << 6	;
	bne	+		;  if ((travd >> 6) == FROM_LT)
	ldy	#$12		;   return y = 18; // 18
	bne	portaly		;
+	cmp	#FROM_TP	;
	bne	portaly		;  else if ((travd >> 6) == FROM_TP)
	ldy	#'r' ^ $60	;   return y = 0x32; // R
	bne	portaly		;  else return y = 0;

+	cmp	#8	 	; 
	bcs	+		; } else if (gridi < 8) // leftmost column, 1~6
	lda @w	V1LOCAL	;//travd;
	bne	portaly		;  if ((travd >> 6) == FROM_RT)
	lda @w	V0LOCAL	;//gridi;
	clc			;
	adc	#'a' ^ $60	;   return y = gridi + 0x21; // B~G
	bne	portala		;  else return y = 0;
	
+	cmp	#8*9		;  
	bcc	+		; } else if (gridi >= 72) { // right column, 73~78
	lda @w	V1LOCAL	;//travd;
	cmp	#FROM_LT << 6	;
	bne	portaly		;  if ((travd >> 6) == FROM_LT)
	lda @w	V0LOCAL	;//gridi;
	sec			;
	sbc	#$48 - $0b	;   y = gridi - (72-11); // 12~17
	bne	portala		;  else return y = 0;

+	pha	;//colnm	; }
	lsr @w	V2LOCAL	;//colnm;
	lsr @w	V2LOCAL	;//colnm;
	lsr @w	V2LOCAL	;//colnm; uint8_t colnm = a >> 3; // 0~9

 	and	#$07		;
	bne	+		; if (a & 0x07 == 0) { // topmost row, 0_0
	lda @w	V1LOCAL	;//travd;
	cmp	#FROM_BT << 6	;  if ((travd >> 6) == FROM_BT)
	bne	portaly		;
	ldy @w	V2LOCAL	;//colnm;
	iny			;   return y = colnm + 1; // 1~10
	bne	portaly		;  else return y = 0;

+	cmp	#$07		;
	bne	portaly		; } else if (a & 0x07 == 7) // bottom row, 0_7
	lda @w	V1LOCAL	;//travd;
	cmp	#FROM_TP << 6	;  if ((travd >> 6) == FROM_TP)
	bne	portaly		;
	lda @w	V2LOCAL	;//colnm;
	clc			;
	adc	#'i' ^ $60	;   return y = colnm + 0x29; // J~Q
portala	tay			;  else return y = 0;
portaly	POPVARS			; }
	rts			;} // portal()

;//1~18(1~0x12),A~R(0x21~0x32) to PORTALS index
bportal	

;//PORTALS index <ANSWERS to grid index <GRIDSIZ
bindex	

toalpha	and	#%001 .. %11111	;inline register int8_t toalpha(
	clc			; register int8_t a) {
	adc	#%001 .. %00000	; return a = (a < 0x20) ? a :
	and	#%010 .. %11111	;                         a - 0x20 + 0x40; //A-I
	rts			;} // toalpha()

waybeam	pha	;//orign	;register uint8_t waybeam(register int8_t a) {
	pha	;//wavef	; uint8_t wavef, orign = y;
	and	#$40		;
	php			;
	lda @w	V0LOCAL	;//orign;
	plp			;
	beq	++		; if (orign & 0x40) { // letter A~H,I-R on LT,BT
	cmp	#'i'		;
	bcc	+		;  if (origin >= 'i')
	lda	#FROM_BT<<6	;   wavef = FROM_BT<<6; // 01000000
	bne	gotbeam		;  else
+	lda	#FROM_LT<<6	;   wavef = FROM_LT<<6; // 10000000
	bne	gotbeam		;
+	cmp	#$0b		; } else { // number 1-10,11-18 on TP,RT
	bcs	+		;  if (origin < 11)
	lda	#FROM_TP<<6	;   wavef = FROM_TP<<6; // 11000000
	bne	gotbeam		;  else
+	lda	#FROM_RT<<6	;   wavef = FROM_RT<<6; // 00000000
gotbeam	sta @w	V1LOCAL	;//wavef; }
	ldy @w	V0LOCAL		;
	jsrAPCS	bportal		; y = bportal(orign); // get its PORTALS[] index
	bmi	badbeam		; if (y < 0) return y=?;
	jsrAPCS	bindex		; y = bindex(y); // from which a HIDGRID[] index
	bmi	badbeam		; if (y < 0) return y=?;

	



	
badbeam	ldy	#$ff		;
	POPVARS			;
	rts			;
	
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

;;; color-memory codes for addressable screens
.if SCREENW && SCREENH
commodc	.byte	VIDEOBG
	.byte	VIDEOR				;1
	.byte	VIDEOY				;2
	.byte	VIDEOO				;3
	.byte	VIDEOB				;4
	.byte	VIDEOP				;5
	.byte	VIDEOG				;6
	.byte	VIDEOBK				;7
	.byte	VIDEOW				;8
	.byte	VIDEOLR				;9
	.byte	VIDEOLY				;10
	.byte	VIDEOLO				;11
	.byte	VIDEOLB				;12
	.byte	VIDEOLP				;13
	.byte	VIDEOLG				;14
	.byte	VIDEOGY				;15
	
;;; putchar()-printable dummy color codes for generic terminal-mode platforms
petscii	.byte	$,$,$,$		;static uint8_t petscii[] = {0, 0, 0, 0,
	.byte	$,$,$,$		;                            0, 0, 0, 0,
	.byte	$,$,$,$		;                            0, 0, 0, 0,
	.byte	$,$,$,$		;                            0, 0, 0, 0};
.else
;;; puttchar()-printable color codes for terminal-mode on color platforms // c64
petscii	.byte	$90,$05,$1c,$9f	;static uint8_t petscii[] = {0x90,0x5,0x1c,0x9f,
	.byte	$9c,$1e,$1f,$9e	; 0x9c,0x1e,0x1f,0x9e  //BLK,WHT,RED,CYN,PUR,GRN
	.byte	$81,$85,$96,$97	; 0x81,0x85,0x96,0x97,     //BLU,YEL,ORA,BRN,LRD
	.byte	$98,$99,$9a,$9b	; 0x98,0x99,0x9a,0x9b};    //GY1,GY2,LGR,LBL,GY3
.endif
RVS_ON	= $12
RVS_OFF	= $92
	
DRW_CEL	= 1<<0			;
DRW_TRY	= 1<<3			;
DRW_HID	= 1<<4			;
DRW_MSG	= 1<<5			;
DRW_LBL	= 1<<6			;
DRW_MSH	= 1<<7			;
DRW_ALL	=DRW_MSH|DRW_LBL|DRW_MSG;
vis_cel	.byte	DRW_CEL		;
vis_try	.byte	DRW_TRY		;
vis_hid	.byte	DRW_HID		;
vis_msg	.byte	DRW_MSG		;
vis_lbl	.byte	DRW_LBL		;
vis_msh	.byte	DRW_MSH		;

visualz	pha	;//V0LOCAL=what	;void visualz(register uint8_t a, uint4_t x0,
	bit	vis_msh		;                                 uint4_t y0) {
	beq	+		; if (a & DRW_MSH) {
	jsrAPCS	hal_msh		;  hal_msh(a);
	lda @w	V0LOCAL		; }
+	bit	vis_lbl		;
	beq	+		; if (a & DRW_LBL) {
	jsrAPCS	hal_lbl		;  hal_lbl(a);
	lda @w	V0LOCAL		; }
+	bit	vis_msg		;
	beq	+		; if (a & DRW_MSG) {
	jsrAPCS	hal_msg		;  hal_msg(a);
	lda @w	V0LOCAL		; }
+	bit	vis_hid		;
	beq	+		; if (a & DRW_HID) {
	jsrAPCS	hal_hid		;  hal_hid(a);
	lda @w	V0LOCAL		; }
+	bit	vis_try		;
	beq	+		; if (a & DRW_TRY) {
	jsrAPCS	hal_try		;  hal_try(a);
	lda @w	V0LOCAL		; }
+	bit	vis_cel		;
	beq	+		; if (a & DRW_CEL) {
	lda	A1FUNCT		;
	sta @w	V0LOCAL	;//y0	;
	lda	A0FUNCT		;
	pha	;//V1LOCAL=x0	;
	jsrAPCS	hal_cel		;  hal_cel(x0, y0);
+	POPVARS			; }
	rts			;} // visualz()

.if SCREENW >= $50
hal_try
hal_hid
hal_msg
hal_lbl
hal_msh
hal_cel	rts
.elsif SCREENW >= $28
hal_try
hal_hid
hal_msg
hal_lbl
hal_msh
hal_cel	rts
.elsif SCREENW >= $16
hal_try
hal_hid
hal_msg
hal_lbl
hal_msh
hal_cel	rts
.else
putchar	tay			;inline void putchar(register uint8_t a) {
	txa			; // a stashed in y
	pha			; // x stashed on stack, by way of a
	tya			; // a restored from y
	jsr	$ffd2		; (* ((*)(uint8_t)) 0xffd2)(a);
	pla			;
	tax			; // x restored from stack, by way of a
	rts			;} // putchar()

rule	.macro	temp,lj,mj,rj	;#define rule(temp,lj,mj,rj) {                 \
	lda	#$0d		;                                              \
	jsr	putchar		; putchar('\n');                               \
	lda	#\lj		;                                              \
	jsr	putchar		; putchar(lj);                                 \
	lda	#$60		;                                              \
	jsr	putchar		; putchar('-');                                \
	ldy	#GRIDW		;                                              \
	cpy	#3		;                                              \
	bcc	+		; if (GRIDW > 2) {                             \
	dey			;                                              \
	dey			;                                              \
-	tya			;                                              \
	sta @w	\temp		;  for (temp = GRIDW - 2; temp; --temp) {      \
	lda	#\mj		;                                              \
	jsr	putchar		;   putchar(mj);                               \
	lda	#$60		;                                              \
	jsr	putchar		;   putchar('-');                              \
	lda @w	\temp		;                                              \
	tay			;                                              \
	dey			;                                              \
	bne	-		;  }                                           \
+	lda	#\mj		; }                                            \
	jsr	putchar		; putchar(mj);                                 \
	lda	#$60		;                                              \
	jsr	putchar		; putchar('-');                                \
	lda	#\rj		;                                              \
	jsr	putchar		; putchar(rj);                                 \
	.endm			;} // rule

putgrid	.macro	gridarr		;#define putgrid(gridarr) {                    \
	pha	;//V0LOCAL=i	; uint8_t i;                                   \
	pha	;//V1LOCAL=r	; uint8_t r;                                   \
	pha	;//V2LOCAL=temp	; uint8_t temp;                                \
	ldy	#VIDEOGY	;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		; putchar(petscii[VIDEOGY]);                   \
	rule V2LOCAL,$b0,$b2,$ae; rule(temp, 0xb0, 0xb2, 0xae) ;               \
	lda	#0		;                                              \
	sta @w	V0LOCAL	;//i	; i = 0;                                       \
	lda	#GRIDH		;                                              \
	sta @w	V1LOCAL	;//r	; for (r = GRIDH; r; r--) {                    \
-	lda	#$0d		;  register uint8_t y;                         \
	jsr	putchar		;                                              \
-	lda	#$7d		;  for (putchar('\n');(y=i)<GRIDSIZ;i+=GRIDH) {\
	jsr	putchar		;   putchar('|');                              \
	lda @w	V0LOCAL	;//i	;                                              \
	cmp	#GRIDSIZ	;                                              \
	bcs	+++++		;                                              \
	tay			;                                              \
	clc			;                                              \
	adc	#GRIDH		;                                              \
	sta @w	V0LOCAL	;//i	;                                              \
	lda	\gridarr,y	;                                              \
	sta @w	V2LOCAL	;//temp	;   temp = gridarr[y];                         \
	bpl	+		;   if (temp < 0) { // absorber, drawn as black\
	ldy	#VIDEOBK	;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		;    putchar(petscii[VIDEOBK]);                \
	jmp	++		;                                              \
+	lsr			;                                              \
	lsr			;                                              \
	lsr			;                                              \
	lsr			;                                              \
	beq	+		;   } else if (temp >= 0x10) {// nontransparent\
	tay			;                                              \
	sec			;    // 0x1_ => 0x01 => 1<<(1-1) == 1==MIXTRED \
	lda	#0		;    // 0x2_ => 0x02 => 1<<(2-1) == 2==MIXTYEL \
-	rol			;    // 0x3_ => 0x03 => 1<<(3-1) == 4==MIXTBLU \
	dey			;    // 0x4_ => 0x04 => 1<<(4-1) == 8==MIXTWHT \
	bne	-		;                                              \
	tay			;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		;    putchar(petscii[1<<(((temp&0x70)>>4)-1)]);\
+	lda @w	V2LOCAL	;//temp	;   }                                          \
	and	#$0f		;   register uint8_t a = temp & 0x0f;          \
	bne	+		;   if (a == 0) {                              \
	lda	#' '		;    a = ' ';                                  \
	bne	++		;   } else { // FIXME: check bit 3 for 'X'/'O' \
+	lda	#RVS_ON		;                                              \
	jsr	putchar		;    putchar(RVS_ON);                          \
	lda @w	V2LOCAL	;//temp	;                                              \
	and	#$0f		;                                              \
	ora	#$30		;                                              \
	cmp	#'9'+1		;                                              \
	bcc	+		;                                              \
	clc			;    a = '0' | ((a <= 9) ? a : (a+'a'-'9'-1)); \
	adc	#'a'-'9'-1	;   }                                          \
+	jsr	putchar		;   putchar(a);                                \
	lda	#RVS_OFF	;                                              \
	jsr	putchar		;   putchar(RVS_OFF);                          \
	ldy	#VIDEOGY	;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		;   putchar(petscii[VIDEOGY]);                 \
	jmp	--		;  }putchar('|');                              \
+	lda @w	V0LOCAL	;//i	;                                              \
	and	#GRIDH-1	;                                              \
	clc			;                                              \
	adc	#1		;                                              \
	sta @w	V0LOCAL	;//i	;  i = (i & (GRIDH-1)) + 1;                    \
	dec @w	V1LOCAL	;//r	;  if (r == 1) // no draw interior joints last \
	beq	+		;   break;                                     \
	rule V2LOCAL,$ab,$7b,$b3;  rule(temp, 0xab, 0x7b, 0xb3);               \
	jmp	---		; }                                            \
+	rule V2LOCAL,$ad,$b1,$bd; rule(temp, 0xad, 0xb1, 0xb3);                \
	POPVARS			;                                              \
	.endm			;} // putgrid

hal_try putgrid	TRYGRID		;
	rts			;
hal_hid putgrid	HIDGRID		;
	rts			;
hal_msg
hal_lbl
hal_msh
	rts			;
hal_cel
	rts
.endif

inputkb
	POPVARS
	rts

hal_inp

.if RNDLOC1 && RNDLOC2
rndgrid	sec	;HIDGRID	;void rndgrid(void) {
	jsr	inigrid		; inigrid(1);
.else
cangrid	.byte	$,$,$,$		;static uint8_t cangrid[] = {0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0,
	.byte	$,$,$,$		; 0x0, 0x0, 0x0, 0x0};
rndgrid	ldy	#GRIDSIZ	;void rndgrid(void) {
-	lda	cangrid-1,y	; for (register uint8_t y = GRIDSIZ; y; y--) {
	sta	HIDGRID-1,y	;  // not very random, it turns out:
	dey			;  HIDGRID[y-1] = cangrid[y-1];
	bne	-		; }
.endif
	rts			;} // rndgrid()

pre_end
.align $10
vararea
.end

