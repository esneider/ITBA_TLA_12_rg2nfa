
all:
	flex -P gr regular_grammar.l
	flex -P fa finite_automata.l
	gcc -m32 -g -std=c99 -pedantic -Wall -Wextra lex.gr.c lex.fa.c rg2nfa.c -o rg2nfa
	rm *.gr.* *.fa.*
