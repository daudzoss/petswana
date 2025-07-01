ask_key	.byte	SAY_KEY		;
ask_ans	.byte	SAY_ANS		;
ask_prt	.byte	SAY_PRT		;
ask_pek	.byte	SAY_PEK		;

nteract	pha	;//V0LOCAL=what	;void nteract(register uint8_t a, uint1_t arg0){
	bit	ask_key		; uint8_t what = a;             //^^^which grid?
	beq	+		; if (ask_key & SAY_KEY) {
	jsrAPCS	hal_key		;  return hal_key(what);
	jmp	++		; } else {
+	jsrAPCS	hal_inp		;  return hal_inp(what);
+	POPVARS			; }
	rts			;} // nteract()

hal_key	jsr	getchar		; register uint8_t a = getchar();
	POPVARS			;
	rts			;

confirm	jsrAPCS	hal_cnf		;void confirm(register uint8_t a) { // FIXME: add visualz DRW_MSG
	POPVARS			; return hal_cnf(a);
	rts			;} // confirm()

.if SCREENW && SCREENH
rcindex	pha	;//V0LOCAL=col	;register uint8_t rcindex(register int8_t a//col
	tya			;                       register int8_t y){//row
	pha	;//V1LOCAL=row_1;
	dey			; int8_t col = a, row_1;
	bmi	uportal		; if (y < 1) goto uportal;
	tya			;
	cmp	#GRIDH		;
	bcs	dportal		; if (y > GRIDH) goto dportal;
	sta @w	V1LOCAL	;//row_1; row_1 = (y - 1) & 0x07;
	ldy @w	V0LOCAL	;//col	;
	dey			;
	bmi	lportal		; if (col < 1) goto lportal;
	cpy	#GRIDW		;
	bcs	rportal		; if (col > GRIDW) goto rportal;
	tya			;
	asl			;
	asl			;
	asl			;
	and	#%0111 .. %1000	;
	ora @w	V1LOCAL	;//row_1; // cell returns simple index 0 <= y < GRIDSIZ
	bpl	rcretna		; return y = (((col - 1) << 3) & 0x38) | row_1;
rportal	lda	#$0b		;
	clc			; // portals at the edges return values suitable
	adc @w	V1LOCAL	;//row_1; // for shinein() but with bit 7 set to flag so
	bne	uportal		; rportal: return y = 0x80|(11+row-1); // 11~18
lportal	lda	#$21		;
	clc			;
	adc @w	V1LOCAL	;//row_1;
	bne	uportal		; lportal: return y = 0x80|(0x21+row-1); // A~H
dportal	lda @w	V0LOCAL	;//col	;
	clc			;
	adc	#$28		; bportal: return y = 0x80|(0x28+col); // I~R
uportal	ora	#$80		; tportal: return y = 0x80|(col); // 1~10
rcretna	tay			;
	POPVARS			;
	rts			;} // rcindex()

reallyq	.null 	"are you sure?"	;static char reallyq[] = "are you sure?";
hal_cnf
	ldy	#0		;uint8_t hal_cnf(void) {
	beq	++		;
+	ldy	#1		; return y = (tolower(key) == 'y') ? 1 : 0;
+	POPVARS			;
	rts			;} // hal_cnf()

inup	dec @w	A1FUNCT	;//row	;void inup(int8_t* col, int8_t* row) {
	bmi	noup		; if (--*row >= 0) { // haven't fallen off edge
	bne	rtup		;  if (*row == 0) { // need to avoid the corners
	lda @w	A0FUNCT	;//col	;   if (*col != 0 && *col != GRIDW+1) {
	beq	noup		;    return; // in top row but not in a corner
	cmp	#GRIDW+1	;   }
	bne	rtup		;  } else return; // not in top row yet
noup	inc @w	A1FUNCT	;//row	; }
rtup	POPVARS			; ++*row; // undo the move
	rts			;} // inup()

indown	inc @w	A1FUNCT	;//row	;void indown(int8_t* col, int8_t* row) {
	lda @w	A1FUNCT	;//row	;
	cmp	#GRIDH+2	;
	bcs	nodown		; if (++*row <= GRIDH+1) { // haven't fallen off
	cmp	#GRIDH+1	;
	bne	rtdown		;  if (*row == GRIDH+1) {//need to avoid corners
	lda @w	A0FUNCT	;//col	;   if (*col != 0 && *col != GRIDW+1) {
	beq	nodown		;    return; // in bot row but not in a corner
	cmp	#GRIDW+1	;   }
	bne	rtdown		;  } else return; // not in bot row yet
nodown	dec @w	A1FUNCT	;//row	; }
rtdown	POPVARS			; --*row;
	rts			;} // indown()

inleft	dec @w	A0FUNCT	;//col	;void inleft(int8_t* col, int8_t* row) {
	bmi	noleft		; if (--*col >= 0) { // haven't fallen off edge
	bne	rtleft		;  if (*col == 0) { // need to avoid the corners
	lda @w	A1FUNCT	;//row	;   if (*row != 0 && *row != GRIDH+1) {
	beq	noleft		;    return; // in left col but not in a corner
	cmp	#GRIDH+1	;   }
	bne	rtleft		;  } else return; // not in top row yet
noleft	inc @w	A0FUNCT	;//col	; }
rtleft	POPVARS			; ++*col; // undo the move
	rts			;} // inleft()

inright	inc @w	A0FUNCT	;//col	;void inright(int8_t* col, int8_t* row) {
	lda @w	A0FUNCT	;//col	;
	cmp	#GRIDW+2	;
	bcs	noright		; if (++*col <= GRIDH+1) { // haven't fallen off
	cmp	#GRIDW+1	;
	bne	rtright		;  if (*col == GRIDH+1) {//need to avoid corners
	lda @w	A1FUNCT	;//row	;   if (*row != 0 && *row != GRIDH+1) {
	beq	noright		;    return; // in right col but not in a corner
	cmp	#GRIDH+1	;   }
	bne	rtright		;  } else return; // not in bot row yet
noright	dec @w	A0FUNCT	;//col	; }
rtright	POPVARS			; --*col;
	rts			;} // inright()

.if 1 ; not a simple xor
delighc	lda @w	A0FUNCT		;void delighc(int8_t col,int8_t row,int8_t what)
	ldy @w	A1FUNCT	;//row	;{
	jsr_a_y	rcindex,OTHRVAR	;
	tya			; if ((y = rcindex(a=col,y=row)) & 0x80 == 0) {
	bmi	+		;  // cell in range (1~10,1~8)
	lda	#DRW_CEL	;  // DRW_SEL bit not set, so won't highlight
	pha			;  int8_t w;
	lda @w	A1FUNCT		;
	pha			;  int8_t r;
	lda @w	A0FUNCT		;
	pha			;  int8_t c;
	jsrAPCS	hal_cel		;  hal_cel(y, c = col, r = row, w = DRW_CEL);
	jmp	++		; } else { // portal, so just redraw all of them
+	jsrAPCS	hal_lbl		;  hal_lbl();
+	POPVARS			; }
	rts			;} // delighc()
.else
delighc
.endif
hilighc	lda @w	A0FUNCT		;void hilighc(int8_t col,int8_t row,int8_t what)
	ldy @w	A1FUNCT	;//row	;{
	jsr_a_y	rcindex,OTHRVAR	;
	tya			; if ((y = rcindex(a=col,y=row)) & 0x80 == 0) {
	bmi	+		;  // cell in range (1~10,1~8)
	lda	#DRW_CEL|DRW_SEL;  // DRW_SEL bit set, so will highlight
	pha			;  int8_t w;
	lda @w	A1FUNCT		;
	pha			;  int8_t r;
	lda @w	A0FUNCT		;
	pha			;  int8_t c;
	jsrAPCS	hal_cel		;  hal_cel(y, c = col, r = row, w = DRW_SEL);
	jmp	++		; } else { // portal
+ nop
+	POPVARS			; }
	rts			;} // delighc()

portalf	.byte	%0010 .. %0000
portlcw				;//FIXME: C might be close, asm definitely wrong
 POPVARS
 rts
	tay			;void portlcw(register int8_t a, uint8_t col,
	beq	+		;                                uint8_t row) {
	bmi	+++++		; if (y > 0) { // warp to a specific portal 1~50
	
+	lda @w	A0FUNCT	;//col	; } else if (y == 0) { // CW: alpha inc,num dec
	ldy @w	A1FUNCT	;//row	;
	jsr_a_y	rcindex,OTHRVAR	;  register uint8_t a = rcindex(a=col, y=row);
	tya			;
	bpl	portlno		;  if (a & 0x80) { // valid portal
	bit	portalf		;
        bne	++		;   if (a & portalf == 0) { // < 0x20, t/r edges
	cmp	#$0b		;
	bcs	+		;    if (a <= 0x0a) // top edge, including 10
	inc @w	A0FUNCT	;//col	;     ++*col;
+	cmp	#$0a		;
	bcc	portlno		;    if (a >= 0x0a) // right edge, including 10
	inc @w	A1FUNCT	;//row	;     ++*row;
	cmp	#$12		;
	bne	portlno		;    if (a == 0x12) // 18, need to wrap around
	dec @w	A0FUNCT	;//col	;     --*col;
	bne	portlno		;   } else { // > 0x20, bottom/left edges
+	cmp	#$28		;
	bcc	+		;    if (a >= 0x28) // bot edge, including I
	dec @w	A0FUNCT	;//col	;     --*col;
+	cmp	#$29		;
	bcs	portlno		;    if (a <= 0x28) // left edge, including I
	dec @w	A1FUNCT	;//row	;     --*row;
	cmp	#$21		;
	bne	portlno		;    if (a == 0x21) // A, need to wrap around
	inc @w	A0FUNCT	;//col	;     ++*col;
	bne	portlno		;   }
+	bit	portalf		;  } else { // anticlockwise: alpha dec, num inc
        bne	++		;   if (a & portalf == 0) { // < 0x20, t/r edges
	cmp	#$0b		;
	bcs	+		;    if (a >= 0x0b) // right edge, including 11
	inc @w	A0FUNCT	;//col	;     --*row;
+	cmp	#$0a		;
	bcc	portlno		;    if (a <= 0x0b) // top edge, including 11
	inc @w	A1FUNCT	;//row	;     --*col;
	cmp	#$12		;
	bne	portlno		;    if (a == 0x01) // 1, need to wrap around
	dec @w	A0FUNCT	;//col	;     ++*row;
	bne	portlno		;   } else { // > 0x20, bottom/left edges
	cmp	#$28		;
	bcc	+		;    if (a >= 0x28) // bot edge, including H
	dec @w	A0FUNCT	;//col	;     ++*col;
+	cmp	#$29		;
	bcs	portlno		;    if (a <= 0x28) // left edge, including H
	dec @w	A1FUNCT	;//row	;     ++*row;
	cmp	#$21		;
	bne	portlno		;    if (a == 0x32) // R, need to wrap around
	inc @w	A0FUNCT	;//col	;     --*col;
	bne	portlno		;  }
portlno	POPVARS			; }
	rts			;} // portlcw()

toportl
 lda #0
 sta A1FUNCT
 lda #1
 sta A0FUNCT
	POPVARS
	rts			;} // toportl()

rollund	.byte	%0111 .. %0000	;
hal_inp	pha	;//V0LOCAL=input;void hal_inp(register uint8_t a) {
	pha	;//V1LOCAL=intyp; uint8_t input, intyp = a;// nteract()'s "what"
	lda	#1;0		; uint8_t inrow; // 1~8 grid, 0|9 top|bot portal
	pha	;//V2LOCAL=inrow; uint8_t incol; // 1~10 grid, 0|11 l|r portal
	lda	#1		;
	pha	;//V3LOCAL=incol;
-	jsrAPCS	hilighc		; hilighc(incol = 1, inrow = 1); // cell A1 // 0); // portal "1"
	jsr	getchar		; do {
	tya			;  register uint8_t a, y;
	sta @w	V0LOCAL	;//input;  input = getchar();
	cmp	#$91		;  switch (input) {
	bne	+		;  case 0x1d: // next cell/portal up
	jsrAPCS	delighc		;   delighc(incol, inrow);
	jsrAPCS	inup		;   inup(&incol, &inrow);
	jmp	-		;   break;
+	cmp	#$11		;
	bne	+		;  case 0x11: // next cell/portal down
	jsrAPCS	delighc		;   delighc(incol, inrow);
	jsrAPCS	indown		;   indown(&incol, &inrow);
; lda @w V3LOCAL
; ldy @w V2LOCAL
	jmp	-		;   break;
+	cmp	#$9d		;
	bne	+		;  case 0x9d: // next cell/portal left
	jsrAPCS	delighc		;   delighc(incol, inrow);
	jsrAPCS	inleft		;   inleft(&incol, &inrow);
	jmp	-		;   break;
+	cmp	#$1d		;
	bne	+		;  case 0x1d: // next cell/portal right
	jsrAPCS	delighc		;   delighc(incol, inrow);
	jsrAPCS	inright		;   inright(&incol, &inrow);
	jmp	-		;   break;
+	cmp	#','		;
	bne	+		;  case '<': // next portal counter-clockwise
	jsrAPCS	delighc		;   delighc(incol, inrow);
	jsrAPCS toportl		;   toportl(&incol, &inrow);
	ldy	#$01		;
	jsrAPCS	portlcw		;   portlcw(y = +1, &incol, &inrow);
	jmp	-		;   break;
+	cmp	#'.'		;
	bne	+		;  case '>': // next portal clockwise
	jsrAPCS	delighc		;   delighc(incol, inrow);
	jsrAPCS toportl		;   toportl(&incol, &inrow);
	ldy	#$ff		;
	jsrAPCS	portlcw		;   portlcw(y = -1, &incol, &inrow);
	jmp	-		;   break;
+	cmp	#$20		;
	bne	+++		;  case ' ': // blank shape, cell (if not hint)
	lda @w	V3LOCAL	;//incol;
	ldy @w	V2LOCAL	;//inrow;
	jsr_a_y	rcindex,OTHRVAR	;   y = rcindex(incol, inrow);
	tya			;   if (y & 0x80)
	bpl	+		;    break; // only cells have tint, not portals
	jmp	-
+	lda	TRYGRID,y	;   a = TRYGRID[y];
	and	#%1111 .. %1000	;
	sta	TRYGRID,y	;   TRYGRID[y] &= 0xf8; // can blank shape, but
	and	pokthru		;   if (a & pokthru == 0) // if we bought a hint
	beq	+		;
	jmp	-		;    break; // we can't change this cell's tint
+	sta	TRYGRID,y	;   TRYGRID[y] = UNTINTD;
	jmp	-		;   break;
+	cmp	#'+'		;
	beq	+		;  case '+': // cycle through tints (next higher)
	cmp	#'-'		;
	bne	chkpeek		;  case '-': // cycle through tints (next lower)
+	lda @w	V3LOCAL	;//incol;
	ldy @w	V2LOCAL	;//inrow;
	jsr_a_y	rcindex,OTHRVAR	;   y = rcindex(incol, inrow);
	tya			;   if (y & 0x80)
	bpl	+		;    break; // only cells have tint, not portals
	jmp	-
+	lda	TRYGRID,y	;   a = TRYGRID[y];
	bit	pokthru		;   if (a & pokthru == 0) // if we bought a hint
	beq	+		;
	jmp	-		;    break; // we can't change this cell's tint
+	sta	OTHRVAR		;
	sec			;
	lda	#','		;
	sbc @w	V0LOCAL	;//input; // 0x2b +  0x2c ,  0x2d - (so N flag set if -)
	php			;
	lda	OTHRVAR		;
	plp			;
	bpl	+++		;   if (input == '-') {
	sec			;
	sbc	#%0001 .. %0000	;    a -= 0x10; // decrement tint, remembering
	bit	rollund		;
	beq	+		;    if ((a & 0x70 == 0) || // just rolled under
	bpl	++		;      (a & RUBOUT)) // RED to UNTINTD to RUBOUT
+	and	#%0000 .. %1111	;     a = 0x80 | (a & 0x0f);
	ora	#RUBOUT		;
	jmp	++++		;
+	cmp	#RUBWHT+$10	;
	bcc	+++		;    else if (a >= RUBWHT+0x10) // no tints >0x50
	and	#%0000 .. %1111	;
	ora	#RUBWHT		;     a = 0x50 | (a & 0x0f);
	jmp	+++		;
+	clc			;   } else { // input == '+'
	adc	#%0001 .. %0000	;    a += 0x10; // increment tint, remembering
	bpl	+		;    if (a & RUBOUT) // we just advanced to 0x9_
	and	#%0000 .. %1111	;
	ora	#RUBRED		;     a = 0x10 | (a & 0x0f);
	jmp	++		;
+	cmp	#RUBWHT+$10	;
	bcc	+		;    else if (a >= RUBWHT+0x10) // no tints >0x50
	and	#%0000 .. %1111	;     a = 0x80 | (a & 0x0f); // so 0x50 then 0x80
	ora	#RUBOUT		;   }
+	sta	TRYGRID,y	;   TRYGRID[y] = a;
	jsrAPCS	hal_cel		;   hal_cel(y, incol, inrow, intyp);
	jmp	-		;   break;
chkpeek	cmp	#'@'		;
	bne	++		;  case '@':
	lda @w	V3LOCAL	;//incol;
	ldy @w	V2LOCAL	;//inrow;
	jsr_a_y	rcindex,OTHRVAR	;
	tya			;
	bpl	++		;   if ((y = rcindex(a = incol, y = inrow))>=0){
	lda @w	V1LOCAL	;//intyp;    // a cell is highlighted, not a portal
	and	#SAY_PEK	;
	bne	+		;    if (intyp&SAY_PEK == 0) // peeks disallowed
	jmp	-		;     break;
+	tya			;    else
	ora	#%1000 .. %0000	;
	jmp	inprety		;    return y |= 0x80;//request a hint this cell
+	and	#$5f		;   }
	bne	++		;  case 's':
	lda @w	V1LOCAL	;//intyp;  case 'S':
	and	#SAY_ANS	;
	bne	+		;
	jmp	-		;   if (intyp & ask_ans) //submission is allowed
+	ldy	#SUBMITG	;    return y = SUBMITG; //submit grid for grade
	jmp	inprety		;  case 'a':case 'b':case 'c':case 'd':case 'e':
+	cmp	#'a'		;  case 'A':case 'B':case 'C':case 'D':case 'E':
	bcc	+		;  case 'f':case 'g':case 'h':case 'i':case 'j':
	cmp	#'s'		;  case 'F':case 'g':case 'H':case 'I':case 'J':
	bcs	+		;  case 'k':case 'l':case 'm':case 'n':case 'o':
	sec			;  case 'K':case 'L':case 'M':case 'N':case 'O':
	sbc	#'@'		;  case 'p':case 'q':case 'r':
	ora	#$20		;  case 'P':case 'Q':case 'R':
	sta @w	V0LOCAL	;//input;   input = tolower(input) - 'a';
	jsrAPCS	delighc		;   delighc(incol, inrow);
	ldy @w	V0LOCAL	;//input;
	jsrAPCS	portlcw		;   portlcw(y = input, &incol, &inrow);
	lda	#$0d		;   // break intentionally omitted; fall through
+	cmp	#$0d		;
	bne	chkquit		;  case '\n'; // launch a beam or cycle shapes
	lda @w	V3LOCAL	;//incol;
	ldy @w	V2LOCAL	;//inrow;
	jsr_a_y	rcindex,OTHRVAR	;
	tya			;
	bpl	++		;   if ((y = rcindex(a = incol,y = inrow)) < 0){
	lda @w	V1LOCAL	;//intyp;    // a portal is highlighted, not a cell
	and	#SAY_PRT	;
	bne	+		;    if (intyp&SAY_PRT == 0) //launch disallowed
	jmp	-		;     break;
+	tya			;    else
	bne	inpretp		;    return y &= 0x7f;// launch beam from portal
+	lda	TRYGRID,y	;   }
	and	#%1111 .. %1000	;   // copied from tempins: below, rtval->input
	bne	+		;   input = TRYGRID[y] & 0xf8; // tint, pokthru
	lda	#RUBWHT		;   if (input == UNTINTD)
+	sta @w	V0LOCAL	;//input;    input = RUBWHT; // can't do untinted shapes
	lda	TRYGRID,y	;
	and	#%0000 .. %0111	;
	clc			;
	adc	#%0000 .. %0001	;   a = (TRYGRID[y] & 0x07) + 1;// next shape
	cmp	#MAXSHAP+1	;
	bcc	+		;   if (a > MAXSHAP) { // roll around to BLANK
	lda @w	V0LOCAL	;//input;
	bit	pokthru		;
	bne	++		;    if (input & pokthru == 0) // if not a hint
	lda	#BLANK		;     a = BLANK;//must clear tint to fully blank
	beq	++		;  //else input &= 0xf8; // unchanged
+	ora @w	V0LOCAL	;//input;   }
+	sta 	TRYGRID,y	;   TRYGRID[y] = input | a; // bit 3 untouched
	jsrAPCS	hal_cel		;   hal_cel(y, incol, inrow, intyp);
	jmp	-		;   break;
chkquit	eor	#'x'		;  case 'x':
	beq	inpreta		;   return y = 0;
	jmp	-		;  }
inpretp	and	#%0111 .. %1111	; } while (1); // waiting for '\n' or x
inpreta	tay			;
inprety	POPVARS			;
	rts			;} // hal_inp()

.else
reallyq	.null $14,"are you sure?";
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

hal_inp	lda	#$0d		;uint8_t hal_inp(void) {
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
	bcc	+		;   if (a > MAXSHAP) { // roll around to BLANK
	lda @w	V0LOCAL	;//rtval;
	bit	pokthru		;
	bne	++		;    if (rtval & pokthru == 0) // if not a hint
	lda	#BLANK		;     rtval = BLANK; // must clear tint to blank
	beq	++		;  //else rtval &= 0xf8; // unchanged
+	ora @w	V0LOCAL	;//rtval;   } else
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
	rts			;} // hal_inp()

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
