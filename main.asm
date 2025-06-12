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
;;; basically the value of the wavefront below but sign-extended from 5-bit to 8

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
ODBOUNC	= %01			; as if off a wall running top left,bottom right
RABOUNC	= %10			; whence ye came
EVBOUNC	= %11			; as if off a wall running top right,bottom left
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
BLANK	= $0			; nothing in the cell to block an incident beam
CHAMFBR	= $1			; triangular reflector, chamfer at bottom right
CHAMFBL	= $2			;      "        "     , chamfer at bottom left
CHAMFTL	= $3			;      "        "     , chamfer at top left
CHAMFTR = $4			;      "        "     , chamfer at top right
BOREDLR	= $5			; transmits left-right but rebounds top-bottom
BOREDTB	= $6			; transmits top-bottom but rebounds left-right
SQUARE	= $7			; cell filled in so all four sides will rebound
SOBLANK	= $8			; marker (in TRYGRID only) that blank confirmed
SOFILLD	= $9			; marker (in TRYGRID only) that object confirmed

;;; upper nybble of grid square absorbs/reflects beam, optionally imparting tint
UNTINTD	= $0			; no tint change: blank cell or transparent refl
TINTRED	= $1			; a red-tinted object sets beam TINTRED-1th bit
TINTYEL	= $2			; " yellow- "     "     "    "  TINTYEL-1th  "
TINTBLU	= $3			; " blue-   "     "     "    "  TINTBLU-1th  "
TINTWHT	= $4			; " white-  "     "     "    "  TINTWHT-1th  "
ABSORBD	= $8			; perfect blackbody, no further travel of a beam
RUBRED	= TINTRED .. %0000
RUBYEL	= TINTYEL .. %0000
RUBBLU	= TINTBLU .. %0000
RUBWHT	= TINTWHT .. %0000
RUBOUT	= ABSORBD .. %0000

;;; beam spectrum bit values, reflecting a tint mixture after multiple rebounds
UNMIXED = 0
MIXTRED	= 0 | 0 | 0 | 1 << (TINTRED - 1)	;1
MIXTYEL	= 0 | 0 | 1 << (TINTYEL - 1) | 0	;2
MIXTORN	= 0 | 0 | MIXTRED | MIXTYEL		;3
MIXTBLU	= 0 | 1 << (TINTBLU - 1) | 0 | 0	;4
MIXTPUR	= 0 | MIXTBLUE | 0 | MIXTRED		;5
MIXTGRN	= 0 | MIXTBLU | MIXTYEL	| 0		;6
MIXTBRN	= 0 | MIXTBLU | MIXTYEL | MIXTRED	;7
MIXTWHT	= 1 << (TINTWHT - 1) | 0 | 0 | 0	;8
MIXT_LR	= MIXTWHT | 0 | 0 | MIXTRED		;9
MIXT_LY	= MIXTWHT | 0 | MIXTYEL	| 0		;10
MIXT_LO	= MIXTWHT | 0 | MIXTYEL | MIXTRED	;11
MIXT_LB	= MIXTWHT | MIXTBLU | 0 | 0		;12
MIXT_LP	= MIXTWHT | MIXTBLU | 0 | MIXTRED	;13
MIXT_LG	= MIXTWHT | MIXTBLU | MIXTYEL | 0	;14
MIXTGRY	= MIXTRED | MIXTYEL | MIXTBLU | MIXTWHT ;15
MIXTOFF	= $f << 4				;16

DRW_CEL	= 1<<0			;
DRW_TRY	= 1<<3			;
DRW_HID	= 1<<4			;
DRW_MSG	= 1<<5			;
DRW_LBL	= 1<<6			;
DRW_MSH	= 1<<7			;
DRW_ALL	=DRW_MSH|DRW_LBL|DRW_MSG;

shinein	pha	;//iport	;register uint8_t shinein(register uint8_t a) {
	jsr	bportal		; uint8_t iport = y, i_idx, oport, o_idx;
	tya			;
	pha	;//i_idx	; i_idx = bportal(y); //PORTINT[],PORTALS[]
	lda	PORTALS,y   	; if (PORTALS[i_idx])
	bne	++		;  return PORTALS[i_idx]; // won't have changed!
	ldy @w	V0LOCAL	;//iport;
	jsrAPCS	waybeam		;
	tya			;
	pha	;//oport	; oport  = waybeam(iport);
	bpl	+		; if (oport & RUBOUT) { // sign bit, absorbed
	ldy @w	V1LOCAL	;//i_idx; 
	lda	#MIXTOFF	;
	sta	PORTINT,y	;  PORTINT[i_idx] = MIXTOFF;
	lda	#RUBOUT		;
	sta	PORTALS,y	;  PORTALS[i_idx] = RUBOUT;
	jmp	++		; } else { // waybeam set PORTINT[o_idx] already
+	jsr	bportal		;
;	tya			;
;	pha	;//o_idx	;  o_idx = bportal(oport); //PORTINT[],PORTALS[]
	lda @w	V0LOCAL	;//iport;
	sta	PORTALS,y	;  PORTALS[o_idx] = iport; // out linked to in
	lda	PORTINT,y	;
	ldy @w	V1LOCAL	;//i_idx;
	sta	PORTINT,y	;  PORTINT[i_idx] = PORTINT[o_idx]; // same tint
	lda @w	V2LOCAL	;//oport;
	sta	PORTALS,y	;  PORTALS[i_idx] = oport; // in linked to out
+	tay			; }
	POPVARS			; return y = PORTALS[i_idx];
	rts			;} shinein()

waybeam	pha	;//orign	;register uint8_t waybeam(register int8_t a) {
	pha	;//wavef	; uint8_t wavef, orign = a;
	and	#$20		; register uint8_t y;
	php			; register uint9_t a;
	lda @w	V0LOCAL	;//orign;
	plp			;
	beq	++		; if (orign & 0x20) { // letter A~H,I-R on LT,BT
	cmp	#'i' ^ $60	;
	bcc	+		;  if (origin >= 0x28)
	lda	#FROM_BT << 6	;   wavef = 0x40; // 01000000
	bne	gotbeam		;  else
+	lda	#FROM_LT << 6	;   wavef = 0x80; // 10000000
	bne	gotbeam		;
+	cmp	#$0b		; } else { // number 1-10,11-18 on TP,RT
	bcs	+		;  if (origin < 11)
	lda	#FROM_TP << 6	;   wavef = 0xc0; // 11000000
	bne	gotbeam		;  else
+	lda	#FROM_RT << 6	;   wavef = 0x00; // 00000000
gotbeam	sta @w	V1LOCAL	;//wavef; }
	lda @w	V0LOCAL	;//orign;
	jsr	bportal		; y = bportal(orign); // letter/number to 0~35
	jsr	bindex		; y = bindex(y); // beam's start in HIDGRID[]
	pha	;//oldy		; do { // check cell by cell as the beam travels
	pha	;//bump		;
	pha	;//oldir	;  uint8_t oldy, bump, oldir;
propag8	tya			;  register uint1_t c;
	sta @w	V2LOCAL	;//oldy	;  oldy = y;
.if 0
	jsrAPCS	putcell		;  y = putcell(y); // y preserved
.endif
	lda	HIDGRID,y	;  // imagine we're on the FROM_ edge of cell y
	bpl	+		;
	jmp	deadend		;  if ((HIDGRID[y] >> 4) & RUBOUT == 0) { // on
+	beq	+		;   if (HIDGRID[y]) { // hit something in cell y
	sta @w	V3LOCAL	;//bump	;    bump = HIDGRID[y];//H nyb tint, L nyb shape
.if 0
	ldy @w	V1LOCAL	;//wavef;
	jsrAPCS	putwave		;    y = putwave(wavef); // y preserved
	lda	#','		;
	jsr	putchar		;
	lda @w	V3LOCAL	;//bump	;    bump = HIDGRID[y];//H nyb tint, L nyb shape
.endif
	lsr			;
	lsr			;
	lsr			;
	lsr			;
	tay			;    y = bump >> 4; // tint added by a collision
	iny			;
	clc			;
	lda	#%1000 .. %0000	;
-	rol			;
	dey			;
	bne	-		;
	ora @w	V1LOCAL	;//wavef;
	sta @w	V1LOCAL	;//wavef;    wavef |= y ? (1 << (y-1)) : 0; // set tint
	rol			;
	rol			;
	rol			;
	and	#%0000 .. %0011	;
	sta @w	V4LOCAL	;//oldir;    oldir = wavef >> 6; // pre-bounce direction
	lda @w	V3LOCAL	;//bump	;
	and	#%0000 .. %0111	;
	tay			;
	lda	bounces,y	;
	ldy @w	V4LOCAL	;//oldir;
	iny			;
	rol			;
	rol			;
-	ror			;    
	ror			;
	dey			;
	bne	-		;
	and	#%0000 .. %0011	;
	ror			;
	ror			;
	ror			;
	eor @w	V1LOCAL	;//wavef;    // deflected using xor of bounces[] element
	sta @w	V1LOCAL	;//wavef;    wavef^=((bounces[bump&7]>>(oldir*2))&3)<<6;
.if 0
	tay			;
	jsrAPCS	putwave		;    y = putwave(wavef); // y preserved
	jsr	getchar		;    getchar(); // dealing with infinite bounces
.endif
	ldy @w	V2LOCAL	;//oldy	;    y = oldy;
+	tya			;   }
	lsr			;   c = y & 1;
	sta @w	V2LOCAL	;//oldy	;   oldy = y >> 1;
	lda @w	V1LOCAL	;//wavef;   // check if exit whether it deflected or not
	and	#%1100 .. %0000	;
	ora @w	V2LOCAL	;//oldy ;   // travel direction .. HIDGRID[] index
	rol			;   a = ((uint9_t)(wavef&0xc0)<<1)|(oldy<<1)|c;
	sta @w	V2LOCAL	;//oldy	;   oldy = a & 0x0ff;
	tay			;
	jsrAPCS	portal		;   y = portal(y = a);
	tya			;   if (y) // contains the exit location
	bne	propag9		;    break;
	lda @w	V1LOCAL	;//wavef;
	sta	OTHRVAR		;
	lda @w	V2LOCAL	;//oldy	;
	and	#%0111 .. %1111	;
	bit	OTHRVAR		;
	bmi	++		;   // set y to index of the beam's next cell
	bvs	+		;   if ((wavef >> 6) == FROM_RT) {
	sec 			;
	sbc	#GRIDH		;
	tay			;    y = (oldy & 0x7f) - GRIDH; // next cell LT
	jmp	propag8		;    continue;
+	tay 			;   } else if ((wavef >> 6) == FROM_BT) {   
	dey			;    y = (oldy & 0x7f) - 1; // next cell tw'd TP
	jmp	propag8		;    continue;
+	bvs	+		;   } else if ((wavef >> 6) == FROM_LT) {   
	clc 			;
	adc	#GRIDH		;
	tay			;    y = (oldy & 0x7f) + GRIDH; // next cell RT
	jmp	propag8		;    continue;
+	tay 			;   } else /* if ((wavef >> 6) == FROM_TP) */ {   
	iny			;    y = (oldy & 0x7f) + 1; // next cell tw'd BT
	jmp	propag8		;    continue;
propag9	tya			;   }
	and	#%0011 .. %1111	;  } while (1);
	sta @w	V2LOCAL	;//oldy	;  oldy = y & 0x3f; // identifier of exit cell
	jsr	bportal		;  y = bportal(oldy); // that cell's array index
	lda @w	V1LOCAL	;//wavef;
	and	#%0000 .. %1111	;
	sta	PORTINT,y	;  PORTINT[y] = wavef & 0x0f;
	ldy @w	V2LOCAL	;//oldy	;  y = oldy; // caller must update other portal!
	jmp	endbeam		; } else
deadend	ldy	#$ff		;  y = -1; // struck an absorber and can't leave
endbeam	POPVARS			; return y; // identifier of exit cell
	rts			;} // waybeam()

;;; when the beam is about to leave the grid cell a[6:0],
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
+	cmp	#FROM_TP << 6	;
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

;//1~18(1~0x12),A~R(0x21~0x32) to PORTALS[] or PORTINT[] index
bportal	cmp	#$21		;inline register int6_t bportal(register int6_t
	bcs	+		;                                           a) {
	tay			; if (a < 0x21)
	dey			;  y = a - 1; // 0x01 => 0, 0x12 => 17
	bcc	++		; else
+	;sec			;
	sbc	#$21 - $12	;  y = a - 15; // 0x21 => 18, 0x32 =>  35
	tay			; return y;
+	rts			;} // bportal()

;//PORTALS index <ANSWERS to grid index <GRIDSIZ
bindex	lda	bindice,y	;register uint7_t bindex(register uint6_t y) {
	tay			;
	rts			; static uint7_t bindice[] =
bindice	.byte	$00,$08,$10,$18	; {0x00,0x08,0x10,0x18, // topmost row of 10
	.byte	$20,$28,$30,$38	;  0x20,0x28,0x30,0x38,                   
	.byte	$40,$48,$48,$49	;  0x40,0x48,0x48,0x49, // rightmost column of 8
	.byte	$4a,$4b,$4c,$4d	;  0x4a,0x4b,0x4c,0x4d,
	.byte	$4e,$4f,$00,$01	;  0x4e,0x4f,0x00,0x01,  // leftmost column of 8
	.byte	$02,$03,$04,$05	;  0x02,0x03,0x04,0x05,
	.byte	$06,$07,$07,$0f	;  0x06,0x07,0x07,0x0f   // bottommost row of 10
	.byte	$17,$1f,$27,$2f	;  0x17,0x1f,0x27,0x2f,
	.byte	$37,$3f,$47,$4f	;  0x30,0x3f,0x47,0x4f}; return y = bindice[y];}

inigrid	lda	#0		;inline inigrid(uint1_t c) {
	ldy	#GRIDSIZ	; for (register uint8_t y = GRIDSIZ; y; y--) {
-	bcc	+		;  if (c)
	sta	HIDGRID-1,y	;   HIDGRID[y-1] = 0;
	bcs	++		;  else
+	sta	TRYGRID-1,y	;   TRYGRID[y-1] = 0;
+	dey			;
	bne	-		; }
	rts			;} // inigrid()

placeit	lda	obstcel,y	;register int8_t placeit(register uint8_t y,
	and	#$0f		;   uint8_t colnm /*A0*/, uint8_t rownm /*A1*/,
	cmp @w	A0FUNCT	;//colnm;   uint8_t elems /*A2*/, uint8_t tint /*A3*/) {
	bcs	+		;
	ldy	#$ff		; if (colnm > obstcel[y] & 0x0f)
	bcc	express		;  return y = -1;// tried to place too far right
+	lsr			;
	lsr			;
	lsr			;
	lsr			;
	cmp @w	A1FUNCT	;//rownm;
	bcs	+		;
	ldy	#$fe		; if (rownm > obstcel[y] >> 4)
	bcc	express		;  return y = -2; // tried to place too far down
+	lda @w	A0FUNCT	;//colnm;
	asl			;
	asl			;
	asl			;
	clc			;
	adc @w	A1FUNCT	;//rownm;
	pha	;//V0LOCAL=ygrid; uint8_t ygrid = (colnm << 3) | rownm;
	iny			;
	tya			;
	pha	;//V1LOCAL=head	; uint8_t head = ++y;
	pha	;//V2LOCAL=yelem; uint8_t yelem;
	clc			;
	adc @w	A2FUNCT	;//elems;
	pha	;//V3LOCAL=ovrbd; uint8_t ovrbd = head + elems;
	pha	;//V4LOCAL=temp	; uint8_t temp;
-	lda	obstcel,y	; for (yelem = head; yelem < ovrbd; y++) {
	sta @w	V4LOCAL	;//temp	;  temp = obstcel[yelem];
	and	#%0001 .. %1111 ;
	clc			;
	adc @w	V0LOCAL	;//ygrid;
	tay			;  register uint8_t y = ygrid + (temp & 0x1f);
	lda	HIDGRID,y	;  if (HIDGRID[y]) // conflicting object there!
	bne	punwind		;   goto punwind;
	lda @w	V4LOCAL	;//temp	;
	rol			;
	rol			;
	rol			;
	rol			;
	and	#%0000 .. %0111 ;
	ora @w	A3FUNCT	;//tint	;  else
	sta	HIDGRID,y	;   HIDGRID[y_] = tint | (temp >> 5); // stamped
	inc @w	V2LOCAL	;//yelem;
	lda @w	V2LOCAL	;//yelem;
	tay			;
	cmp @w	V3LOCAL	;//ovrbd;
	bcc	-		; }
	ldy	#0		; return 0; // success
preturn	POPVARS			;
express	rts			;punwind:
punwind
 jsrAPCS hal_try
 jsr	putchar
	ldy @w	V2LOCAL	;//yelem; for (yelem; yelem != head; yelem--) {
	tya			;  register uint8_t y;
	cmp @w	V1LOCAL	;//head	;
	beq	preturn		;
	dec @w	V2LOCAL	;//yelem;
	lda	obstcel-1,y	;
	and	#%0001 .. %1111	;
	clc			;
	adc @w	V0LOCAL	;//ygrid;  y = ygrid + (obstcel[yelem - 1] & 0x1f);
	tay			;  HIDGRID[y] = 0;
	lda	#0		; }
	sta	HIDGRID,y	; return y = head; // guaranteed nonzero
	beq	punwind		;} // placeit()

.if 0;RNDLOC1 && RNDLOC2
rotshap				;//try a new rotation of a shape in the linked list

rndgrid	pha	;V0LOCAL;//next	;void rndgrid(void) {
	pha	;V1LOCAL;//rotn	; uint8_t next, rotn, tint, elems, rownm, colnm;
	pha	;V2LOCAL;//oldy	;
	pha	;V3LOCAL;//tint	;
	pha	;V4LOCAL;//elems;
	pha	;V5LOCAL;//rownm;
	pha	;V6LOCAL;//colnm;
	sec	;HIDGRID	; inigrid(1); // start with HIDGRID blank
	jsr	inigrid		;
	ldy	#0		; register uint8_t y;
-	tya			; for (y = 0; (next=obstlst[y]) != 0; y = next) {
	sta @w	V2LOCAL	;//oldy	;
	lda	obstlst,y	;
	beq	rnddone		;
	sta @w	V0LOCAL	;//next	;
	lda	obstlst+1,y	;
	sta @w	V3LOCAL	;//tint	;  tint = obstlst[+1+y];
	lda	obstlst+2,y	;
	sta @w	V4LOCAL	;//elems;  elems = obstlst[+2+y];
	lda	RNDLOC1		;
	eor	RNDLOC2		;  // random starting rotation since grid blank
	ora 	#%1000 .. %0000	;  // prevent infinite loop by eventual rollover
	and 	#%1000 .. %0011	;
	sta @w	V4LOCAL	;//rotn	;  for (rotn=0x80|(rand()&3);rotn&0x80;rotn++) {
-	and	#%0000 .. %0011	;
	clc			;
	adc @w	V2LOCAL	;//oldy	;
	tay			;
	lda	obstlst+3,y	;
	pha			;   uint8_t temp = obstlst[+3+y + ((rotn++)&3)];
	lda	RNDLOC1		;
	eor	RNDLOC2		;
	and	#%0000 .. %0011 ;
	sta @w	V5LOCAL	;//rownm;   rownm = rand() & 7;
-	lda	RNDLOC1		;   do {
	eor	RNDLOC2		;
	and	#%0000 .. %1111	;
	cmp	#GRIDW		;
	bcs	-		;
	sta @w	V6LOCAL ;//colnm;   } while ((colnm = rand() & 15) >= GRIDW);
	pla			;
	tay			;
	jsrAPCS	placeit		;
	tya			;   if (placeit(temp,colnm,rownm,elems,tint)==0)
	beq	+		;    break;
	inc @w	V4LOCAL	;//rotn	;
	lda @w	V4LOCAL	;//rotn	;
	bmi	--		;  }
	brk			;
+	ldy @w	V0LOCAL	;//next	;
	bne	---		; }
rnddone	POPVARS			;
	rts			;} // rndgrid()

.else
cangrid	.byte	0|CHAMFTL,	0|SQUARE,	0|CHAMFBL,	BLANK
	.byte	BLANK,		BLANK,		RUBOUT|SQUARE,	RUBOUT|SQUARE
	.byte	BLANK,		BLANK,		BLANK,		BLANK
	.byte	BLANK,		BLANK,		BLANK,		BLANK
	.byte	BLANK,		RUBWHT|CHAMFTL,	RUBWHT|CHAMFBL,	BLANK
	.byte	BLANK,		RUBRED|CHAMFTR,	RUBRED|SQUARE,	RUBRED|CHAMFBL
	.byte	RUBWHT|CHAMFTL,	RUBWHT|SQUARE,	RUBWHT|SQUARE,	RUBWHT|CHAMFBL
	.byte	BLANK,		BLANK,		BLANK,		BLANK
	.byte	BLANK,		BLANK,		BLANK,		BLANK
	.byte	RUBWHT|CHAMFTL,	RUBWHT|CHAMFBL,	BLANK,		BLANK
	.byte	BLANK,		BLANK,		BLANK,		BLANK
	.byte	RUBWHT|CHAMFTR,	RUBWHT|CHAMFBR,	BLANK,		BLANK
	.byte	BLANK,		BLANK,		BLANK,		BLANK
	.byte	BLANK,		RUBBLU|CHAMFTL,	BLANK,		BLANK
	.byte	BLANK,		BLANK,		BLANK,		BLANK
	.byte	RUBBLU|CHAMFTL,	RUBBLU|SQUARE,	BLANK,		BLANK
	.byte	RUBYEL|CHAMFTR,	RUBYEL|SQUARE,	BLANK,		BLANK
	.byte	RUBBLU|CHAMFTR,	RUBBLU|SQUARE,	BLANK,		BLANK
	.byte	BLANK,		RUBYEL|CHAMFTR,	BLANK,		BLANK
	.byte	BLANK,		RUBBLU|CHAMFTR,	BLANK,		BLANK
rndgrid	ldy	#GRIDSIZ	;void rndgrid(void) {static uint8_t cangrid[80];
-	lda	cangrid-1,y	; for (register uint8_t y = GRIDSIZ; y; y--) {
	sta	HIDGRID-1,y	;  // not very random, it turns out:
	dey			;  HIDGRID[y-1] = cangrid[y-1];
	bne	-		; }
.endif
	rts			;} // rndgrid()

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

;;; color-memory codes for addressable screens
.if BKGRNDC
commodc	.byte	VIDTEXT		;0
	.byte	VIDEOR		;1
	.byte	VIDEOY		;2
	.byte	VIDEOO		;3
	.byte	VIDEOBL		;4
	.byte	VIDEOP		;5
	.byte	VIDEOG		;6
	.byte	VIDEOBR		;7
	.byte	VIDEOW		;8
	.byte	VIDEOLR		;9
	.byte	VIDEOLY		;10
	.byte	VIDEOLO		;11
	.byte	VIDEOLB		;12
	.byte	VIDEOLP		;13
	.byte	VIDEOLG		;14
	.byte	VIDEOGY		;15
	.byte	VIDEOBK		;16
.endif

frozen

;;; putchar()-printable color codes for terminal-mode on color platforms (vic20)
.if BKGRNDC
petscii	.byte	$98		;static uint8_t petscii[17] = {0x98, // UNMIXED
	.byte	$1c		;/* annotations are UNMIXED */ 0x1c, // MIXTRED
	.byte	$9e		;/* i.e. 0x98 = c16 blu-grn */ 0x9e, // MIXTYEL
	.byte	$81		;/*  and 0x98 = c64 med-gry */ 0x81, // MIXTORN
	.byte	$1f		;                              0x1f, // MIXTBLU
	.byte	$9c		;                              0x9c, // MIXTPUR
	.byte	$1e		;                              0x1e, // MIXTGRN
	.byte	$95		;                              0x95, // MIXTBRN
	.byte	$05		;                              0x05, // MIXTWHT
	.byte	$96		; /* on c16 this is yel-grn */ 0x96, // MIXT_LR
	.byte	$9b		; /* l. g; no l. y. PETSCII */ 0x9b, // MIXT_LY
	.byte	$9f		; /* cyan; no l. o. PETSCII */ 0x9f, // MIXT_LO
	.byte	$9a		; /* on c16 this is d. blue */ 0x9a, // MIXT_LB
	.byte	$9f		; /* cyan; no l. p. PETSCII */ 0x9f, // MIXT_LP
	.byte	$99		; /* on c16 this is l. blue */ 0x99, // MIXT_LG
	.byte	$97		; /* on c16 this is l. red */  0x97, // MIXTGRY
	.byte	$90		; /* universally black */      0x90};// MIXTOFF
.else
;;; putchar()-printable dummy color codes for generic terminal-mode platforms
petscii	.byte   $,$,$,$		;static uint8_t petscii[17] = {0, 0, 0, 0,
	.byte   $,$,$,$		;                              0, 0, 0, 0,
	.byte   $,$,$,$		;                              0, 0, 0, 0,
	.byte   $,$,$,$,$	;                              0, 0, 0, 0, 0};
.endif

;;; putchar()-printable graphics symbols for terminal-mode on all platforms
petsyms	.byte	($20<<1)	;static uint8_t petsyms[] = {0x20<<1,// if BLANK
	.byte	($00<<1)	;                   (0*0xa9<<1)|0, // if CHAMFBR
	.byte	($7f<<1)	;                     (0x7f<<1)|1, // if CHAMFBL
	.byte	($00<<1)|1	;                   (0*0xa9<<1)|1, // if CHAMFTL
	.byte	($7f<<1)|1	;                     (0x7f<<1)|0, // if CHAMFTR
	.byte	($60<<1)|1	;                     (0x60<<1)|1, // if BOREDLR
	.byte	($7d<<1)|1	;                     (0x7d<<1)|1, // if BOREDTB
	.byte	($20<<1)|1	;                     (0x20<<1)|1, // if SQUARE
	.byte	($76<<1)	;                     (0x76<<1)|0, // if SOBLANK
	.byte	($71<<1)	;                     (0x71<<1)|0};// if SOFILLD
RVS_ON	= $12			;// if 0th bit above is 1, will reverse a symbol
RVS_OFF	= $92			;// done for good measure after printing a cell

getchar	txa			;inline uint8_t getchar(void) {
	pha			; // x stashed on stack, by way of a
-	jsr	$ffe4		; do {
	beq	-		;  y = (* ((*)(void)) 0xffe4)();
	tay			; } while (!y);
	pla			; return y;
	tax			; // x restored from stack, by way of a
	rts			;} // getchar()

.if SCREENH && (SCREENW >= $50)
putchar
putcell
putwave
hal_try
hal_hid
hal_msg
hal_lbl
hal_msh
hal_cel	rts
.elsif SCREENH && (SCREENW >= $28)
putchar
putcell
putwave
hal_try
hal_hid
hal_msg
hal_lbl
hal_msh
hal_cel	rts
.elsif SCREENH && (SCREENW >= $16)
putchar
putcell
putwave
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

putcell	pha	;V0LOCAL;//oldy	;register uint8_t putcell(register uint8_t a) {
	lda	#' '		; uint8_t oldy = a;
	jsr	putchar		; putchar(' ');
	lda @w	V0LOCAL	;//oldy	;
	and	#%0000 .. %0111	;
	clc			;
	adc	#'a'		;
	jsr	putchar		; putchar('a' + (0x07 & oldy)); // A~H
	lda @w	V0LOCAL	;//oldy	;
	lsr			;
	lsr			;
	lsr			;
	clc			;
	adc	#'1'		;
	cmp	#'9'+1		;
	bcc	+		; if (oldy >= (9 << 3)) {
	lda	#'1'		;  putchar('1');
	jsr	putchar		;  putchar('0');
	lda	#'0'		; } else {
+	jsr	putchar		;  putchar('1' + (oldy >> 3)); // 1~9
	lda	#':'		; }
	jsr	putchar		; putchar(':');
	ldy @w	V0LOCAL	;//oldy	;
	POPVARS			; return y = oldy;
	rts			;} // putcell()

hexdig	.byte	'0','1','2','3'	;static uint8_t hexdig[] = {'0','1','2','3'
	.byte	'4','5','6','7'	;                           '4','5','6','7'
	.byte	'8','9','a','b'	;                           '8','9','a','b'
	.byte	'c','d','e','f'	;                           'c','d','e','f'};
putwave	pha	;V0LOCAL;//oldy	;register uint8_t putwave(register uint8_t a) {
	lsr			; uint8_t oldy = a;
	lsr			;
	lsr			;
	lsr			;
	tay			;
	lda	hexdig,y	;
	jsr	putchar		; putchar(hexdig[a >> 4]);
	lda @w	V0LOCAL	;//oldy	;
	and	#%0000 .. %1111	;
	tay			;
	lda	hexdig,y	;
	jsr	putchar		; putchar(hexdig[a & 0x0f]);
	ldy @w	V0LOCAL	;//oldy	;
	POPVARS			; return y = oldy;
	rts			;} // putcell()

rule	.macro	temp,lj,mj,rj	;#define rule(temp,lj,mj,rj) {                 \
	lda	#$0d		;                                              \
	jsr	putchar		; putchar('\n');                               \
	lda	#$20		;                                              \
	jsr	putchar		; putchar(' ');                                \
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

putgrid	.macro	gridarr,perimtr	;#define putgrid(gridarr,perimtr) {            \
	pha	;//V0LOCAL=i	; uint8_t i;                                   \
	pha	;//V1LOCAL=r	; uint8_t r;                                   \
	pha	;//V2LOCAL=temp	; uint8_t temp;                                \
	lda	petscii+UNMIXED	;                                              \
	jsr	putchar		; putchar(petscii[UNMIXED]);                   \
	lda	#$0d		;                                              \
	jsr	putchar		; putchar('\n');                               \
	lda	#' '		;                                              \
	jsr	putchar		; putchar(' ');                                \
	lda	#' '		;                                              \
	jsr	putchar		; putchar(' ');                                \
	lda	PORTINT		;                                              \
	and	#%0001 .. %1111	;                                              \
	tay			;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		; putchar(petscii[PORTINT[0] & 0x1f]);         \
	lda	#0		;                                              \
	sta @w	V0LOCAL	;//i	; for (i = 0; i < 9; i++) {                    \
-	clc			;                                              \
	adc	#'1'		;                                              \
	jsr	putchar		;  putchar('1' + i);                           \
	lda	#' '		;                                              \
	jsr	putchar		;  putchar(' ');                               \
	inc @w	V0LOCAL	;//i	;                                              \
	ldy @w	V0LOCAL	;//i	;                                              \
	lda	PORTINT,y	;                                              \
	and	#%0001 .. %1111	;                                              \
	tay			;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		;  putchar(petscii[PORTINT[i+1] & 0x1f]);      \
	lda @w	V0LOCAL	;//i	;                                              \
	cmp	#9		;                                              \
	bcc	-		; }                                            \
	lda	#'1'		;                                              \
	jsr	putchar		; putchar('1');                                \
	lda	#'0'		;                                              \
	jsr	putchar		; putchar('0');                                \
	lda	petscii+UNMIXED	;                                              \
	jsr	putchar		; putchar(petscii[UNMIXED]);                   \
	rule V2LOCAL,$b0,$b2,$ae; rule(temp, 0xb0, 0xb2, 0xae) ;               \
.if SCREENW > $16
	lda	PORTINT+$0b	;                                              \
	and	#%0001 .. %1111	;                                              \
	tay			;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		;  putchar(petscii[PORTINT[i+1] & 0x1f]);      \
	lda	#'1'		;                                              \
	jsr 	putchar		; putchar('1'); //  right-edge label 10's digit\
	lda	petscii+UNMIXED	;                                              \
	jsr	putchar		;  putchar(petscii[UNMIXED]);                  \
.endif
	lda	#0		;                                              \
	sta @w	V0LOCAL	;//i	; i = 0;                                       \
	sta @w	V1LOCAL	;//r	; for (r = 0; r < GRIDH; r++) {                \
-	lda	#$0d		;  register uint8_t y;                         \
	jsr	putchar		;  putchar('\n');                              \
	lda @w	V1LOCAL	;//r	;                                              \
	adc	#GRIDW+GRIDH	;                                              \
	tay			;                                              \
	lda	PORTINT,y	;                                              \
	and	#%0001 .. %1111	;                                              \
	tay			;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		;  putchar(petscii[PORTINT[r+GRIDH+GRIDY]]);   \
	lda @w	V1LOCAL	;//r	;                                              \
	clc			;                                              \
	adc	#'a'		;                                              \
	jsr	putchar		;  putchar('a' + r); // A~H down left side     \
	lda	petscii+UNMIXED	;                                              \
	jsr	putchar		;  putchar(petscii[UNMIXED]);                  \
-	lda	#$7d		;  for (; (y=i) < GRIDSIZ; i+=GRIDH) {         \
	jsr	putchar		;   register uint8_t a;                        \
	lda @w	V0LOCAL	;//i	;   register uint1_t c;                        \
	tay			;                                              \
	cmp	#GRIDSIZ	;   putchar('|');                              \
	bcs	+++++++		;   c = 0;                                     \
	adc	#GRIDH		;   a = ' ';                                   \
	sta @w	V0LOCAL	;//i	;                                              \
	lda	\gridarr,y	;                                              \
	sta @w	V2LOCAL	;//temp	;   temp = gridarr[y];                         \
	bpl	+		;   if (temp < 0) { // absorber, drawn as black\
	lda	petscii+$10	;                                              \
	jsr	putchar		;    putchar(petscii[16]);                     \
	lda	#' '		;                                              \
	jmp	+++++		;    c = 1;                                    \
+	lsr			;                                              \
	lsr			;                                              \
	lsr			;                                              \
	lsr			;                                              \
	tay			;                                              \
	beq	+		;   } else if (temp >= 0x10) {// nontransparent\
	sec			;    // 0x1_ => 0x01 => 1<<(1-1) == 1==MIXTRED \
	lda	#0		;    // 0x2_ => 0x02 => 1<<(2-1) == 2==MIXTYEL \
-	rol			;    // 0x3_ => 0x03 => 1<<(3-1) == 4==MIXTBLU \
	dey			;    // 0x4_ => 0x04 => 1<<(4-1) == 8==MIXTWHT \
	bne	-		;                                              \
	tay			;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		;    putchar(petscii[1<<(((temp&0x70)>>4)-1)]);\
+	lda @w	V2LOCAL	;//temp	;   }                                          \
	and	#%0000 .. %1111	;                                              \
	tay			;   c = petsyms[temp & 0x0f] & 1;              \
	lda	petsyms,y	;   a = petsyms[temp & 0x0f] >> 1;             \
.if !BKGRNDC
	cpy	#SQUARE		;
	bne	+		;
	lda @w	V2LOCAL	;//temp	;
	lsr			;
	lsr			;
	lsr			;
	lsr			;
	tay			;
	lda	#0		;
	sec			;
-	rol			;
	dey			;
	bne	-		;
	tay			;
	lda	tintltr,y	;
	sec			;
	rol			;
.endif
+	lsr			;   if (!a)                                    \
	bne	+		;    a = 0xa9; // only 8-bit stored in petsyms \
	lda	#$a9		;   }                                          \
+	bcc	++		;   if (c) {                                   \
+	pha			;                                              \
	lda	#RVS_ON		;                                              \
	jsr	putchar		;    putchar(RVS_ON);                          \
	pla			;   }                                          \
+	jsr	putchar		;   putchar(a);                                \
	lda	#RVS_OFF	;                                              \
	jsr	putchar		;   putchar(RVS_OFF);                          \
	lda	petscii+UNMIXED	;                                              \
	jsr	putchar		;   putchar(petscii[UNMIXED]);                 \
	jmp	---		;  }putchar('|');                              \
+
.if SCREENW > $17
	lda	#' '		;                                              \
	jsr	putchar		;  putchar(' '); // offset 1's digit diagonally\
	lda @w	V1LOCAL	;//r	;                                              \
	clc			;                                              \
	adc	#$0a		;                                              \
	tay			;                                              \
	lda	PORTINT,y	;                                              \
	and	#%0001 .. %1111	;                                              \
	tay			;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		;                                              \
	lda @w	V1LOCAL	;//r	;                                              \
	clc			;                                              \
	adc	#'1'		;                                              \
	jsr	putchar		;  putchar(r + '1'); // 11~18                  \
	lda	petscii+UNMIXED	;                                              \
	jsr	putchar		;   putchar(petscii[UNMIXED]);                 \
.endif
	lda @w	V0LOCAL	;//i	;                                              \
	and	#GRIDH-1	;                                              \
	clc			;                                              \
	adc	#1		;                                              \
	sta @w	V0LOCAL	;//i	;  i = (i & (GRIDH-1)) + 1;                    \
	inc @w	V1LOCAL	;//r	;  if (r == GRIDH) // no interior joints at bot\
	cmp	#GRIDH		;                                              \
	bcs	+		;   break;                                     \
	rule V2LOCAL,$ab,$7b,$b3;  rule(temp, 0xab, 0x7b, 0xb3);               \
.if SCREENW > $16
	lda @w	V1LOCAL	;//r	;                                              \
	clc			;                                              \
	adc	#$0b		;                                              \
	tay			;                                              \
	lda	PORTINT,y	;                                              \
	and	#%0001 .. %1111	;                                              \
	tay			;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		;                                              \
	lda	#'1'		;                                              \
	jsr 	putchar		; putchar('1'); //  right-edge label 10's digit\
	lda	petscii+UNMIXED	;                                              \
	jsr	putchar		;   putchar(petscii[UNMIXED]);                 \
.endif
	jmp	----		; }                                            \
+	rule V2LOCAL,$ad,$b1,$bd; rule(temp, 0xad, 0xb1, 0xb3);                \
	lda	#$0d		;                                              \
	jsr	putchar		; putchar('\n');                               \
	lda	#' '		;                                              \
	jsr	putchar		; putchar(' ');                                \
	lda	#' '		;                                              \
	jsr	putchar		; putchar(' ');                                \
	lda	#0		;                                              \
	sta @w	V0LOCAL	;//i	; for (i = 0; i < 10; i++) {                   \
-	clc			;
	adc	#GRIDH*2+GRIDW	;
	tay			;
	lda	PORTINT,y	;
	and	#%0001 .. %1111	;                                              \
	tay			;                                              \
	lda	petscii,y	;                                              \
	jsr	putchar		;                                              \
	lda @w	V0LOCAL	;//i	;
	clc			;
	adc	#'i'		;
	jsr	putchar		;  putchar(i);                                 \
	lda	#' '		;                                              \
	jsr	putchar		;  putchar(' ');                               \
	inc @w	V0LOCAL	;//i	;                                              \
	lda @w	V0LOCAL	;//i	;                                              \
	cmp	#$a		;                                              \
	bcc	-		; }                                            \
	lda	petscii+UNMIXED	;                                              \
	jsr	putchar		;   putchar(petscii[UNMIXED]);                 \
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

main	tsx	;//req'd by APCS;int main(void) {
.if !BASIC
	lda	#$0f		; // P500 has to start in bank 15
	sta	$01		; static volatile int execute_bank = 15;
.endif
.if BKGRNDC
	lda	#VIDEOBG	; if (BKGRNDC) // addressable screen
	sta	BKGRNDC		;  BKGRNDC = VIDEOBG;
.endif
	lda	#$00		; for (register uint8_t y = ANSWERS; y; y--) {
	ldy	#ANSWERS	;  // bits 5~0 where a beam into this one exits
-	sta	PORTALS-1,y	;  PORTALS[y-1] = 0; // no beam entry/exit yet
	sta	PORTINT-1,y	;  // bits 3~0 tint reflected, or bit 4 absorbed
	dey			;  PORTINT[y-1] = 0; // no beam entry/exit yet
	bne	-		; }
	clc	;TRYGRID	;
	jsr	inigrid		; inigrid(0);
	jsrAPCS	rndgrid		; rndgrid();
-	ldy	#DRW_ALL|DRW_HID; do { register uint8_t a;
	jsrAPCS	visualz		;  visualz(DRW_ALL|DRW_HID);
	jsr	tempinp		;  a = tempinp();
	beq	+		;  if (a)
	tay			;
	jsrAPCS	shinein		;  
	tya			;
	jsr	tempout		;   tempout(shinein(a));
	jmp	-		; } while(a);
+	rts			;} // main()

.if SCREENW && SCREENH
tempinp rts
tempout rts
.else
tempinp	lda	#$0d		;uint8_t tempinp(void) {
	jsr	putchar		; putchar('\n');
	lda	#'?'		;
	jsr	putchar		; putchar('?');
-	jsr	getchar		; while ((a = getchar()) != DEL_KEY) {
	tya			;
	cmp	#$14		;
	beq	++++		;
	cmp	#'1'		;
	bcc	-		;
	bne	++		;  if (a == '1') {
	jsr	putchar		;   putchar(a);
-	jsr	getchar		;   do {
	tya			;    a = getchar();
	cmp	#$0d		;
	bne	+		;    if (a == '\n')
	lda	#1		;
	rts			;     return 1; // only time a Return is needed
+	cmp	#'0'		;
	bcc	-		;    else if (a >= '0'
	cmp	#'8'+1		;             &&
	bcs	-		;             a <= '8') {
	pha			;
	jsr	putchar		;     putchar(a);
	pla			;
	sec			;     return a-'0' + 10;
	sbc	#'0'-10		;    }
	rts			;   } while (1);
+	cmp	#'9'+1		;
	bcs	+		;  } else if (a > '1' && a <= '9') {
	pha			;
	jsr	putchar		;   putchar(a);
	pla			;
	sec			;
	sbc	#'0'		;
	rts			;   return a-'0';
+	and	#%0101 .. %1111	;
	cmp	#'a'		;
	bcc	--		;  } else if (toupper(a) >= 'a'
	cmp	#'s'		;             &&
	bcs	--		;             tolower(a) <= 'r') {
	pha			;
	jsr	putchar		;   putchar(a);
	pla			;
	sec			;
	sbc	#'a'		;
	clc			;
	adc	#$21		;   return a-'a' + 0x21;
	rts			; }
+	lda	#0		; return 0;
	rts			;} // tempinp()

tempout	pha			;void tempout(uint8_t a) {
	jsr	bportal		;
	lda	PORTINT,y	;
	sta	OTHRVAR		; OTHRVAR = PORTINT[bportal(a)];
	bpl	+		; if (OTHERVAR & MIXTOFF) {
	lda	#RVS_ON		;
	jsr	putchar		;  putchar(RVS_ON);
	lda	petscii+$10	;
	jsr	putchar		;  putchar(petscii[16]);
	lda	#' '		;
	jsr	putchar		;
	lda	#RVS_OFF	;
	jsr	putchar		;  putchar(RVS_OFF);
	jmp	+++++++		;
+	beq	++		; } else if (OTHRVAR) {
	lda	#%0000 .. %1000	;
-	bit	OTHRVAR		;  for (a = 0x08; a; a >>= 1) {
	beq	+		;   if  (OTHVAR & a) {
	pha			;
	lda	#RVS_ON		;
	jsr	putchar		;    putchar(RVS_ON);
	pla			;
	pha			;
	tay			;
	lda	tintltr,y	;
	pha			;
	lda	petscii,y	;
	jsr	putchar		;    putchar(petscii[a]);
	pla			;
	jsr	putchar		;    putchar(tintltr[a]);
	pla			;   }
+	lsr			;
	bne	-		;  }
	beq	++		; } else {
+	lda	#' '		;  putchar(' ');
	jsr	putchar		; }
+	lda	#RVS_OFF	;
	jsr	putchar		; putchar(RVS_OFF);
	lda	petscii+UNMIXED	;
	jsr	putchar		; putchar(petscii[UNMIXED]);
	pla			;
	clc			;
	adc	#$20		;
	and	#$5f		;
	sta	OTHRVAR		;
	bit	OTHRVAR		;
	bvc	+		; if (a > 0x20) { // A~R
	jsr	putchar		;  putchar(a + 0x20);
	rts			;
+	clc			;
	adc	#$30		;
	cmp	#$3a		;
	bcs	+		; } else if (a < 10) { // 1-9
	jsr	putchar		;  putchar(a + 0x30);
	rts			;
+	sec			;
	sbc	#$0a		;
	pha			; } else {
	lda	#'1'		;
	jsr	putchar		;  putchar('1');
	pla			;  putchar(a-10 + 0x30);
	pha			;
	jsr	putchar		; }
+	pla			;
	rts			;} // tempout()
tintltr	.byte	0,'r','y',0	;
	.byte	'b',0,0,0,'w'	;
.endif

.include "obstacle.asm"

pre_end
.align	$10
vararea
.end

