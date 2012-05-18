
all:
	flex -P gr regular_grammar.l
	gcc -g -lfl lex.gr.c rg2nfa.c
	rm *.gr.*
