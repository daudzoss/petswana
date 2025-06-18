ask_key	.byte	SAY_KEY		;
ask_ans	.byte	SAY_ANS		;
ask_prt	.byte	SAY_PRT		;
ask_pek	.byte	SAY_PEK		;

nteract	bit	ask_key		;void nteract(register uint8_t a, uint4_t arg0){
	beq	+		; if (ask_key & SAY_KEY) {
	jsrAPCS	hal_key		;
	POPVARS			;  return hal_key();
	rts			; } else {
+	jsrAPCS	hal_inp		;  return hal_inp();
	POPVARS			; }
	rts			;} // nteract()

confirm	jsrAPCS	hal_cnf		;void confirm(register uint8_t a) { // FIXME: add visualz DRW_MSG
	POPVARS			; return hal_cnf(a);
	rts			;} // confirm()

reallyq	.null $14,"are you sure?";static char reallyq[] = "\bare you sure?";
hal_cnf	stckstr	reallyq,hal_cnf	;uint8_t hal_cnf(void) {
	ldy	#$ff		; stckstr(reallyq, reallyq+sizeof(reallyq));
	jsrAPCS	putstck,lda,#0	; putstck(0, 255, reallyq); // print from stack
	POPVARS			;
	DONTRTS			;
	ldy	#SAY_KEY	;
	jsrAPCS	nteract		;
	tya			;
	pha			; uint8_t key = nteract(SAY_KEY);
	jsr	putchar		; putchar(key);
	lda @w	V0LOCAL	;//key	;
	cmp	#'y'		;
	beq	+		;
	cmp	#'y'+$20	;
	beq	+		;
	ldy	#0		;
	beq	++		;
+	ldy	#1		; return y = (tolower(key) == 'y') ? 1 : 0;
+	POPVARS			;
	rts			;} // hal_cnf()

inputkb
	POPVARS
	rts

hal_key	jsr	getchar		; register uint8_t a = getchar();
	POPVARS			;
	rts			;

hal_inp	jsrAPCS	tempinp		;
	POPVARS			;
	rts			;

.if SCREENW && SCREENH
tempinp rts
.else
tempinp	lda	#$0d		;uint8_t tempinp(void) {
	pha	;//VOLOCAL=rtval; uint8_t rtval;
	jsr	putchar		; putchar('\n');
-	lda	#'?'		;
	jsr	putchar		;
	jsr	getchar		;
	tya			;
	cmp	#'x'		;
	beq	+		;
	cmp	#'x'+$20	;
	beq	+		;
.if 1
	cmp	#'x'+$40	;
	beq	+		;
	cmp	#'x'+$60	;
	beq	+		;
	cmp	#'x'+$80	; // why, c16, why is 'x' 0x58 but 'X' 0xd8?!?
.endif
	bne	++		; register uint8_t a;
+	lda	#0		;
	jmp	tempinr		; while (putchar('?'), ((a=getchar()) != 'x')) {
+	cmp	#'s'		;  register int8_t y;
	beq	+		;
	cmp	#'s'+$20	;
	beq	+		;
.if 1
	cmp	#'s'+$40	;
	beq	+		;
	cmp	#'s'+$60	;
	beq	+		;
	cmp	#'s'+$80	; // why, c16, why is 's' 0x53 but 'S' 0xd3?!?
.endif
	bne	++		;  if (tolower(a) == 's')
+	lda	#SUBMITG	;
	jmp	tempinr		;   return y = SUBMITG; // submit grid for grade
+	cmp	#' '		;
	bne	+		;
	jmp	tempins		;
+	cmp	#'@'		;
	bne	+		;
	jmp	tempina		;  else if (a != ' ' && a != '@') {
+	cmp	#'1'		;   // portal as A~R or 1~18
	bcc	-		;
	bne	++		;   if (a == '1') {
	jsr	putchar		;    putchar(a);
	jsr	getchar		;
	tya			;    a = getchar();
	cmp	#$0d		;
	bne	+		;    if (a == '\n')
	lda	#1		;
	jmp	tempinr		;     y = 1; // only time a Return needed
+	cmp	#'0'		;
	bcc	-		;    else if (a >= '0'
	cmp	#'8'+1		;             &&
	bcs	-		;             a <= '8') {
	sta @w	V0LOCAL	;//rtval;
	jsr	putchar		;     putchar(a);
	lda @w	V0LOCAL	;//rtval;
	sec			;
	sbc	#'0'-$0a	;
	jmp	tempinr		;     return y = a-'0' + 10;
+	cmp	#'9'+1		;
	bcs	+		;   } else if (a > '1' && a <= '9') {
	sta @w	V0LOCAL	;//rtval;
	jsr	putchar		;    putchar(a);
	lda @w	V0LOCAL	;//rtval;
	sec			;
	sbc	#'0'		;
	jmp	tempinr		;    return y = a-'0';
+	and	#%0101 .. %1111	;
	cmp	#'a'		;
	bcs	+		;
	jmp	-		;   } else if (toupper(a) >= 'A'
+	cmp	#'r'+1		;              &&
	bcc	+		;
	jmp	-		;              toupper(a) <= 'R') {
+	sta @w	V0LOCAL	;//rtval;
	jsr	putchar		;    putchar(a);
	lda @w	V0LOCAL	;//rtval;
	sec			;
	sbc	#'a'		;
	clc			;    return y = a-'A' + 0x21;
	adc	#$21		;   }
	jmp	tempinr		;  } else if (a == ' ') { // put @cell a~h,1~10_
tempins	jsr	putchar		;   putchar(' ');
	jsrAPCS	getcell		;   // for 1, need Return to distinguish from 10
	tya			;   y = getcell();
	bpl	+		;   if (y < 0)
	jmp	-		;    continue; // note: 1x, won't flow back here
+	pha	;//V1LOCAL=ycopy;   uint8_t ycopy = y;
	pha	;//V2LOCAL=row	;
	pha	;//V3LOCAL=col	;   uint8_t row, col;
	lda	TRYGRID,y	;
	and	#%1111 .. %1000	;
	sta @w	V0LOCAL	;//rtval;   rtval = TRYGRID[ycopy] & 0xf8;
	tya			;
	and	#%0000 .. %0111	;
	clc			;
	adc	#1		;
	sta @w	V2LOCAL	;//row	;   row = (ycopy & 0x07) + 1; // for DRW_CEL
	tya			;
	lsr			;
	lsr			;
	lsr			;
	clc			;
	adc	#1		;
	sta @w	V3LOCAL	;//col	;   col = (ycopy >> 3)  + 1; // for DRW_CEL
	lda	TRYGRID,y	;
	and	#%0000 .. %0111	;
	clc			;
	adc	#1		;   a = (TRYGRID[ycopy]&0x07) + 1; // next shape
	cmp	#MAXSHAP+1	;
	bcc	+		;   if (a > MAXSHAP)
	lda	#BLANK		;    rtval = BLANK; // must clear tint to blank
	beq	++		;
+	ora @w	V0LOCAL	;//rtval;   else
+	sta @w	V0LOCAL	;//rtval;    rtval |= a;// bit 3 has been left untouched
	bit	pokthru		;   if (rtval & pokthru) {// we've bought a hint
	beq	colorky		;    if (HIDGRID[y]) // which confirmed obstacle
	lda	HIDGRID,y	;     goto colornc; // so don't need to ask tint
	bne	colornc		;   }
colorky	jsr	getchar		;   while ((a = y = toupper(getchar())) != 'X'){
	tya			;
	ldy @w	V1LOCAL	;//ycopy;
	and	#%0101 .. %1111	;    switch (a) {
	cmp	#$0d		;    case '\n': // leave existing tint unchanged
	bne	+		;
colornc	lda @w	V0LOCAL	;//rtval;    colornc:
.if 1
	cmp	#%0001 .. %0000	;     if (rtval < RUBRED) // no tint already set
	bcc	colorky		;      continue; // don't allow transparents yet
.endif
	sta	TRYGRID,y	;     TRYGRID[ycopy] = rtval; // hal_cel() reads
	ldy	#DRW_CEL	;
	jsrAPCS	visualz		;     visualz(DRW_CEL, col, row); // show it
	lda	#$40		;
	jmp	tempinr		;     return 0x40;// fall thru main()'s switch{}
+	cmp	#'b'		;    case 'B':
	bne	+		;
	lda @w	V0LOCAL	;//rtval;
	and	#%0000 .. %1111	;
	ora	#RUBBLU		;
	sta	TRYGRID,y	;     TRYGRID[ycopy] = RUBBLU | (rtval &0x0f);
	ldy	#DRW_CEL	;
	jsrAPCS	visualz		;     visualz(DRW_CEL, col, row); // show it
	lda	petscii+MIXTBLU	;
	jsr	putchar		;     putchar(petscii[MIXTBLU]);
	lda	#RVS_ON		;
	jsr	putchar		;     putchar(RVS_ON);
	lda	#'b'		;
	jsr	putchar		;     putchar('B');
	lda	#$40		;
	jmp	tempinr		;     return 0x40;// fall thru main()'s switch{}
+	cmp	#'r'		;    case 'R':
	bne	+		;
	lda @w	V0LOCAL	;//rtval;
	and	#%0000 .. %1111	;
	ora	#RUBRED		;
	sta	TRYGRID,y	;     TRYGRID[ycopy] = RUBBLU | (rtval &0x0f);
	ldy	#DRW_CEL	;
	jsrAPCS	visualz		;     visualz(DRW_CEL, col, row); // show it
	lda	petscii+MIXTRED	;
	jsr	putchar		;     putchar(petscii[MIXTRED]);
	lda	#RVS_ON		;
	jsr	putchar		;     putchar(RVS_ON);
	lda	#'r'		;
	jsr	putchar		;     putchar('R');
	lda	#$40		;
	jmp	tempinr		;     return 0x40;// fall thru main()'s switch{}
+	cmp	#'w'		;    case 'W':
	bne	+		;
	lda @w	V0LOCAL	;//rtval;
	and	#%0000 .. %1111	;
	ora	#RUBWHT		;
	sta	TRYGRID,y	;     TRYGRID[ycopy] = RUBBLU | (rtval &0x0f);
	ldy	#DRW_CEL	;
	jsrAPCS	visualz		;     visualz(DRW_CEL, col, row); // show it
	lda	petscii+MIXTWHT	;
	jsr	putchar		;     putchar(petscii[MIXTWHT]);
	lda	#RVS_ON		;
	jsr	putchar		;     putchar(RVS_ON);
	lda	#'w'		;
	jsr	putchar		;     putchar('W');
	lda	#$40		;
	jmp	tempinr		;     return 0x40;// fall thru main()'s switch{}
+	cmp	#'y'		;    case 'Y':
	bne	+		;
	lda @w	V0LOCAL	;//rtval;
	and	#%0000 .. %1111	;
	ora	#RUBYEL		;
	sta	TRYGRID,y	;     TRYGRID[ycopy] = RUBBLU | (rtval &0x0f);
	ldy	#DRW_CEL	;
	jsrAPCS	visualz		;     visualz(DRW_CEL, col, row); // show it
	lda	petscii+MIXTYEL	;
	jsr	putchar		;     putchar(petscii[MIXTYEL]);
	lda	#RVS_ON		;
	jsr	putchar		;     putchar(RVS_ON);
	lda	#'y'		;
	jsr	putchar		;     putchar('Y');
	lda	#$40		;     return 0x40;// fall thru main()'s switch{}
	jmp	tempinr		;    }
+	cmp	#'t'		;    case 'T':
	bne	+		;
	lda @w	V0LOCAL	;//rtval;
	and	#%0000 .. %1111	;
	ora	#0		;
	sta	TRYGRID,y	;     TRYGRID[ycopy] = 0 | (rtval &0x0f);
	ldy	#DRW_CEL	;
	jsrAPCS	visualz		;     visualz(DRW_CEL, col, row); // show it
	lda	petscii+UNMIXED	;
	jsr	putchar		;     putchar(petscii[UNMIXED]);
	lda	#RVS_ON		;
	jsr	putchar		;     putchar(RVS_ON);
	lda	#' '		;
	jsr	putchar		;     putchar(' ');
	lda	#$40		;     return 0x40;// fall thru main()'s switch{}
	jmp	tempinr		;    }
+	cmp	#'a'		;    case 'A':
	bne	+		;
	lda @w	V0LOCAL	;//rtval;
	and	#%0000 .. %1111	;
	ora	#RUBOUT		;
	sta	TRYGRID,y	;     TRYGRID[ycopy] = RUBOUT | (rtval &0x0f);
	ldy	#DRW_CEL	;
	jsrAPCS	visualz		;     visualz(DRW_CEL, col, row); // show it
	lda	petscii+16	;
	jsr	putchar		;     putchar(petscii[16]);
	lda	#RVS_ON		;
	jsr	putchar		;     putchar(RVS_ON);
	lda	#'a'		;
	jsr	putchar		;     putchar('A');
	lda	#$40		;     return 0x40;// fall thru main()'s switch{}
	jmp	tempinr		;    }
+	eor	#'x'		;   }
	beq	tempinr		;   return 0; // request to quit instead of tint
	jmp	colorky		;  } else if (a == '@') { // peek @cell a~h,1~10
tempina	jsr	putchar		;   putchar('@');
	jsrAPCS	getcell		;   y = getcell();
	tya			;   return 0x80 | y;
	ora	#$80		;  }
tempinr	tay			; }
	POPVARS			; return 0;
	rts			;} // tempinp()

getcell	pha	;//V0LOCAL=cella;register uint8_t getcell(void) {
	pha	;//V1LOCAL=celln; uint8_t calla/*lpha*/,celln/*umeric*/;
	jsr	getchar		;
	tya			; register uint8_t y, a = getchar();
	cmp	#'a'		;
	bcs	+		;
	jmp	getcele		;
+	cmp	#'i'+$20	;
	bcc	+		; if ((a < 'A') || (a >= 'i'))
	jmp	getcele		;  return y = -1;
+	and	#%0101 .. %1111	; a &= 0x5f; // toupper()
	cmp	#'i'		;
	bcc	+		; if (toupper(a) >= 'I')
	jmp	getcele		;  return y = -1;
+	sta @w	V0LOCAL	;//cella;
	jsr	putchar		; putchar(a);
	lda @w	V0LOCAL	;//cella;
	sec			;
	sbc	#'a'		;
	sta @w	V0LOCAL	;//cella; cella = a - 'a'; // now in range 0~7
	jsr	getchar		;
	tya			; a = getchar();
	cmp	#'9'+1		;
	bcc	+		;
	jmp	getcele		;
+	cmp	#'1'		;
	bcs	+		; if ((a < '1') || (a > '9'))
	jmp	getcele		;  return y = -1;
+	sta @w	V1LOCAL	;//celln;
	jsr	putchar		; putchar(a);
	lda @w	V1LOCAL	;//celln;
	cmp	#'1'		;
	bne	+++		; else if (a == '1') {
	jsr	getchar		;  a = getchar();
	tya			;
	cmp	#'0'		;
	bne	+		;  if (a == '0') {
	lda	#'0'		;
	jsr	putchar		;   putchar('0');
	lda	#'9'+1		;   a = '1'+9;
	bne	+++		;
+	cmp	#$0d		;
	beq	+		;  } else if (a != '\n')
	jmp	getcele		;   return y = -1;
+	lda	#'1'		;  } else a = '1';
+	sec			; }
	sbc	#'1'		; a -= '1'; // now in range 0~9
	ldy	#3		;
-	asl			;
	dey			;
	bne	-		; a <<= 3; // now 0,8,16,24,32,40,48,56,64,72
	ora @w	V0LOCAL	;//cella; a |= cella; // now 0~79
	tay			; return y = a;
	jmp	getcelr		;
getcele	ldy	#$ff		;
getcelr	POPVARS			;
	rts			;} // getcell()
.endif
