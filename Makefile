
all:
	flex regular_grammar.l
	gcc -g -lfl lex.yy.c rg2nfa.c
	rm *.yy.*
