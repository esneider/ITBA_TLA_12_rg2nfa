
all:
	flex -P gr regular_grammar.l
	gcc -g -std=c99 -pedantic -Wall -Wextra lex.gr.c rg2nfa.c
	rm *.gr.*

fa:
	flex -P fa finite_automata.l
	gcc -g -std=c99 -pedantic -Wall -Wextra lex.fa.c
	rm *.fa.*
