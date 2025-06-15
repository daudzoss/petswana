getchar	txa			;inline uint8_t getchar(void) {
	pha			; // x stashed on stack, by way of a
-	jsr	$ffe4		; do {
	beq	-		;  y = (* ((*)(void)) 0xffe4)();
	tay			; } while (!y);
	pla			; return y;
	tax			; // x restored from stack, by way of a
	rts			;} // getchar()

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
	rts			;}
	
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

hal_inp	jsr	tempinp		;
	tay			;
	POPVARS			;
	rts			;

.if SCREENW && SCREENH
tempinp rts
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
.endif
	
