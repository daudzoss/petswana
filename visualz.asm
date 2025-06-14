vis_cel	.byte	DRW_CEL		;
vis_msg	.byte	DRW_MSG		;
	.byte	0
vis_mov	.byte	DRW_MOV		;
vis_try	.byte	DRW_TRY		;
vis_hid	.byte	DRW_HID		;
vis_lbl	.byte	DRW_LBL		;
vis_msh	.byte	DRW_MSH		;

visualz	pha	;//V0LOCAL=what	;void visualz(register uint8_t a, uint8_t arg0,
	bit	vis_msh		;                                 uint4_t arg1){
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
	lda	PORTINT+$0a	;                                              \
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
.if SCREENW != $16
	jsr	putchar		;  putchar('\n');                              \
.endif
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
	cpy	#SQUARE		;                                              \
	bne	+		;   if (y == 7) { // room for tintltr w/o color\
	lda @w	V2LOCAL	;//temp	;                                              \
	lsr			;                                              \
	lsr			;                                              \
	lsr			;                                              \
	lsr			;                                              \
	php			;                                              \
	lda	petsyms,y	;                                              \
	plp			;                                              \
	beq	+		;    if (temp >> 4) { // not transparent       \
	tay			;                                              \
	lda	#0		;                                              \
	sec			;                                              \
-	rol			;                                              \
	dey			;                                              \
	bne	-		;                                              \
	tay			;                                              \
	lda	tintltr,y	;     a = tintltr[1 << (temp >> 4)]; //W/R/Y/B \
	sec			;    }                                         \
	rol			;   }                                          \
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
	adc	#$0a		;                                              \
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
.if SCREENW != $16
	lda	#$0d		;                                              \
	jsr	putchar		; putchar('\n');                               \
.endif
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
