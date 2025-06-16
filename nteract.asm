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

reallyq	.null	"really quit?"	;static char reallyq[] = "really quit?";
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
	pha	;//VOLOCAL=prtal; uint8_t prtal;
	pha	;//V1LOCAL=cella; uint8_t cella;
	pha	;//V2LOCAL=celln; uint8_t celln;
	jsr	putchar		; putchar('\n');
-	lda	#'?'		;
	jsr	putchar		;
	jsr	getchar		;
	tya			;
	ldy	#0		;
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
	bne	++		;
+	jmp	tempinr		; while (putchar('?'), ((a=getchar()) != 'x')) {
+	cmp	#'s'		;
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
+	ldy	#SUBMITG	;
	jmp	tempinr		;   return y = SUBMITG; // submit grid for grade
+	cmp	#'@'		;
	beq	tempina		;  else if (a != '@') { // portal as A~R or 1~18
	cmp	#'1'		;
	bcc	-		;
	bne	++		;   if (a == '1') {
	jsr	putchar		;    putchar(a);
	jsr	getchar		;
	tya			;    a = getchar();
	cmp	#$0d		;
	bne	+		;    if (a == '\n')
	ldy	#1		;
	jmp	tempinr		;     y = 1; // only time a Return needed
+	cmp	#'0'		;
	bcc	-		;    else if (a >= '0'
	cmp	#'8'+1		;             &&
	bcs	-		;             a <= '8') {
	sta @w	V0LOCAL	;//prtal;
	jsr	putchar		;     putchar(a);
	lda @w	V0LOCAL	;//prtal;
	sec			;
	sbc	#'0'-$0a	;
	tay			;
	jmp	tempinr		;     return y = a-'0' + 10;
+	cmp	#'9'+1		;
	bcs	+		;   } else if (a > '1' && a <= '9') {
	sta @w	V0LOCAL	;//prtal;
	jsr	putchar		;    putchar(a);
	lda @w	V0LOCAL	;//prtal;
	sec			;
	sbc	#'0'		;
	tay			;
	jmp	tempinr		;    return y = a-'0';
+	and	#%0101 .. %1111	;
	cmp	#'a'		;
	bcs	+		;
	jmp	-		;   } else if (toupper(a) >= 'A'
+	cmp	#'r'+1		;              &&
	bcc	+		;
	jmp	-		;              toupper(a) <= 'R') {
+	sta @w	V0LOCAL	;//prtal;
	jsr	putchar		;    putchar(a);
	lda @w	V0LOCAL	;//prtal;
	sec			;
	sbc	#'a'		;
	clc			;
	adc	#$21		;    return y = a-'A' + 0x21;
	tay			;   }
	bne	tempinr		;  } else { // @ precedes peek at a~h,1~10 cell
tempina	jsr	putchar		;   putchar('@');
	jsr	getchar		;
	tya			;   a = getchar();
	cmp	#'a'		;
	bcs	+		;
	jmp	-		;
+	cmp	#'i'+$20	;
	bcc	+		;   if ((a < 'A') || (a >= 'i'))
	jmp	-		;    continue;
+	and	#%0101 .. %1111	;   a &= 0x5f; // toupper()
	cmp	#'i'		;
	bcc	+		;   if (toupper(a) >= 'I')
	jmp	-		;    continue;
+	sta @w	V1LOCAL	;//cella;
	jsr	putchar		;   putchar(a);
	lda @w	V1LOCAL	;//cella;
	sec			;
	sbc	#'a'		;
	sta @w	V1LOCAL	;//cella;   cella = a - 'a'; // now in range 0~7
	jsr	getchar		;
	tya			;   a = getchar();
	cmp	#'9'+1		;
	bcc	+		;
	jmp	-		;
+	cmp	#'1'		;
	bcs	+		;   if ((a < '1') || (a > '9'))
	jmp	-		;    continue;
+	sta @w	V2LOCAL	;//celln;
	jsr	putchar		;   putchar(a);
	lda @w	V2LOCAL	;//celln;
	cmp	#'1'		;
	bne	+++		;   else if (a == '1') {
	jsr	getchar		;    a = getchar();
	tya			;
	cmp	#'0'		;
	bne	+		;    if (a == '0') {
	lda	#'0'		;
	jsr	putchar		;     putchar('0');
	lda	#'9'+1		;     a = '1'+9;
	bne	+++		;
+	cmp	#$0d		;
	beq	+		;    } else if (a != '\n')
	jmp	-		;     continue;
+	lda	#'1'		;    else a = '1';
+	sec			;   }
	sbc	#'1'		;   a -= '1'; // now in range 0~9
	ldy	#3		;
-	asl			;
	dey			;
	bne	-		;   a <<= 3; // now 0,8,16,24,32,40,48,56,64,72
	ora	#$80		;
	ora @w	V1LOCAL	;//cella;   
	tay			;
tempinr	POPVARS			;
	rts			;} // tempinp()
.endif
