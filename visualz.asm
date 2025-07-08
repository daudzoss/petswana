visualz pha	;//V0LOCAL=whata;void visualz(register uint8_t a, uint8_t arg0,
	pha	;//V1LOCAL=what	;                                 uint4_t arg1){
	and	#DRW_MSH	; uint8_t whata/*ll*/ = a, what;
	sta @w	V1LOCAL	;//what	; what = whata & DRW_MSH;
	beq	+		; if (what) {
	tay			;
	jsrAPCS	hal_msh		;  hal_msh(what);
+	lda @w	V0LOCAL		; }
	and	#DRW_LBL	;
	sta @w	V1LOCAL	;//what	; what = whata & DRW_LBL;
	beq	+		; if (what) {
	jsr	hal_lbl		;  hal_lbl(what); // uses X extensively
+	lda @w	V0LOCAL		; }
	and	#DRW_HID	;
	sta @w	V1LOCAL	;//what	; what = whata & DRW_HID;
	beq	+		; if (what) {
	tay			;
	jsrAPCS	hal_hid		;  hal_hid(what);
+	lda @w	V0LOCAL		; }
	and	#DRW_TRY	;
	sta @w	V1LOCAL	;//what	; what = whata & DRW_TRY;
	beq	+		; if (what) {
	tay			;
	jsrAPCS	hal_try		;  hal_try(what);
+	lda @w	V0LOCAL		; }
	and	#DRW_CEL|DRW_SEL; a = whata & (DRW_CEL|DRW_SEL);//_SEL=highlight
	beq	+		; if (a) { // can only draw cell in TRYGRID here
	sta @w	V1LOCAL	;//what	;  what = a; // _SEL can xor,reverse/flash cells
	lda @w	A1FUNCT	;//arg1	;  uint8_t row, col;
	pha	;//V2LOCAL=row	;  row = arg1; // row 1~8 (to match a 0~9 x 0~11
	lda @w	A0FUNCT	;//arg0	;
	pha	;//V3LOCAL=col	;  col = arg0; // col 1~10 (cells+portals matrix
	sec			;
	sbc	#1		;
	asl			;
	asl			;
	asl			;
	clc			;
	adc @w	V2LOCAL	;//row	;
	sec			;
	sbc	#1		;  // contents to show get fetched from TRYGRID
	tay			;  y = ((col - 1) << 3)|(row - 1); // index 0~79
	jsrAPCS	hal_cel		;  hal_cel(y, col, row, what);
	jmp	++		;  return; // can't subsequently print a message
+	lda @w	V0LOCAL		; }       // since it requires a string on stack
	and	#DRW_MSG	; what = whata & DRW_MSG;
	beq	+		; if (what) {
	POPVARS			;
	DONTRTS			;
	jmp	hal_msg		;  hal_msg(); // needs direct A0FUNCT access
+	POPVARS			; }
	rts			;} // visualz()

tinted	.byte	(RUBRED|RUBYEL|RUBBLU|RUBWHT|RUBOUT)
pokthru	.byte	(SOBLANK & SOFILLD)
guessed	.byte	(CHAMFBR|CHAMFBL|CHAMFTL|CHAMFTR|SQUARE)

;;; color-memory codes for addressable screens
.if BKGRNDC
commodc	.byte	VIDEOBK		;0
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
.endif

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
	.byte	$90		; /* universally black */      0x90};// 16
.else
;;; putchar()-printable dummy color codes for generic terminal-mode platforms
petscii	.byte   0,0,0,0		;static uint8_t petscii[17] = {0, 0, 0, 0,
	.byte   0,0,0,0		;                              0, 0, 0, 0,
	.byte   0,0,0,0		;                              0, 0, 0, 0,
	.byte   0,0,0,0,0	;                              0, 0, 0, 0, 0};
.endif

;;; putchar()-printable graphics symbols for terminal-mode on all platforms
petsyms	.byte	($20<<1)	;static uint8_t petsyms[] = {0x20<<1,// if BLANK
	.byte	($00<<1)	;                   (0*0xa9<<1)|0, // if CHAMFBR
	.byte	($7f<<1)	;                     (0x7f<<1)|1, // if CHAMFBL
	.byte	($00<<1)|1	;                   (0*0xa9<<1)|1, // if CHAMFTL
	.byte	($7f<<1)|1	;                     (0x7f<<1)|0, // if CHAMFTR
	.byte	($20<<1)|1	;                     (0x20<<1)|1, // if SQUARE
	.byte	($60<<1)|1	;                     (0x60<<1)|1, // if BOREDLR
	.byte	($7d<<1)|1	;                     (0x7d<<1)|1, // if BOREDTB
	.byte	($76<<1)	;                     (0x76<<1)|0, // if SOBLANK
	.text	x"e2" x 7	;                     (0x71<<1)|0,...};//SOFILLD
RVS_ON	= $12			;// if 0th bit above is 1, will reverse a symbol
RVS_OFF	= $92			;// done for good measure after printing a cell

.if 0;SCREENH && (SCREENW >= $50)
hal_try
hal_hid
hal_msg
hal_msh
hal_cel	POPVARS
hal_lbl
	rts
.elsif 0;SCREENH && (SCREENW >= $28)
LABLULM	= SCREENM
LABLUL2	= SCREENM + ...
GRIDULM	= SCREENM + SCREENW + 1

hal_cel	POPVARS
	rts
hal_try
hal_hid
hal_msg
hal_msh	POPVARS
hal_lbl
	rts
.elsif SCREENH && (SCREENW >= $16)
CIRCLC	= VIDEOBK
CELLDIM	= 2
.if GRIDULM && GRIDUL2 && GRIDUL4 && GRIDUL6
GRIDPIT	= CELLDIM+1
.else
GRIDPIT = CELLDIM
.endif
LABLULM	= SCREENM
LABLUL0	= LABLULM + 0*GRIDPIT*SCREENW
LABLUL2	= LABLULM + 2*GRIDPIT*SCREENW
LABLUL4	= LABLULM + 4*GRIDPIT*SCREENW
LABLUL6	= LABLULM + 6*GRIDPIT*SCREENW
GRIDULM	= 0			; no VIC20 real estate for inter-cell grid lines
GRIDUL0 = 0
GRIDUL2	= 0
GRIDUL4	= 0
GRIDUL6	= 0
CELLULM	= SCREENM + SCREENW + 1
CELLUL0	= CELLULM + 0*GRIDPIT*SCREENW
CELLUL2	= CELLULM + 2*GRIDPIT*SCREENW
CELLUL4	= CELLULM + 4*GRIDPIT*SCREENW
CELLUL6	= CELLULM + 6*GRIDPIT*SCREENW
GRDLINC	= 0


hal_msh	POPVARS
	rts
.else
rule	.macro	temp,lj,mj,rj	;#define rule(temp,lj,mj,rj) {                 \
.if SCREENW != $16
	lda	#$0d		;                                              \
	jsr	putchar		; putchar('\n');                               \
.endif
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

hal_hid				;void hal_hid(uint8_t what) { hal_try(what); }
hal_try	pha	;//V0LOCAL=i	;void hal_try(uint8_t what) { // DRW_HID,DRW_TRY
	pha	;//V1LOCAL=r	;
	pha	;//V2LOCAL=temp	; uint8_t i, r, temp;
	lda	petscii+UNMIXED	;
	jsr	putchar		; putchar(petscii[UNMIXED]);
	lda	#$0d		;
	jsr	putchar		; putchar('\n');
	lda	#' '		;
	jsr	putchar		; putchar(' ');
	lda	#' '		;
	jsr	putchar		; putchar(' ');
	lda	PORTINT		;
	and	#%0001 .. %1111	;
	tay			;
	lda	petscii,y	;
	jsr	putchar		; putchar(petscii[PORTINT[0] & 0x1f]);
	lda	#0		;
	sta @w	V0LOCAL	;//i	; for (i = 0; i < 9; i++) {
-	clc			;
	adc	#'1'		;
	jsr	putchar		;  putchar('1' + i);
	lda	#' '		;
	jsr	putchar		;  putchar(' ');
	inc @w	V0LOCAL	;//i	;
	ldy @w	V0LOCAL	;//i	;
	lda	PORTINT,y	;
	and	#%0001 .. %1111	;
	tay			;
	lda	petscii,y	;
	jsr	putchar		;  putchar(petscii[PORTINT[i+1] & 0x1f]);
	lda @w	V0LOCAL	;//i	;
	cmp	#9		;
	bcc	-		; }
	lda	#'1'		;
	jsr	putchar		; putchar('1');
	lda	#'0'		;
	jsr	putchar		; putchar('0');
	lda	petscii+UNMIXED	;
	jsr	putchar		; putchar(petscii[UNMIXED]);
	rule V2LOCAL,$b0,$b2,$ae; rule(temp, 0xb0, 0xb2, 0xae) ;
.if SCREENW > $16
	lda	PORTINT+$0a	;
	and	#%0001 .. %1111	;
	tay			;
	lda	petscii,y	;
	jsr	putchar		;  putchar(petscii[PORTINT[i+1] & 0x1f]);
	lda	#'1'		;
	jsr 	putchar		; putchar('1'); //  right-edge label 10's digit
	lda	petscii+UNMIXED	;
	jsr	putchar		;  putchar(petscii[UNMIXED]);
.endif
	lda	#0		;
	sta @w	V0LOCAL	;//i	; i = 0;
	sta @w	V1LOCAL	;//r	; for (r = 0; r < GRIDH; r++) {
-	lda	#$0d		;  register uint8_t y;
.if SCREENW != $16
	jsr	putchar		;  putchar('\n');
.endif
	lda @w	V1LOCAL	;//r	;
	adc	#GRIDW+GRIDH	;
	tay			;
	lda	PORTINT,y	;
	and	#%0001 .. %1111	;
	tay			;
	lda	petscii,y	;
	jsr	putchar		;  putchar(petscii[PORTINT[r+GRIDH+GRIDY]]);
	lda @w	V1LOCAL	;//r	;
	clc			;
	adc	#'a'		;
	jsr	putchar		;  putchar('a' + r); // A~H down left side
	lda	petscii+UNMIXED	;
	jsr	putchar		;  putchar(petscii[UNMIXED]);
-	lda	#$7d		;  for (; (y=i) < GRIDSIZ; i+=GRIDH) {
	jsr	putchar		;   register uint8_t a;
	lda @w	V0LOCAL	;//i	;   register uint1_t c;
	tay			;
	cmp	#GRIDSIZ	;   putchar('|');
	bcc	dnxtcel		;   c = 0;
	jmp	dendrow		;
dnxtcel	adc	#GRIDH		;   a = ' ';
	sta @w	V0LOCAL	;//i	;
	lda @w	A0FUNCT	;//what	;
	and	#DRW_TRY	;
	beq	dhidden		;   if (what & DRW_TRY) { // DRW_HID has no SO*
	lda	TRYGRID,y	;    temp = TRYGRID[y];
	bit	pokthru		;
	beq	deither		;    if (temp & pokthru) { // if unknown, hint
	bit	guessed		;
	beq	+		;     if (temp & guessed) // we placed block so
	and #~(SOBLANK&SOFILLD)	;      temp &= ~pokthru;// show guess, not hint
	bne	deither		;     else // no guess placed here so
+	lda	HIDGRID,y	;      // set flag to show either tinted circle
	ora	#SOBLANK&SOFILLD;      temp = HIDGRID[y] | pokthru; // or X
	bne	deither		;    }
dhidden	lda @w	A0FUNCT	;//what	;
	and	#DRW_HID	;
	beq	dgerror		;   } else if (what & DRW_HID)
	lda	HIDGRID,y	;    temp = HIDGRID[y];
	jmp	deither		;
dgerror	brk			;   else
	brk			;    exit(dgerror);
deither	sta @w	V2LOCAL	;//temp	;
	bpl	+		;   if (temp < 0) { // absorber, drawn as black
	lda	petscii+$10	;
	jsr	putchar		;    putchar(petscii[16]);
	lda	#' '		;
	jmp	+++++		;    c = 1;
+	lsr			;
	lsr			;
	lsr			;
	lsr			;
	tay			;
	beq	+		;   } else if (temp >= 0x10) {// nontransparent
	sec			;    // 0x1_ => 0x01 => 1<<(1-1) == 1==MIXTRED
	lda	#0		;    // 0x2_ => 0x02 => 1<<(2-1) == 2==MIXTYEL
-	rol			;    // 0x3_ => 0x03 => 1<<(3-1) == 4==MIXTBLU
	dey			;    // 0x4_ => 0x04 => 1<<(4-1) == 8==MIXTWHT
	bne	-		;
	tay			;
	lda	petscii,y	;
	jsr	putchar		;    putchar(petscii[1<<(((temp&0x70)>>4)-1)]);
+	lda @w	V2LOCAL	;//temp	;   }
	and	#%0000 .. %1111	;
	tay			;   c = petsyms[temp & 0x0f] & 1;
	lda	petsyms,y	;   a = petsyms[temp & 0x0f] >> 1;
.if !BKGRNDC
	cpy	#SQUARE		;
	bne	+		;   if (y == 5) { // room for tintltr w/o color
	lda @w	V2LOCAL	;//temp	;
	lsr			;
	lsr			;
	lsr			;
	lsr			;
	beq	+		;    if (temp >> 4) { // not transparent
	tay			;
	sec			;
	lda	#0		;
-	rol			;
	dey			;
	bne	-		;     // set a to 'R'/'Y'/'B'/'W' (left-shifted)
	tay			;     a = tintltr[1<<(((temp&0x70)>>4)-1)] << 1;
	lda	tintltr,y	;     c = 1; // reverse video
	sec			;    }
	rol			;   }
.endif
+	lsr			;   if ((a >>= 1) == 0) {
	bne	+		;    a = 0xa9; // only 8-bit stored in petsyms
	lda	#$a9		;   }
+	bcc	++		;   if (c) {
+	pha			;
	lda	#RVS_ON		;
	jsr	putchar		;    putchar(RVS_ON);
	pla			;   }
+	jsr	putchar		;   putchar(a);
	lda	#RVS_OFF	;
	jsr	putchar		;   putchar(RVS_OFF);
	lda	petscii+UNMIXED	;
	jsr	putchar		;   putchar(petscii[UNMIXED]);
	jmp	---		;  }putchar('|');
dendrow
.if SCREENW > $17
	lda	#' '		;
	jsr	putchar		;  putchar(' '); // offset 1's digit diagonally
	lda @w	V1LOCAL	;//r	;
	clc			;
	adc	#$0a		;
	tay			;
	lda	PORTINT,y	;
	and	#%0001 .. %1111	;
	tay			;
	lda	petscii,y	;
	jsr	putchar		;
	lda @w	V1LOCAL	;//r	;
	clc			;
	adc	#'1'		;
	jsr	putchar		;  putchar(r + '1'); // 11~18
	lda	petscii+UNMIXED	;
	jsr	putchar		;   putchar(petscii[UNMIXED]);
.endif
	lda @w	V0LOCAL	;//i	;
	and	#GRIDH-1	;
	clc			;
	adc	#1		;
	sta @w	V0LOCAL	;//i	;  i = (i & (GRIDH-1)) + 1;
	inc @w	V1LOCAL	;//r	;  if (r == GRIDH) // no interior joints at bot
	cmp	#GRIDH		;
	bcs	+		;   break;
	rule V2LOCAL,$ab,$7b,$b3;  rule(temp, 0xab, 0x7b, 0xb3);
.if SCREENW > $16
	lda @w	V1LOCAL	;//r	;
	clc			;
	adc	#$0a		;
	tay			;
	lda	PORTINT,y	;
	and	#%0001 .. %1111	;
	tay			;
	lda	petscii,y	;
	jsr	putchar		;
	lda	#'1'		;
	jsr 	putchar		; putchar('1'); //  right-edge label 10's digit
	lda	petscii+UNMIXED	;
	jsr	putchar		;   putchar(petscii[UNMIXED]);
.endif
	jmp	----		; }
+	rule V2LOCAL,$ad,$b1,$bd; rule(temp, 0xad, 0xb1, 0xb3);
.if SCREENW != $16
	lda	#$0d		;
	jsr	putchar		; putchar('\n');
.endif
	lda	#' '		;
	jsr	putchar		; putchar(' ');
	lda	#' '		;
	jsr	putchar		; putchar(' ');
	lda	#0		;
	sta @w	V0LOCAL	;//i	; for (i = 0; i < 10; i++) {
-	clc			;
	adc	#GRIDH*2+GRIDW	;
	tay			;
	lda	PORTINT,y	;
	and	#%0001 .. %1111	;
	tay			;
	lda	petscii,y	;
	jsr	putchar		;
	lda @w	V0LOCAL	;//i	;
	clc			;
	adc	#'i'		;
	jsr	putchar		;  putchar(i);
	lda	#' '		;
	jsr	putchar		;  putchar(' ');
	inc @w	V0LOCAL	;//i	;
	lda @w	V0LOCAL	;//i	;
	cmp	#$a		;
	bcc	-		; }
	lda	petscii+UNMIXED	;
	jsr	putchar		;   putchar(petscii[UNMIXED]);
	POPVARS			;
	rts			;} // putgrid

hal_msh
hal_cel	POPVARS
hal_lbl
	rts
.endif

.if !VIC20UNEXP
hal_msg	ldy	#$ff		;void hal_msg(void) {
	lda	#0		; putstck(0,255); // needs direct A0FUNCT access
	jmp	putstck		;} // hal_msg()
.else
hal_msg	rts
.endif

.if SCREENW && SCREENH
;;; functions for addressable screens, able to draw randomly accessed
symartl	.byte	$20		; // BLANK
	.byte	$a0		; // CHAMFBR
	.byte	$5f		; // CHAMFBL
	.byte	$20		; // CHAMFTL
	.byte	$df		; // CHAMFTR
	.byte	$a0		; // SQUARE
	.byte	$f9		; // BOREDLR
	.byte	$f6		; // BOREDTB
	.byte	$4d		; // SOBLANK
	.byte	$55		; // SOFILLED
	;.byte	0,0,0,0,0,0

symartr	.byte	$20		; // BLANK
	.byte	$69		; // CHAMFBR
	.byte	$a0		; // CHAMFBL
	.byte	$e9		; // CHAMFTL
	.byte	$20		; // CHAMFTR
	.byte	$a0		; // SQUARE
	.byte	$f9		; // BOREDLR
	.byte	$f5		; // BOREDTB
	.byte	$4e		; // SOBLANK
	.byte	$49		; // SOFILLED
	;.byte	0,0,0,0,0,0

symarbl	.byte	$20		; // BLANK
	.byte	$69		; // CHAMFBR
	.byte	$20		; // CHAMFBL
	.byte	$e9		; // CHAMFTL
	.byte	$a0		; // CHAMFTR
	.byte	$a0		; // SQUARE
	.byte	$f8		; // BOREDLR
	.byte	$f6		; // BOREDTB
	.byte	$4e		; // SOBLANK
	.byte	$4a		; // SOFILLED
	;.byte	0,0,0,0,0,0

symarbr	.byte	$20		; // BLANK
	.byte	$20		; // CHAMFBR
	.byte	$5f		; // CHAMFBL
	.byte	$a0		; // CHAMFTL
	.byte	$df		; // CHAMFTR
	.byte	$a0		; // SQUARE
	.byte	$f8		; // BOREDLR
	.byte	$f5		; // BOREDTB
	.byte	$4d		; // SOBLANK
	.byte	$4b		; // SOFILLED
	;.byte	0,0,0,0,0,0

tintarr	.byte	VIDEOBG		; // UNTINTD
	.byte	VIDEOR		; // TINTRED
	.byte	VIDEOY		; // TINTYEL
	.byte	VIDEOBL		; // TINTBLU
	.byte	VIDEOW		; // TINTWHT
	.byte	0,0,0,VIDEOBK	; // ABSORBD
	;.byte	0,0,0,0,0,0,0

OUTLNTL	= $4f
OUTLNTR	= $50
OUTLNBL	= $4c
OUTLNBR	= $7a

filltwo	.macro	baseadr		;#define filltwo(baseadr,symtl,symtr,symbl,\
.if 0
 tya
 pha
 lda #$0d
 jsr putchar
 pla
 pha
 tay
 jsrAPCS puthexd
 lda @w V7LOCAL
 and #$60
 jsr putchar
 lda @w V6LOCAL
 and #$60
 jsr putchar
 lda @w V5LOCAL
 and #$60
 jsr putchar
 lda @w V4LOCAL
 and #$60
 jsr putchar
 pla
 tay
.endif
	pla	;//symtl=V7LOCAL;symbr,scoff,cellt,y)/*y=scoff*/
	sta	CELLUL\baseadr,y;                                

	pla	;//symtr=V6LOCAL;
	sta	1+CELLUL\baseadr,y

	pla	;//symbl=V5LOCAL;
	sta	SCREENW+CELLUL\baseadr,y

	pla	;//symbr=V4LOCAL;
	sta	1+SCREENW+CELLUL\baseadr,y

	ldy @w	V2LOCAL	;//cellt;
	cmp	#OUTLNBR	;

	php			;
	lda	tintarr,y	; register uint8_t a = 	tintarr[cellt];
	plp			;
	bne	+		;
	cpy	#UNTINTD	;
	bne	+		; if ((symbr == OUTLNBR) && (cellt == UNTINTD))
	lda	#VIDEOBK	;   a |= VIDEOBK; // highlighting so not VIDEOBG
+	ldy @w	V3LOCAL	;//scoff;
.if 0
 pha
 lda #' '	
 jsr putchar
 pla
 pha
 tay
 jsrAPCS puthexd
 pla
 ldy @w V3LOCAL
.endif
	sta	SCREEND+CELLUL\baseadr,y;
	sta	SCREEND+1+CELLUL\baseadr,y
	sta	SCREEND+SCREENW+CELLUL\baseadr,y
	sta	SCREEND+1+SCREENW+CELLUL\baseadr,y
	.endm			;

halhprt	bcs	+		;void halhprt(register uint8_t y, // col#
	lda	SCREENM,y	;             register uint1_t c) {
	ora	#$80		; if (c == 0) { // top row 1~10
	sta	SCREENM,y	;  SCREENM[y] |= 0x80;
	lda	SCREENM+1,y	;
	ora	#$80		;
	sta	SCREENM+1,y	;  SCREENM[y+1] |= 0x80;
	bne	++		; } else { // bot row i~r
+	lda	SCREENM+SCREENW*(1+GRIDPIT*GRIDH),y
	ora	#$80		;  SCREENM[SCREENW*(1+GRIDPIT*GRIDH)+y] |= 0x80;
	sta	SCREENM+SCREENW*(1+GRIDPIT*GRIDH),y
	lda	SCREENM+SCREENW*(1+GRIDPIT*GRIDH)+1,y
	ora	#$80		;  SCREENM[SCREENW*(1+GRIDPIT*GRIDH)+y+1]|=0x80;
	sta	SCREENM+SCREENW*(1+GRIDPIT*GRIDH)+1,y
+	POPVARS			; } // jmp'ed here from hal_prt so POPVARS
	rts			;} // halhprt()

halvsml	lda	SCREENM+999,y	;static uint8_t* charcell = SCREENM+999;
	ora	#$80		;void halvsml(register uint8_t y) {
halvsms	sta	SCREENM+999,y	; *charcell |= 0x80;
	rts			;} // halvsml()
halvini	lda	#(>SCREENM)-1	;void halvini(register uint8_t y) { // row#
	sta	1+halvsml+1	;
	lda	#<SCREENM	;
;	sta	halvsml+1	;
-	inc	1+halvsml+1	;
-	cpy	#0		;
	beq	+		;
	dey			;
	clc			;
	adc	#SCREENW	;
	bcs	--		;
	bcc	-		;
+	sta	halvsml+1	;
	sta	halvsms+1	;
	lda	1+halvsml+1	;
	sta	1+halvsms+1	; charcell = SCREENM + y * SCREENW;
	rts			;} // halvini()
halvprt	bcs	+		;void halvpr(register uint8_t y, // row#
	jsr	halvini		;            register uint1_t c) {
	ldy	#0		; if (c == 0) { // left col a~h
	beq	++		;  halvini(y);
+	jsr	halvini		;  y = 0;
	ldy	#GRIDPIT*GRIDW+1; } else { // right col 11~18
+	tya			;  halvini(y);
	clc			;  y = GRIDPIT+GRIDH;
	adc	#SCREENW	; }
	pha			;
	jsr	halvsml		; halvsml(y);
	pla			;
	tay			;
	jsr	halvsml		; halvsml(y + SCREENW);
	POPVARS			;
	rts			;} // halvprt()

hal_prt	and	#$7f		;void hal_prt(register uint8_t a) {
	tay			;
	jsrAPCS	bportal		; register uint8_t y = bportal(a & 0x7f);
	tya			;
	cmp	#$0a  		;
	bcs	+		; if (y < 10) { // portals 1~10 are [0~9]
.if GRIDPIT == 2
	asl			;
	tay			;
	iny			;  y = y * GRIDPIT + 1; // SCREENM[1,3,5,...19]
.elsif GRIDPT == 3
	sta	OTHRVAR		;
	asl			;
	clc			;
	adc	OTHRVAR		;
	tay			;
	iny			;  y = y * GRIDPIT + 1; // SCREENM[1,4,7,...,28]
.else
.error "unhandled GRIDPIT value"
.endif
	clc			;
	jmp	halhprt		;  halhprt(y, 0);// paint top character and next
+	cmp	#$12		;
	bcs	+		; } else if (y < 18) { // portal 11~18 : [10~17]

	sec			;
	sbc	#$0a		;
.if GRIDPIT == 2
	asl			;
	tay			;
	iny			;  y = (y-10)*GRIDPIT+1; // [1,3,5,...]
.elsif GRIDPT == 3
	sta	OTHRVAR		;
	asl			;
	clc			;
	adc	OTHRVAR		;
	tay			;
	iny			;  y = (y-10)*GRIDPIT+1;// [1,4,7,...,28]
.else
.error "unhandled GRIDPIT value"
.endif
	sec			;
	jmp	halvprt		;  halvprt(y,1);// paint right character and blw

+	cmp	#$1a		;
	bcs	+		; } else if (y < 26) { // portal a~h are [18~25]

	sec			;
	sbc	#$12		;
.if GRIDPIT == 2
	asl			;
	tay			;
	iny			;  y = (y-18)*GRIDPIT+1; // [1,3,5,...19]
.elsif GRIDPT == 3
	sta	OTHRVAR		;
	asl			;
	clc			;
	adc	OTHRVAR		;
	tay			;
	iny			;  y = (y-18)*GRIDPIT+1;// [1,4,7,...,28]
.else
.error "unhandled GRIDPIT value"
.endif
	clc			;
	jmp	halvprt		;  halvprt(y,0); // paint left character and blw
	
+	cmp	#$24		;
	bcs	+		; } else if (y < 36) { // portal i~r are [26~35]
	sec			;
	sbc	#$1a		;
.if GRIDPIT == 2
	asl			;
	tay			;
	iny			;  y = (y-26)*GRIDPIT+1; // [1,3,5,...19]
.elsif GRIDPT == 3
	sta	OTHRVAR		;
	asl			;
	clc			;
	adc	OTHRVAR		;
	tay			;
	iny			;  y = (y-26)*GRIDPIT+1;// [1,4,7,...,28]
.else
.error "unhandled GRIDPIT value"
.endif
	sec			;  halhprt(y, 1);// paint bot character and next
	jmp	halhprt		; } else exit(DRW_SEL);
+	brk			;} // hal_prt()

ocupied	.byte	%0000 .. %0111	;
sel_cel	.byte	DRW_SEL
hal_cel	pha	;V0LOCAL=gridi	;void hal_cel(register uint8_t a, uint8_t col,
	tay			;                   uint8_t row, uint8_t what) {
	lda	TRYGRID,y	; uint8_t gridi = a; // so we can hint iff a<80
	and	#%0000 .. %1111	; uint8_t cellv = TRYGRID[a/*0~70|80~159*/]&0xf;
	cpy	#GRIDSIZ	;
	bcs	++	;dhidden; if (gridi < GRIDSIZ) { // no hints in HIDGRID
	bit	pokthru		;
 	beq	++	;deither;  if (cellv & pokthru) { // if unknown, hint
	bit	guessed		;
	beq	+		;   if (cellv & guessed) // we placed block so
	and #~(SOBLANK&SOFILLD)	;    cellv &= ~pokthru; // show guess, not hint
	bne	++	;deither;   else // no guess placed here so
+	lda	HIDGRID,y	;    // set flag to show either tinted circle
	ora	#SOBLANK&SOFILLD;    cellv = HIDGRID[y] | pokthru; // or X
+	pha	;V1LOCAL=cellv	;  }
	lda	#$98		; }
	pha	;V2LOCAL=cellt	; uint8_t cellt = 0x98 /* or CIRLC? */; // for X
	lda	TRYGRID,y	;
	bit	pokthru		;
	beq	+		; if ((pokthru & TRYGRID[y] == 0) // not a hint
	lda	HIDGRID,y	;
	bit	ocupied		;
	beq	++		;  || (ocupied & HIDGRID[y])) // cell is a shape
+	lda	TRYGRID,y	;
	lsr			;
	lsr			;
	lsr			;
	lsr			;
	sta @w	V2LOCAL	;//cellt;  cellt = TRYGRID[a] >> 4; // use tint 0~4 | 8
+	lda	#-GRIDPIT	;
	ldy @w	A0FUNCT	;//col	;
-	clc			;
	adc	#+GRIDPIT	;
	dey			;
	bne	-		;
	pha	;V3LOCAL=scoff	; uint8_t scoff = (col-1)*GRIDPIT;// 0~9*GRIDPIT
	ldy @w	V1LOCAL	;//cellv; register uint8_t y = cellv;
	lda	symarbr,y	;
	cmp	#' '		;
	bne	+		;
	lda @w	A2FUNCT	;//what	;
	bit	sel_cel		;
	php			;
	lda	symarbr,y	;
	plp			;
	beq	+		; if ((symarbr[y] == ' ') && (what & DRW_SEL))
	lda	#OUTLNBR	;  symbr = OUTLNBR;
+	cmp	#$a0		;
	bne	+		;
	lda @w	A2FUNCT	;//what	;
	bit	sel_cel		;
	php			;
	lda	symarbr,y	;
	plp			; else if ((symarbr[y] = 0xa0) &&
	beq	+		;          (what & DRW_SEL))
	lda	#$80|OUTLNBR	;  symbr = 0x80 | OUTLNBR;
+	pha	;V4LOCAL=symbr	; else symbr = symarbr[y];
	
	lda	symarbl,y	;
	cmp	#' '		;
	bne	+		;
	lda @w	A2FUNCT	;//what	;
	bit	sel_cel		;
	php			;
	lda	symarbl,y	;
	plp			;
	beq	+		; if ((symarbl[y] == ' ') && (what & DRW_SEL))
	lda	#OUTLNBL	;  symbl = OUTLNBL;
+	cmp	#$a0		;
	bne	+		;
	lda @w	A2FUNCT	;//what	;
	bit	sel_cel		;
	php			;
	lda	symarbl,y	;
	plp			; else if ((symarbl[y] = 0xa0) &&
	beq	+		;          (what & DRW_SEL))
	lda	#$80|OUTLNBL	;  symbl = 0x80 | OUTLNBL;
+	pha	;V5LOCAL=symbl	; else symbl = symarbl[y];

	lda	symartr,y	;
	cmp	#' '		;
	bne	+		;
	lda @w	A2FUNCT	;//what	;
	bit	sel_cel		;
	php			;
	lda	symartr,y	;
	plp			;
	beq	+		; if ((symartr[y] == ' ') && (what & DRW_SEL))
	lda	#OUTLNTR	;  symtr = OUTLNTR;
+	cmp	#$a0		;
	bne	+		;
	lda @w	A2FUNCT	;//what	;
	bit	sel_cel		;
	php			;
	lda	symartr,y	;
	plp			; else if ((symartr[y] = 0xa0) &&
	beq	+		;          (what & DRW_SEL))
	lda	#$80|OUTLNTR	;  symtr = 0x80 | OUTLNTR;
+	pha	;V6LOCAL=symtr	; else symtr = symartr[y];

	lda	symartl,y	;
	cmp	#' '		;
	bne	+		;
	lda @w	A2FUNCT	;//what	;
	bit	sel_cel		;
	php			;
	lda	symartl,y	;
	plp			;
	beq	+		; if ((symartl[y] == ' ') && (what & DRW_SEL))
	lda	#OUTLNTL	;  symtl = OUTLNTL;
+	cmp	#$a0		;
	bne	+		;
	lda @w	A2FUNCT	;//what	;
	bit	sel_cel		;
	php			;
	lda	symartl,y	;
	plp			; else if ((symartl[y] = 0xa0) &&
	beq	+		;          (what & DRW_SEL))
	lda	#$80|OUTLNTL	;  symtl = 0x80 | OUTLNTL;
+	pha	;V7LOCAL=symtl	; else symtl = symartly];

	lda @w	A1FUNCT	;//row	;
	and	#1		; switch (a = row) {
	bne	+		;  case 2:
	lda @w	V3LOCAL	;//scoff;   scoff += GRIDPIT*SCREENW;
	clc			;  case 1:
	adc	#GRIDPIT*SCREENW;   filltwo(0, a, symtl, symtr, symbl, symbr,
	sta @w	V3LOCAL	;//scoff;    scoff, cellt, y=scoff, gridi);       break;
+	lda @w	A1FUNCT	;//row	;
	ldy @w	V3LOCAL	;//scoff;  case 4:
	cmp	#3		;   scoff += GRIDPIT*SCREENW;
	bcs	+		;  case 3:
	filltwo	0		;   filltwo(2, a, symtl, symtr, symbl, symbr,
	jmp	++++		;    scoff, cellt, y=scoff, gridi);       break;
+	cmp	#5		;  case 6:
	bcs	+		;   scoff += GRIDPIT*SCREENW;
	filltwo	2		;   filltwo(4, a, symtl, symtr, symbl, symbr,
	jmp	+++		;    scoff, cellt, y=scoff, gridi);       break;
+	cmp	#7		;  case 8:
	bcs	+		;   scoff += GRIDPIT*SCREENW;
	filltwo	4		;  case 7:
	jmp	++		;  default: filltwo(6, a, symtl, symtr, symbl,
+	filltwo	6		;   symbr, scoff, cellt, y=scoff, gridi);
+	POPVARS			; }
	rts			;} // hal_cel()

gridsho	clc			;void gridsho(register uint8_t a /* offset */) {
	adc	#GRIDSIZ	;
	pha	;//savey=V0LOCAL; uint8_t savey = GRIDSIZ + a; // +0=TRY,+80=HID
	lda	#DRW_CEL	;
	pha	;//what=V1LOCAL	; uint8_t what, DRW_CEL;
	lda	#GRIDSIZ/8	;
	pha	;//row=V2LOCAL	;
	pha	;//col=V3LOCAL	; uint8_t row, col;
-	lda	#8		; for (col = 10; col; col--) {
	sta @w	V2LOCAL	;//row	;  for(row = 8; row; row--) {
-	dec @w	V0LOCAL	;//savey;
	ldy @w	V0LOCAL	;//savey;
	jsrAPCS	hal_cel		;   hal_cel(--savey, col, row, what);
	dec @w	V2LOCAL	;//row	;
	bne	-		;  }
	dec @w	V3LOCAL	;//col	;
	bne	--		; }
	POPVARS			;
	rts			;} // gridsho()

hal_try	lda	#0		;void hal_try(void) { gridsho(0);
	jmp	gridsho		;} // hal_try()

hal_hid
.if !VIC20UNEXP
	jsrAPCS	gridcir		;void hal_try(void) {
.endif
	lda	#$50		; gridcir(); gridsho(80);
.if 1;causes an unhandled case at the end of halhprt() if a portal is selected:
	jmp	gridsho		;} // hal_hid()
.endif

CGRIDTL	= $
CGRIDH	= $
CGRIDHB	= $
CGRIDTR	= $
CGRIDV	= $
CGRIDHV	= $
CGRIDVR	= $
CGRIDVL	= $
CGRIDBL	= $
CGRIDHT	= $
CGRIDBR	= $

CIRCLTL	= $55
CIRCLH	= $40
CIRCLTR	= $49
CIRCLV	= $5d
CIRCLBL	= $4a
CIRCLBR	= $4b

SCREEND	= SCREENC-SCREENM

gridtop .byte	$20,$31,$20,$32
	.byte	$20,$33,$20,$34
	.byte	$20,$35,$20,$36
	.byte	$20,$37,$20,$38
	.byte	$20,$39,$20,$31
	.byte	$30,$20
	;" 1 2 3 4 5 6 7 8 9 10 "
gridbot	.byte	$20,$09,$20,$0a
	.byte	$20,$0b,$20,$0c
	.byte	$20,$0d,$20,$0e
	.byte	$20,$0f,$20,$10
	.byte	$20,$11,$20,$12
	.byte	$20,$20
	;" i j k l m n o p q r  "
hal_lbl	txa			;inline void hal_lbl(void) {
	pha
	lda	#' '	
	sta	LABLUL0	
	sta	LABLUL0+SCREENW
	sta	LABLUL2+SCREENW
	sta	LABLUL4+SCREENW
	sta	LABLUL6+SCREENW
	sta	LABLUL6+SCREENW+SCREENW

	lda	#'a'-'@'
	sta	LABLUL0+(SCREENW*2)
	lda	#'c'-'@'
	sta	LABLUL2+(SCREENW*2)
	lda	#'e'-'@'
	sta	LABLUL4+(SCREENW*2)
	lda	#'g'-'@'
	sta	LABLUL6+(SCREENW*2)
	ldy	#ANSWERS/2+'a'-'a'
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL0+(SCREENW*2)
	ldy	#ANSWERS/2+'c'-'a'
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL2+(SCREENW*2)
	ldy	#ANSWERS/2+'e'-'a'
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL4+(SCREENW*2)
	ldy	#ANSWERS/2+'g'-'a'
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL6+(SCREENW*2)

	lda	#' '	
	sta	LABLUL0+(SCREENW*3)
	sta	LABLUL2+(SCREENW*3)
	sta	LABLUL4+(SCREENW*3)
	sta	LABLUL6+(SCREENW*3)
	sta	LABLUL6+SCREENW+(SCREENW*3)

	lda	#'b'-'@'
	sta	LABLUL0+(SCREENW*4)
	lda	#'d'-'@'
	sta	LABLUL2+(SCREENW*4)
	lda	#'f'-'@'
	sta	LABLUL4+(SCREENW*4)
	lda	#'h'-'@'
	sta	LABLUL6+(SCREENW*4)
	ldy	#ANSWERS/2+'b'-'a'
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL0+(SCREENW*4)
	ldy	#ANSWERS/2+'d'-'a'
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL2+(SCREENW*4)
	ldy	#ANSWERS/2+'f'-'a'
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL4+(SCREENW*4)
	ldy	#ANSWERS/2+'h'-'a'
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL6+(SCREENW*4)

.if GRIDULM && GRIDUL2 && GRIDUL4 && GRIDUL6
	lda	#'1'	
	sta	LABLUL0+(SCREENW*1+GRIDPIT*10+2)
	sta	LABLUL2+(SCREENW*1+GRIDPIT*10+2)
	sta	LABLUL4+(SCREENW*1+GRIDPIT*10+2)
	sta	LABLUL6+(SCREENW*1+GRIDPIT*10+2)
	sta	LABLUL0+(SCREENW*2+GRIDPIT*10+2)
	lda	#'3'	
	sta	LABLUL2+(SCREENW*2+GRIDPIT*10+2)
	lda	#'5'	
	sta	LABLUL4+(SCREENW*2+GRIDPIT*10+2)
	lda	#'7'	
	sta	LABLUL6+(SCREENW*2+GRIDPIT*10+2)
	ldy	#$0b-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL0+(SCREENW*1+GRIDPIT*10+2)
	sta	SCREEND+LABLUL0+(SCREENW*2+GRIDPIT*10+2)
	ldy	#$0d-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL2+(SCREENW*1+GRIDPIT*10+2)
	sta	SCREEND+LABLUL2+(SCREENW*2+GRIDPIT*10+2)
	ldy	#$0f-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL4+(SCREENW*1+GRIDPIT*10+2)
	sta	SCREEND+LABLUL4+(SCREENW*2+GRIDPIT*10+2)
	ldy	#$11-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL6+(SCREENW*1+GRIDPIT*10+2)
	sta	SCREEND+LABLUL6+(SCREENW*2+GRIDPIT*10+2)
.else
	lda	#'1'	
	sta	LABLUL0+(SCREENW*1+GRIDPIT*10+1)
	sta	LABLUL2+(SCREENW*1+GRIDPIT*10+1)
	sta	LABLUL4+(SCREENW*1+GRIDPIT*10+1)
	sta	LABLUL6+(SCREENW*1+GRIDPIT*10+1)
	sta	LABLUL0+(SCREENW*2+GRIDPIT*10+1)
	lda	#'3'	
	sta	LABLUL2+(SCREENW*2+GRIDPIT*10+1)
	lda	#'5'	
	sta	LABLUL4+(SCREENW*2+GRIDPIT*10+1)
	lda	#'7'	
	sta	LABLUL6+(SCREENW*2+GRIDPIT*10+1)
	ldy	#$0b-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL0+(SCREENW*1+GRIDPIT*10+1)
	sta	SCREEND+LABLUL0+(SCREENW*2+GRIDPIT*10+1)
	ldy	#$0d-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL2+(SCREENW*1+GRIDPIT*10+1)
	sta	SCREEND+LABLUL2+(SCREENW*2+GRIDPIT*10+1)
	ldy	#$0f-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL4+(SCREENW*1+GRIDPIT*10+1)
	sta	SCREEND+LABLUL4+(SCREENW*2+GRIDPIT*10+1)
	ldy	#$11-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL6+(SCREENW*1+GRIDPIT*10+1)
	sta	SCREEND+LABLUL6+(SCREENW*2+GRIDPIT*10+1)
.endif

.if GRIDULM && GRIDUL2 && GRIDUL4 && GRIDUL6
	lda	#'1'	
	sta	LABLUL0+(SCREENW*3+GRIDPIT*10+2)
	sta	LABLUL2+(SCREENW*3+GRIDPIT*10+2)
	sta	LABLUL4+(SCREENW*3+GRIDPIT*10+2)
	sta	LABLUL6+(SCREENW*3+GRIDPIT*10+2)
	lda	#'2'
	sta	LABLUL0+(SCREENW*4+GRIDPIT*10+2)
	lda	#'4'
	sta	LABLUL2+(SCREENW*4+GRIDPIT*10+2)
	lda	#'6'
	sta	LABLUL4+(SCREENW*4+GRIDPIT*10+2)
	lda	#'8'
	sta	LABLUL6+(SCREENW*4+GRIDPIT*10+2)
	ldy	#$0c-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL0+(SCREENW*3+GRIDPIT*10+2)
	sta	SCREEND+LABLUL0+(SCREENW*4+GRIDPIT*10+2)
	ldy	#$0e-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL2+(SCREENW*3+GRIDPIT*10+2)
	sta	SCREEND+LABLUL2+(SCREENW*4+GRIDPIT*10+2)
	ldy	#$10-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL4+(SCREENW*3+GRIDPIT*10+2)
	sta	SCREEND+LABLUL4+(SCREENW*4+GRIDPIT*10+2)
	ldy	#$12-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL6+(SCREENW*3+GRIDPIT*10+2)
	sta	SCREEND+LABLUL6+(SCREENW*4+GRIDPIT*10+2)
.else
	lda	#'1'	
	sta	LABLUL0+(SCREENW*3+GRIDPIT*10+1)
	sta	LABLUL2+(SCREENW*3+GRIDPIT*10+1)
	sta	LABLUL4+(SCREENW*3+GRIDPIT*10+1)
	sta	LABLUL6+(SCREENW*3+GRIDPIT*10+1)
	lda	#'2'
	sta	LABLUL0+(SCREENW*4+GRIDPIT*10+1)
	lda	#'4'
	sta	LABLUL2+(SCREENW*4+GRIDPIT*10+1)
	lda	#'6'
	sta	LABLUL4+(SCREENW*4+GRIDPIT*10+1)
	lda	#'8'
	sta	LABLUL6+(SCREENW*4+GRIDPIT*10+1)
	ldy	#$0c-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL0+(SCREENW*3+GRIDPIT*10+1)
	sta	SCREEND+LABLUL0+(SCREENW*4+GRIDPIT*10+1)
	ldy	#$0e-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL2+(SCREENW*3+GRIDPIT*10+1)
	sta	SCREEND+LABLUL2+(SCREENW*4+GRIDPIT*10+1)
	ldy	#$10-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL4+(SCREENW*3+GRIDPIT*10+1)
	sta	SCREEND+LABLUL4+(SCREENW*4+GRIDPIT*10+1)
	ldy	#$12-1
	ldx	PORTINT,y
	lda	commodc,x
	sta	SCREEND+LABLUL6+(SCREENW*3+GRIDPIT*10+1)
	sta	SCREEND+LABLUL6+(SCREENW*4+GRIDPIT*10+1)
.endif
	ldy	#gridbot-gridtop
-	lda	gridtop-1,y
	sta	LABLULM-1,y
	tya
	pha
	lsr
	tay
	ldx	PORTINT-1,y
	pla
	tay
	lda	#CIRCLC
	cpy	#1
	beq	+
	cpy	#gridbot-gridtop
	beq	+
	lda	commodc,x
+	sta	SCREEND+LABLULM-1,y

	lda	gridbot-1,y
.if GRIDULM && GRIDUL2 && GRIDUL4 && GRIDUL6
	sta	LABLULM+SCREENW*(2+GRIDPIT*8)-1,y
.else
	sta	LABLULM+SCREENW*(1+GRIDPIT*8)-1,y
.endif
	tya
	pha
	lsr
	tay
	ldx	PORTINT+GRIDW+2*GRIDH-1,y
	pla
	tay
	lda	#CIRCLC
	cpy	#1
	beq	+
	cpy	#gridbot-gridtop
	beq	+
	lda	commodc,x
+
.if GRIDULM && GRIDUL2 && GRIDUL4 && GRIDUL6
	sta	SCREEND+LABLULM+SCREENW*(2+GRIDPIT*8)-1,y
.else
	sta	SCREEND+LABLULM+SCREENW*(1+GRIDPIT*8)-1,y
.endif
;	sta	SCREENC-1,y
	dey		
	bne	-	
	pla
	tax
	rts			;} // hal_lbl()

.if !VIC20UNEXP
gridcir	ldy	#1+GRIDPIT*GRIDW;void gridcir(void) {
	lda	#CIRCLTR	; register uint8_t y = 1+GRIDPIT*GRIDW;
	sta	LABLULM,y	; LABLULM[y] = CIRCLTR;
	lda	#CIRCLBR	;
	sta	LABLULM+(GRIDPIT*GRIDH+1)*SCREENW,y
	lda	#CIRCLC		; LABLULM[y+(GRIDPIT*GRIDH+1)*SCREENW]= CIRCLBR;
	sta	SCREEND+LABLULM,y;LABLULM[y + SCREEND + ""] = CIRCLC;
	sta	SCREEND+LABLULM+(GRIDPIT*GRIDH+1)*SCREENW,y
	lda	#CIRCLBL	; LABLULM[y + SCREEND] = CIRCLC;
	dey			;
-	lda	#CIRCLH		; for (; y; --y) {
	sta	LABLULM,y	;  LABLULM[y] = CIRCLH;
	sta	LABLULM+(GRIDPIT*GRIDH+1)*SCREENW,y
	lda	#CIRCLC		;  LABLULM[y + SCREEND] = CIRCLC;
	sta	SCREEND+LABLULM,y
	sta	SCREEND+LABLULM+(GRIDPIT*GRIDH+1)*SCREENW,y
	dey			;
	bne	-		; }
	lda	#CIRCLTL	;
	sta	LABLULM,y	; LABLULM[0] = CIRCLTR;
	lda	#CIRCLBL	;
	sta	LABLULM+(GRIDPIT*GRIDH+1)*SCREENW,y
	lda	#CIRCLC		; LABLULM[0 + SCREEND] = CIRCLC;
	sta	SCREEND+LABLULM,y
	sta	SCREEND+LABLULM+(GRIDPIT*GRIDH+1)*SCREENW,y
	lda	#CIRCLV		; for (r = 0; y; --y) {
.for r := 1, r <= GRIDPIT*GRIDH, r += 1
	sta LABLULM+r*SCREENW	;
	sta LABLULM+r*SCREENW+GRIDPIT*GRIDW+1
.next
	lda	#CIRCLC		;
.for r := 1, r <= GRIDPIT*GRIDH, r += 1
	sta SCREEND+LABLULM+r*SCREENW
	sta SCREEND+LABLULM+r*SCREENW+GRIDPIT*GRIDW+1
.next
	rts			;} // gridcir()


tempstr	.null	$0d,$98,"beam @"
tempout	pha			;
	pha			;
	ldy	#0		;
-	tya			;
	pha			;
	lda	tempstr,y	;
	jsr	putchar		;
	pla			;
	tay			;
	iny			;
	cmp #tempout-tempstr-1	;
	bcc	-		;
	pla			;
	jsr	bportal		;
	lda	PORTALS,y	;
	bit	portalf		;
	beq	+		;
	eor	#%0110 .. %0000	;
	jmp	++		;
+	ora	#%0011 .. %0000	;
	cmp	#'9'+1		;
	bcc	+		;
	sec			;
	sbc	#$0a		;
	pha			;
	lda	#'1'		;
	jsr	putchar		;
	pla			;
+	jsr	putchar		;
	lda	#':'		;
	jsr	putchar		;
	pla			;
.endif
.else
tempout
.endif
.if !VIC20UNEXP
	pha			;void tempout(uint8_t a) {
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
	rts
tintltr	.byte	0,'r','y',0	;
	.byte	'b',0,0,0,'w'	;
	.byte	0,0,0,0,0,0,0,'a'
.else
	rts			;} // tempout()
.endif
