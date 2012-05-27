
all:
	flex -P gr regular_grammar.l
	gcc -g -std=c99 -pedantic -Wall -Wextra lex.gr.c rg2nfa.c
	rm *.gr.*
