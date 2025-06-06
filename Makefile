all : petswana_p500.prg petswana_c64.prg petswana_c16.prg

petswana_p500.prg : main.asm p500/header.inc
	64tass -a p500/header.inc main.asm --verbose-list -L petswana_p500.lst -o petswana_p500.prg

petswana_c64.prg : main.asm c64/header.inc
	64tass -a c64/header.inc main.asm --verbose-list -L petswana_c64.lst -o petswana_c64.prg

petswana_c16.prg : main.asm c16/header.inc
	64tass -a c16/header.inc main.asm --verbose-list -L petswana_c16.lst -o petswana_c16.prg

clean :
	rm -f *.prg *.lst
