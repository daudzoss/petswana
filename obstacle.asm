obstlst	.byte	obstac2-obstlst	;
	.byte	RUBBLU		;
	.byte	rot1blu-rot0blu	;
	.byte	rot0blu-obstcel	;
	.byte	rot1blu-obstcel	;
	.byte	rot2blu-obstcel	;
	.byte	rot3blu-obstcel	;
	
obstac2	.byte	obstac3-obstlst	;
	.byte	RUBWHT		;
	.byte	rot1wht-rot0wht	;
	.byte	rot0wht-obstcel	;
	.byte	rot1wht-obstcel	;
	.byte	rot2wht-obstcel	;
	.byte	rot3wht-obstcel	;

obstac3	.byte	obstac4-obstlst	;
	.byte	RUBWHT		;
	.byte	rot1wh2-rot0wh2	;
	.byte	rot0wh2-obstcel	;
	.byte	rot1wh2-obstcel	;
	.byte	rot2wh2-obstcel	;
	.byte	rot3wh2-obstcel	;
	
obstac4	.byte	obstac5-obstlst	;
	.byte	RUBYEL		;
	.byte	rot1yel-rot0yel	;
	.byte	rot0yel-obstcel	;
	.byte	rot1yel-obstcel	;
	.byte	rot2yel-obstcel	;
	.byte	rot3yel-obstcel	;
	
obstac5	.byte	obstac6-obstlst	;
	.byte	RUBRED		;
	.byte	rot1red-rot0red	;
	.byte	rot0red-obstcel	;
	.byte	rot1red-obstcel	;
	.byte	rot2red-obstcel	;
	.byte	rot3red-obstcel	;

obstac6	.byte	obstac7-obstlst	;
	.byte	UNTINTD		;
	.byte	rot1unt-rot0unt	;
	.byte	rot0unt-obstcel	;
	.byte	rot1unt-obstcel	;
	.byte	rot2unt-obstcel	;
	.byte	rot3unt-obstcel	;
	
obstac7	.byte	obstend-obstlst	;
	.byte	RUBOUT		;
	.byte	rot1abs-rot0abs	;
	.byte	rot0abs-obstcel	;
	.byte	rot1abs-obstcel	;
	.byte	rot2abs-obstcel	;
	.byte	rot3abs-obstcel	;
	
obstend	.byte	0
	

obstcel
rot0blu
rot0wht	
	.byte	$6 .. $6	; // placement constraints for TL corner in A~H ($7=none), 1-10 ($9=none)
	.byte	(CHAMFTL<<5)|$01
	.byte	(CHAMFTL<<5)|$08
	.byte	(SQUARE	<<5)|$09	
	.byte	(CHAMFTR<<5)|$10
	.byte	(SQUARE	<<5)|$11
	.byte	(CHAMFTR<<5)|$19
rot1blu
rot1wht
	.byte	$4 .. $8	; pointing toward RT
	.byte	(CHAMFTR<<5)|$00
	.byte	(SQUARE	<<5)|$01
	.byte	(SQUARE	<<5)|$02
	.byte	(CHAMFBR<<5)|$03
	.byte	(CHAMFTR<<5)|$09
	.byte	(CHAMFBR<<5)|$0a
rot2blu
rot2wht
	.byte	$6 .. $6	; pointing toward BT
	.byte	(CHAMFBL<<5)|$00
	.byte	(SQUARE	<<5)|$08
	.byte	(CHAMFBL<<5)|$09
	.byte	(SQUARE	<<5)|$10
	.byte	(CHAMFBR<<5)|$11
	.byte	(CHAMFBR<<5)|$18
rot3blu
rot3wht
	.byte	$4 .. $8	; pointing toward LT
	.byte	(CHAMFTL<<5)|$01
	.byte	(CHAMFBL<<5)|$02
	.byte	(CHAMFTL<<5)|$08
	.byte	(SQUARE <<5)|$09
	.byte	(SQUARE	<<5)|$0a
	.byte	(CHAMFBL<<5)|$0b
	

rot0wh2
rot1wh2
rot2wh2
rot3wh2
	.byte	$6 .. $8	;
	.byte	(CHAMFTL<<5)|$00
	.byte	(CHAMFBL<<5)|$01
	.byte	(CHAMFTR<<5)|$08
	.byte	(CHAMFBR<<5)|$09
	
	
rot0yel
	.byte	$6 .. $8	; pointing toward BT LT
	.byte	(CHAMFTR<<5)|$00
	.byte	(SQUARE	<<5)|$01
	.byte	(CHAMFTR<<5)|$09
rot1yel
	.byte	$6 .. $8	; pointing toward TP LT
	.byte	(SQUARE	<<5)|$00
	.byte	(CHAMFBR<<5)|$01
	.byte	(CHAMFBR<<5)|$08
rot2yel
	.byte	$6 .. $8	; pointing toward TP RT
	.byte	(CHAMFBL<<5)|$00
	.byte	(SQUARE	<<5)|$08
	.byte	(CHAMFBL<<5)|$09
rot3yel
	.byte	$6 .. $8	; pointing toward BT RT
	.byte	(CHAMFTL<<5)|$01
	.byte	(CHAMFTL<<5)|$08
	.byte	(CHAMFTL<<5)|$09
	

rot0red
	.byte	$5 .. $9	; V RH parallelogram
	.byte	(CHAMFTL<<5)|$00
	.byte	(SQUARE	<<5)|$01
	.byte	(CHAMFBR<<5)|$02
rot1red
	.byte	$7 .. $7	; H RH parallelogram
	.byte	(CHAMFBL<<5)|$00
	.byte	(SQUARE	<<5)|$08
	.byte	(CHAMFTR<<5)|$10
rot2red
	.byte	$5 .. $9	; V LH parallelogram
	.byte	(CHAMFTR<<5)|$00
	.byte	(SQUARE	<<5)|$01
	.byte	(CHAMFBL<<5)|$02
rot3red	
	.byte	$7 .. $7	; H LH parallelogram
	.byte	(CHAMFTL<<5)|$00
	.byte	(SQUARE	<<5)|$08
	.byte	(CHAMFBR<<5)|$10
	

rot0unt
	.byte	$5 .. $9	; V trapezoid pointing toward LT
	.byte	(CHAMFTL<<5)|$00
	.byte	(SQUARE	<<5)|$01
	.byte	(CHAMFBL<<5)|$02
rot1unt
	.byte	$7 .. $7	; H trapezoid pointing toward TP
	.byte	(CHAMFTL<<5)|$00
	.byte	(SQUARE	<<5)|$08
	.byte	(CHAMFTR<<5)|$10
rot2unt
	.byte	$5 .. $9	; V trapezoid pointing toward RT
	.byte	(CHAMFTR<<5)|$00
	.byte	(SQUARE	<<5)|$01
	.byte	(CHAMFBR<<5)|$02
rot3unt
	.byte	$7 .. $7	; H trapezoid pointing toward BT
	.byte	(CHAMFBL<<5)|$00
	.byte	(SQUARE	<<5)|$08
	.byte	(CHAMFBR<<5)|$10

rot0abs
rot2abs
	.byte	$6 .. $9	; V pair
	.byte	(SQUARE	<<5)|$00
	.byte	(SQUARE <<5)|$01
rot1abs
rot3abs
	.byte	$7 .. $8	; H pair
	.byte	(SQUARE <<5)|$00
	.byte	(SQUARE	<<5)|$08

obsten2
