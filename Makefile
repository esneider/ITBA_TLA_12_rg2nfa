
all:
	flex regular_grammar.l
	gcc -lfl lex.yy.c
	rm *.yy.*
