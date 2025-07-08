all : petswana.prg petswana_vic20.prg petswana_c64.prg petswana_c16.prg

petswana.prg : 6502apcs.inc visualz.asm nteract.asm obstacle.asm main.asm generic/header.inc
	64tass -a -Wall -Wno-strict-bool -Wno-implied-reg generic/header.inc main.asm --verbose-list -L petswana.lst -o petswana.prg

petswana_vic20.prg : 6502apcs.inc visualz.asm nteract.asm obstacle.asm main.asm vic20/header.inc
	64tass -a -Wall -Wno-strict-bool -Wno-implied-reg -DVIC20UNEXP:=true vic20/header.inc main.asm --verbose-list -L petswana_vic20.lst -o petswana_vic20.prg

petswana_c64.prg : 6502apcs.inc visualz.asm nteract.asm obstacle.asm main.asm c64/header.inc
	64tass -a -Wall -Wno-strict-bool -Wno-implied-reg c64/header.inc main.asm --verbose-list -L petswana_c64.lst -o petswana_c64.prg

petswana_c16.prg : 6502apcs.inc visualz.asm nteract.asm obstacle.asm main.asm c16/header.inc
	64tass -a -Wall -Wno-strict-bool -Wno-implied-reg c16/header.inc main.asm --verbose-list -L petswana_c16.lst -o petswana_c16.prg

clean :
	rm -f *.prg *.lst
