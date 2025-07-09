obstlst
	.byte	obstac2-obstlst	;
	.byte	RUBBLU		;
	.byte	tri6_0e-tri6_0	;
	.byte	tri6_0-obstcel	;
	.byte	tri6_1-obstcel	;
	.byte	tri6_2-obstcel	;
	.byte	tri6_3-obstcel	;
	
obstac2
	.byte	obstac3-obstlst	;
	.byte	RUBWHT		;
	.byte	tri6_0e-tri6_0	;
	.byte	tri6_0-obstcel	;
	.byte	tri6_1-obstcel	;
	.byte	tri6_2-obstcel	;
	.byte	tri6_3-obstcel	;

obstac3
	.byte	obstac4-obstlst	;
	.byte	RUBWHT		;
	.byte	diamo4e-diamo4	;
	.byte	diamo4-obstcel	;
	.byte	diamo4-obstcel	;
	.byte	diamo4-obstcel	;
	.byte	diamo4-obstcel	;
	
obstac4
	.byte	obstac5-obstlst	;
	.byte	RUBYEL		;
	.byte	tri3_0e-tri3_0	;
	.byte	tri3_0-obstcel	;
	.byte	tri3_1-obstcel	;
	.byte	tri3_2-obstcel	;
	.byte	tri3_3-obstcel	;
	
obstac5
	.byte	obstac6-obstlst	;
	.byte	RUBRED		;
	.byte	rpar_0e-rpar_0
	.byte	rpar_0-obstcel	;
	.byte	rpar_1-obstcel	;
	.byte	lpar_0-obstcel	;
	.byte	lpar_1-obstcel	;

obstac6
.if 0
	.byte	obstac7-obstlst	;
	.byte	UNTINTD		;
	.byte	tra3_0e-tra3_0	;
	.byte	tra3_0-obstcel	;
	.byte	tra3_1-obstcel	;
	.byte	tra3_2-obstcel	;
	.byte	tra3_3-obstcel	;
	
obstac7
	.byte	obstend-obstlst	;
	.byte	RUBOUT		;
	.byte	rct2_0e-rct2_0	;
	.byte	rct2_0-obstcel	;
	.byte	rct2_1-obstcel	;
	.byte	rct2_0-obstcel	;
	.byte	rct2_1-obstcel	;
	
obstend
.endif
	.byte	0
	

obstcel

;;;// placement constraints for TL corner in A~H ($7=none), 1-10 ($9=none)
tri6_0	.byte	$6 .. $6
	.byte	(CHAMFTL<<5)|$01
	.byte	(CHAMFTL<<5)|$08
	.byte	(SQUARE	<<5)|$09	
	.byte	(CHAMFTR<<5)|$10
	.byte	(SQUARE	<<5)|$11
tri6_0e	.byte	(CHAMFTR<<5)|$19
	
tri6_1	.byte	$4 .. $8	; pointing toward RT
	.byte	(CHAMFTR<<5)|$00
	.byte	(SQUARE	<<5)|$01
	.byte	(SQUARE	<<5)|$02
	.byte	(CHAMFBR<<5)|$03
	.byte	(CHAMFTR<<5)|$09
tri6_1e	.byte	(CHAMFBR<<5)|$0a
	
tri6_2	.byte	$6 .. $6	; pointing toward BT
	.byte	(CHAMFBL<<5)|$00
	.byte	(SQUARE	<<5)|$08
	.byte	(CHAMFBL<<5)|$09
	.byte	(SQUARE	<<5)|$10
	.byte	(CHAMFBR<<5)|$11
tri6_2e	.byte	(CHAMFBR<<5)|$18
tri6_3	.byte	$4 .. $8	; pointing toward LT
	.byte	(CHAMFTL<<5)|$01
	.byte	(CHAMFBL<<5)|$02
	.byte	(CHAMFTL<<5)|$08
	.byte	(SQUARE <<5)|$09
	.byte	(SQUARE	<<5)|$0a
tri6_3e	.byte	(CHAMFBL<<5)|$0b
	
diamo4	.byte	$6 .. $8	;
	.byte	(CHAMFTL<<5)|$00
	.byte	(CHAMFBL<<5)|$01
	.byte	(CHAMFTR<<5)|$08
diamo4e	.byte	(CHAMFBR<<5)|$09
	
	
tri3_0	.byte	$6 .. $8	; pointing toward BT LT
	.byte	(CHAMFTR<<5)|$00
	.byte	(SQUARE	<<5)|$01
tri3_0e	.byte	(CHAMFTR<<5)|$09

tri3_1	.byte	$6 .. $8	; pointing toward TP LT
	.byte	(SQUARE	<<5)|$00
	.byte	(CHAMFBR<<5)|$01
tri3_1e	.byte	(CHAMFBR<<5)|$08

tri3_2	.byte	$6 .. $8	; pointing toward TP RT
	.byte	(CHAMFBL<<5)|$00
	.byte	(SQUARE	<<5)|$08
tri3_2e	.byte	(CHAMFBL<<5)|$09

tri3_3	.byte	$6 .. $8	; pointing toward BT RT
	.byte	(CHAMFTL<<5)|$01
	.byte	(CHAMFTL<<5)|$08
tri3_3e	.byte	(SQUARE	<<5)|$09
	

rpar_0	.byte	$5 .. $9	; V RH parallelogram
	.byte	(CHAMFTL<<5)|$00
	.byte	(SQUARE	<<5)|$01
rpar_0e	.byte	(CHAMFBR<<5)|$02

rpar_1	.byte	$7 .. $7	; H RH parallelogram
	.byte	(CHAMFBL<<5)|$00
	.byte	(SQUARE	<<5)|$08
rpar_1e	.byte	(CHAMFTR<<5)|$10

lpar_0	.byte	$5 .. $9	; V LH parallelogram
	.byte	(CHAMFTR<<5)|$00
	.byte	(SQUARE	<<5)|$01
lpar_03	.byte	(CHAMFBL<<5)|$02

lpar_1	.byte	$7 .. $7	; H LH parallelogram
	.byte	(CHAMFTL<<5)|$00
	.byte	(SQUARE	<<5)|$08
lpar_1e	.byte	(CHAMFBR<<5)|$10

.if 0
tra3_0	.byte	$5 .. $9	; V trapezoid pointing toward LT
	.byte	(CHAMFTL<<5)|$00
	.byte	(SQUARE	<<5)|$01
tra3_0e	.byte	(CHAMFBL<<5)|$02

tra3_1	.byte	$7 .. $7	; H trapezoid pointing toward TP
	.byte	(CHAMFTL<<5)|$00
	.byte	(SQUARE	<<5)|$08
tra3_1e	.byte	(CHAMFTR<<5)|$10

tra3_2	.byte	$5 .. $9	; V trapezoid pointing toward RT
	.byte	(CHAMFTR<<5)|$00
	.byte	(SQUARE	<<5)|$01
tra3_2e	.byte	(CHAMFBR<<5)|$02

tra3_3	.byte	$7 .. $7	; H trapezoid pointing toward BT
	.byte	(CHAMFBL<<5)|$00
	.byte	(SQUARE	<<5)|$08
tra3_3e	.byte	(CHAMFBR<<5)|$10

rct2_0	.byte	$6 .. $9	; V pair
	.byte	(SQUARE	<<5)|$00
rct2_0e	.byte	(SQUARE <<5)|$01

rct2_1	.byte	$7 .. $8	; H pair
	.byte	(SQUARE <<5)|$00
rct2_1e	.byte	(SQUARE	<<5)|$08
.endif

obsten2
