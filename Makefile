
all:
	flex -P grammar regular_grammar.l
	gcc -g -lfl lex.grammar.c rg2nfa.c
	rm *.grammar.*
