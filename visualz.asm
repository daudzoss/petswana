visualz pha	;//V0LOCAL=whata;void visualz(register uint8_t a, uint8_t arg0,
	pha	;//V1LOCAL=what	;                                 uint4_t arg1){
	and	#DRW_MSH	; uint8_t whata/*ll*/ = a, what;
	sta @w	V1LOCAL	;//what	; what = whata & DRW_MSH;
	beq	+		; if (what) {
	jsrAPCS	hal_msh		;  hal_msh(what);
+	lda @w	V0LOCAL		; }
	and	#DRW_LBL	;
	sta @w	V1LOCAL	;//what	; what = whata & DRW_LBL;
	beq	+		; if (what) {
	jsrAPCS	hal_lbl		;  hal_lbl(what);
+	lda @w	V0LOCAL		; }
	and	#DRW_HID	;
	sta @w	V1LOCAL	;//what	; what = whata & DRW_HID;
	beq	+		; if (what) {
	jsrAPCS	hal_hid		;  hal_hid(what);
+	lda @w	V0LOCAL		; }
	and	#DRW_TRY	;
	sta @w	V1LOCAL	;//what	; what = whata & DRW_TRY;
	beq	+		; if (what) {
	jsrAPCS	hal_try		;  hal_try(what);
+	lda @w	V0LOCAL		; }
	and	#DRW_CEL	; y = whata & DRW_CEL;
	beq	+		; if (y) {
	tay			;
	lda @w	A1FUNCT	;//arg1	;
	sta @w	V0LOCAL	;//cntnt;
	lda @w	A0FUNCT	;//arg0	;
	sta @w	V1LOCAL	;//index;
	jsrAPCS	hal_cel		;  hal_cel(y, arg0, arg1);
+	lda @w	V0LOCAL		; }
	and	#DRW_MSG	; what = whata & DRW_MSG;
	beq	+		; if (what) {
	POPVARS			;
	DONTRTS			;
	jmp	hal_msg		;  hal_msg(what); // needs direct A0FUNCT access
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
	.byte	($20<<1)|1	;                     (0x20<<1)|1, // if SQUARE
	.byte	($60<<1)|1	;                     (0x60<<1)|1, // if BOREDLR
	.byte	($7d<<1)|1	;                     (0x7d<<1)|1, // if BOREDTB
	.byte	($76<<1)	;                     (0x76<<1)|0, // if SOBLANK
	.text	x"e2" x 7	;                     (0x71<<1)|0,...};//SOFILLD
RVS_ON	= $12			;// if 0th bit above is 1, will reverse a symbol
RVS_OFF	= $92			;// done for good measure after printing a cell

.if SCREENH && (SCREENW >= $50)
putcell
hal_try
hal_hid
hal_msg
hal_lbl
hal_msh
hal_cel	POPVARS
	rts
.elsif SCREENH && (SCREENW >= $28)
putcell
hal_try
hal_hid
hal_msg
hal_lbl
hal_msh
hal_cel	POPVARS
	rts
.elsif SCREENH && (SCREENW >= $16)
putcell
hal_try
hal_hid
hal_msg
hal_lbl
hal_msh
hal_cel	POPVARS
	rts
.else

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

pokthru	.byte	(SOBLANK & SOFILLD)
guessed	.byte	(CHAMFBR|CHAMFBL|CHAMFTL|CHAMFTR|SQUARE)
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
	and #~(SOBLANK&SOFILLD)	;      temp &= pokthru; // show guess, not hint
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
	bne	+		;   if (y == 7) { // room for tintltr w/o color
	lda @w	V2LOCAL	;//temp	;
	lsr			;
	lsr			;
	lsr			;
	lsr			;
	php			;
	lda	petsyms,y	;
	plp			;
	beq	+		;    if (temp >> 4) { // not transparent
	tay			;
	lda	#0		;
	sec			;
-	rol			;
	dey			;
	bne	-		;
	tay			;
	lda	tintltr,y	;     a = tintltr[1 << (temp >> 4)]; //W/R/Y/B
	sec			;    }
	rol			;   }
.endif
+	lsr			;   if (!a)
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
	
hal_msg	ldy	#$ff		;void hal_msg(void) {
	lda	#0		; putstck(0,255); // needs direct A0FUNCT access
	jmp	putstck		;} // hal_msg()
	
hal_lbl
hal_msh
hal_cel	POPVARS
	rts
.endif

.if SCREENW && SCREENH
tempout rts
.else
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
