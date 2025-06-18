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
;;; {UNTINTD=0;TINT*=1,2,3,4;ABSORBD=8}	{marker in TRY}	{BLANK=0;CHAMF;SQUARE=5}

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
bounce5	.byte	RABOUNC x 4
bounce6	.byte	(RABOUNC << TP) | (NOBOUNC << LT) | (RABOUNC << BT) | NOBOUNC;RT
bounce7	.byte	(NOBOUNC << TP) | (RABOUNC << LT) | (NOBOUNC << BT) | RABOUNC;RT

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
SQUARE	= $5			; cell filled in so all four sides will rebound
BOREDLR	= $6			; transmits left-right but rebounds top-bottom
BOREDTB	= $7			; transmits top-bottom but rebounds left-right
SOBLANK	= $8			; marker (in TRYGRID only) that blank confirmed
SOFILLD	= $9			; marker (in TRYGRID only) that object confirmed
MAXSHAP	= SQUARE;BOREDTB

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

SAY_KEY	= 1<<4		 	; returns the key value
SAY_ANS	= 1<<5			; returns %01 .. special code %111111, or $00
SAY_PRT	= 1<<6			; returns %00 .. portal_1~50, or $00 for quit
SAY_PEK	= 1<<7			; returns %1 .. cell_0~79, or $00 for quit
SAY_ANY = SAY_PEK|SAY_PRT|SAY_ANS
	;; special codes here
SUBMITG	= %01 .. %111111	; turn in answer for grading, please

DRW_CEL	= 1<<0			; // A0: cell 0~79, A1: object
DRW_MSG	= 1<<1			; // A0: '\0'-terminated character string?!?
DRW_MOV	= 1<<3			; // A0: first move index to draw
DRW_TRY	= 1<<4			;no args?
DRW_HID	= 1<<5			;no args?
DRW_LBL	= 1<<6			;no args
DRW_MSH	= 1<<7			;no args; also draws screen decorations if any
DRW_DEC	= DRW_MSH|DRW_LBL	;
DRW_BTH	= DRW_HID|DRW_TRY	;

.include "stdlib.asm"

main	jsr	wipescr		;int main(void) {
	jsrAPCS	b2basic+1	; wipescr();
b2basic	rts			;
	lda	#2		;
	pha	;//V0LOCAL	; uint8_t remng = 2; // guesses remaining
.if !BASIC
	lda	#$0f		; static volatile uint8_t execute_bank* = 0x01;
	sta	$01		; *execute_bank = 15;// P500 runs in system bank
.endif
.if BKGRNDC
	lda	#VIDEOBG	; if (BKGRNDC) // use available color screen
	sta	BKGRNDC		;  BKGRNDC = VIDEOBG;
.endif
	jsrAPCS	initize		; initize(); // portals, grids
-	ldy	#DRW_DEC|DRW_TRY; do {
	jsrAPCS	visualz		;  visualz(DRW_MSH|DRW_LBL|DRW_TRY);
	ldy	#SAY_ANY	;
	jsrAPCS	nteract		;  y = nteract(SAY_ANY);  
	sty	OTHRVAR		;
	lda	#$ff		;
	bit	OTHRVAR		;   
	bne	+		;  if (y == 0) { // user quit
	jsrAPCS	confirm		;   register uint8_t y = confirm();
	tya			;
	beq	-		;   if (y)
	lda	#0		;
	beq	mainend		;    exit(0);
+	bpl	+		;  } else if (y & SAY_PEK) { // cell check
	jsrAPCS	peekcel		;   peekcel(y); // FIXME: add msg
	jmp	-		;
+	bvc	+++		;  } else if (y & 0x40) { // special input  
	cpy	#SUBMITG	;   switch (y) {
	bne	++		;   case SUBMITG:
	jsrAPCS	confirm		;
	tya			;    if (!confirm())
	beq	-		;     break /*switch*/;
	jsrAPCS	chkgrid		;
	tya			;
	bne	+		;    if (chkgrid(y) == 0) {
	stckstr	youwin,youwon	;     stckstr(youwin, youwin+sizeof(youwin));
	ldy	#DRW_MSG	;
	jsrAPCS	visualz		;     visualz(DRW_MSG);
	ldy @w	V0LOCAL	;//remng;
	jmp	mainend	    	;     exit(y = remng);
+	dec @w	V0LOCAL	;//remng;
	bne	-		;    } else if (--remnng == 0) {
	stckstr	youlose,youlost	;     stckstr(youlose, youlose+sizeof(youlose));
	ldy	#DRW_HID|DRW_MSG;
	jsrAPCS	visualz		;     visualz(DRW_HID|DRW_MSG);
	ldy	#0		;     exit(y = 0);
	jmp	mainend		;    }
+	jmp	-		;   }
+	jsrAPCS	shinein		;  } else { // portal check
	tya			;   tempout(shinein(a)); // FIXME: add msg
	jsr	tempout		;  }
	jmp	-		; } while (a);
mainend	POPVARS			;
	rts			;} // main()

youwin	.null	$0d,"grid correct, you win!"
youwon
youlose	.null	$0d,"you lose after guess 2"
youlost	
	
initize	jsr	iniport		;void initize(void) {
	clc			; iniport();
	jsr	inigrid		; inigrid(0 /* TRYGRID */);
	sec			;
	jsr	inigrid		; inigrid(1 /* HIDGRID */);
	jsrAPCS	rndgrid		; rndgrid();
	POPVARS			;
	rts			;} // initize()

chkgrid	ldy	#GRIDSIZ	;inline register unit8_t chkgrid(void) {
-	lda	TRYGRID-1,y	; for (uint8_t y = GRIDSIZ; y; y--) {
	and	#~(SOBLANK)	;  register uint8_t a = TRYGRID[y-1] & 0xf7;
	cmp	HIDGRID-1,y	;  if (HIDGRID[y-1] != a) 
	bne	+		;   break;
	dey			;  // bit 3 was any hint revealed, not our guess
	bne	-		; }
+	POPVARS			; return y; // 0 for perfect match
	rts			;} // chkgrid()

peekcel	and	#%0111 .. %1111	;
	tay			;
	lda	TRYGRID,y	;
	ora	#%0000 .. %1000	;
	sta	TRYGRID,y	;
	POPVARS			;
	rts			;

iniport	lda	#$00		;inline void iniport(void) {
	ldy	#ANSWERS	; for (register uint8_t y = ANSWERS; y; y--) {
-	sta	PORTALS-1,y	;  PORTINT[y-1] = PORTALS = 0; // no beam yet
	sta	PORTINT-1,y	; //             // where a beam into here exits
	dey			;// bits 3~0 tint reflected, or bit 4 absorbed
	bne	-		; }
	rts			;} // iniport()

inigrid	lda	#0		;inline inigrid(uint1_t c) {
	ldy	#GRIDSIZ	; for (register uint8_t y = GRIDSIZ; y; y--) {
-	bcc	+		;  if (c)
	sta	HIDGRID-1,y	;   HIDGRID[y-1] = 0;
	bcs	++		;  else
+	sta	TRYGRID-1,y	;   TRYGRID[y-1] = 0;
+	dey			;
	bne	-		; }
	rts			;} // inigrid()

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
	lda	HIDGRID,y	;  // imagine we're on the FROM_ edge of cell y
	bpl	+		;
	jmp	deadend		;  if ((HIDGRID[y] >> 4) & RUBOUT == 0) { // on
+	beq	+		;   if (HIDGRID[y]) { // hit something in cell y
	sta @w	V3LOCAL	;//bump	;    bump = HIDGRID[y];//H nyb tint, L nyb shape
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

placeit	lda	obstcel,y	;register int8_t placeit(register uint8_t y,
	and	#$0f		;   uint8_t colnm /*A0*/, uint8_t rownm /*A1*/,
	cmp @w	A0FUNCT	;//colnm;   uint8_t elems /*A2*/, uint8_t tint /*A3*/) {
	bcs	+		;
	ldy	#$ff		; if (colnm > obstcel[y] & 0x0f)
	bcc	express		;  return y = -1;// tried to place too far right
+	lda	obstcel,y	;
	lsr			;
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
	ora @w	A1FUNCT	;//rownm;
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
punwind	ldy @w	V2LOCAL	;//yelem; for (yelem; yelem != head; yelem--) {
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

.if RNDLOC1 && RNDLOC2
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
	sta @w	V1LOCAL	;//rotn	;  for (rotn=0x80|(rand()&3);rotn&0x80;rotn++) {
-	and	#%0000 .. %0011	;
	clc			;
	adc @w	V2LOCAL	;//oldy	;
	tay			;
	lda	obstlst+3,y	;
	pha			;   uint8_t temp = obstlst[+3+y + ((rotn++)&3)];
-	lda	RNDLOC1		;   do {
	eor	RNDLOC2		;
	and	#%0000 .. %0111 ;#%0000 .. %1111 ;
;	cmp	#GRIDH		;
;	bcs	-		;
	sta @w	V5LOCAL	;//rownm;   } while ((rownm = rand() & 15) >= GRIDH);
-	lda	RNDLOC1		;   do {
	eor	RNDLOC2		;
	and	#%0000 .. %1111	;
	cmp	#GRIDW		;
	bcs	-		;
	sta @w	V6LOCAL	;//colnm;   } while ((colnm = rand() & 15) >= GRIDW);
	pla			;
	tay			;
	jsrAPCS	placeit		;
	tya			;   if (placeit(temp,colnm,rownm,elems,tint)==0)
	beq	+		;    break;
	inc @w	V1LOCAL	;//rotn	;
	lda @w	V1LOCAL	;//rotn	;
	bmi	---		;  }
;	jsr	getchar		;
	jsrAPCS hal_hid		;
	brk			;
+	ldy @w	V0LOCAL	;//next	;
	bne	----		; }
rnddone	POPVARS			;

.else
cangrid	.byte	0|CHAMFTL,	0|BOREDLR,	0|CHAMFBL,	BLANK
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

modekey	.text	$09,$83,$08	; enable upper/lower case, uppercase, lock upper
.if SCREENH
	.text	$13,$13		; clear any BASIC 3.5/4 subwindows on the screen
.endif
wipescr	ldx	#wipescr-modekey;inline void wipescr(void) { // APCS uncompliant
-	lda	modekey,x	;                             // for performance
	jsr	$ffd2		;
	dex			;
	bne	-		; printf("%c%c%c%c%c%c", 9, 147, 8, 19, 19);
.if SCREENH && SCREENW
	ldy	#SCREENH	; for (register int8_t y = SCREENH; y > 0; y--)

-	ldx	#SCREENW	;  for (register int8_t x = SCREENH; x > 0; x--)
-	lda	#$20		;
	jsr	$ffd2		;   printf(" ");
	dex			;
	bne	-		;
	dey			;
	bne	--		;
	lda	#$13		;
	jsr	$ffd2		; printf("%c", 19); // back to home corner
.endif
	rts			;}
.include "obstacle.asm"
.include "visualz.asm"
.include "nteract.asm"

pre_end
.align $10			;//FIXME:unnecessary for production
vararea
.end

