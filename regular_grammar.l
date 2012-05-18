%{

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "rg2nfa.h"

extern struct grammar *yylval;

char last_left_production = 0;

void set_grammar_name( void );
void add_non_terminal( void );
void add_terminal( void );
void add_initial_symbol( void );
void add_production_left( void );
void add_production_right( void );

%}

low_letter     [a-z]
up_letter      [A-Z]
letter         ({low_letter}|{up_letter})

whitespace     [ \t\f\v\n\r]
grammar_name   {letter}[^ \t\f\v\n\r=]*
terminals      {low_letter}
non_terminals  {up_letter}
productions    {letter}({whitespace}*{letter}+)*

def_begin      {whitespace}*"="{whitespace}*"("{whitespace}*"{"
def_delimiter  "}"{whitespace}*","{whitespace}*"{"
def_end        "}"{whitespace}*")"{whitespace}*
def_delimiter_initial_sym_begin "}"{whitespace}*","
def_delimiter_initial_sym_end   ","{whitespace}*"{"

%x DEF_BEGIN NON_TERMINALS NON_TERMINALS_COMMA TERMINALS TERMINALS_COMMA
%x INITIAL_SYM INITIAL_SYM_END PRODUCTIONS_LEFT PRODUCTIONS_ARROW
%x PRODUCTIONS_RIGHT PRODUCTIONS_RIGHT_COMMA

%option yylineno

%%

{whitespace} { }

{grammar_name} { set_grammar_name(); BEGIN( DEF_BEGIN ); }

<DEF_BEGIN>{def_begin} { BEGIN( NON_TERMINALS ); }


<NON_TERMINALS,NON_TERMINALS_COMMA>{whitespace} { }

<NON_TERMINALS>{non_terminals} { add_non_terminal(); BEGIN( NON_TERMINALS_COMMA ); }

<NON_TERMINALS_COMMA>"," { BEGIN( NON_TERMINALS ); }

<NON_TERMINALS,NON_TERMINALS_COMMA>{def_delimiter} { BEGIN( TERMINALS ); }


<TERMINALS,TERMINALS_COMMA>{whitespace} { }

<TERMINALS>{terminals} { add_terminal(); BEGIN( TERMINALS_COMMA ); }

<TERMINALS_COMMA>"," { BEGIN( TERMINALS ); }

<TERMINALS,TERMINALS_COMMA>{def_delimiter_initial_sym_begin} { BEGIN( INITIAL_SYM ); }


<INITIAL_SYM,INITIAL_SYM_END>{whitespace} { }

<INITIAL_SYM>{non_terminals} { add_initial_symbol(); BEGIN( INITIAL_SYM_END ); }

<INITIAL_SYM_END>{def_delimiter_initial_sym_end} { BEGIN( PRODUCTIONS_LEFT ); }


<PRODUCTIONS_LEFT,PRODUCTIONS_ARROW,PRODUCTIONS_RIGHT,PRODUCTIONS_RIGHT_COMMA>{whitespace} { }

<PRODUCTIONS_LEFT>{non_terminals} { add_production_left(); BEGIN( PRODUCTIONS_ARROW ); }

<PRODUCTIONS_ARROW>"->" { BEGIN( PRODUCTIONS_RIGHT ); }

<PRODUCTIONS_RIGHT>{productions} { add_production_right(); BEGIN( PRODUCTIONS_RIGHT_COMMA ); }

<PRODUCTIONS_RIGHT>"\\" { add_production_right(); BEGIN( PRODUCTIONS_RIGHT_COMMA ); }

<PRODUCTIONS_RIGHT_COMMA>"|" { BEGIN( PRODUCTIONS_RIGHT ); }

<PRODUCTIONS_RIGHT_COMMA>"," { BEGIN( PRODUCTIONS_LEFT ); }

<PRODUCTIONS_RIGHT_COMMA,PRODUCTIONS_LEFT>{def_end} { }


. {
    printf( "%d: error: illegal grammar name\n", yylineno );
	return 1;
}

<DEF_BEGIN>. {
    printf( "%d: error: invalid grammar, it should be `name=({non-terminals},"
            "{terminals},initial,{productions})'\n", yylineno );

    free_grammar( yylval );
	return 1;
}

<NON_TERMINALS>. {
    printf( "%d: error: illegal non-terminal symbol, it should be an upper "
            "case letter\n", yylineno );

    free_grammar( yylval );
	return 1;
}

<NON_TERMINALS_COMMA>. {
    printf( "%d: error: missing comma between non-terminal symbols\n", yylineno );

    free_grammar( yylval );
	return 1;
}

<TERMINALS>. {
    printf( "%d: error: illegal terminal symbol, it should be a lower case "
            "letter\n", yylineno );

    free_grammar( yylval );
	return 1;
}

<TERMINALS_COMMA>. {
    printf( "%d: error: missing comma between terminal symbols\n", yylineno );

    free_grammar( yylval );
	return 1;
}

<INITIAL_SYM>. {
    printf( "%d: error: illegal initial symbol, it should be an upper case "
            "letter\n", yylineno );

    free_grammar( yylval );
	return 1;
}

<INITIAL_SYM_END>. {
    printf( "%d: error: missing comma after the initial symbol\n", yylineno );

    free_grammar( yylval );
	return 1;
}

<PRODUCTIONS_LEFT>. {
    printf( "%d: error: illegal left side of production, it should be an upper "
            "case letter\n", yylineno );

    free_grammar( yylval );
	return 1;
}

<PRODUCTIONS_ARROW>. {
    printf( "%d: error: missing `->' after left side of production\n", yylineno );

    free_grammar( yylval );
	return 1;
}

<PRODUCTIONS_RIGHT>. {
    printf( "%d: error: illegal right side of production, it shoud be a "
            "sequence of letters\n", yylineno );

    free_grammar( yylval );
	return 1;
}

<PRODUCTIONS_RIGHT_COMMA>. {
    printf( "%d: error: missing comma or pipe after production\n", yylineno );

    free_grammar( yylval );
	return 1;
}

%%

void set_grammar_name( void ) {

    yylval = new_grammar();

    yylval->name = malloc( yyleng + 1 );

    if ( !yylval->name ) {

        free_grammar( yylval );
        memory_error();
    }

    strcpy( yylval->name, yytext );
}

void add_non_terminal( void ) {

    printf( "non-terminal symbol: '%s'\n", yytext );

    yylval->non_terminals[ yylval->num_non_terminals++ ] = yytext[0];
}

void add_terminal( void ) {

    printf( "terminal symbol: '%s'\n", yytext );

    yylval->terminals[ yylval->num_terminals++ ] = yytext[0];
}

void add_initial_symbol( void ) {

    printf( "initial symbol: '%s'\n", yytext );

    yylval->initial = yytext[0];
}

void add_production_left( void ) {

    last_left_production = yytext[0];
}

void add_production_right( void ) {

    struct production* production = grammar_new_production( yylval );

    production->left = last_left_production;
    production->right = malloc( yyleng + 1 );

    if ( !production->right ) {

        free_grammar( yylval );
        memory_error();
    }

    strcpy( production->right, yytext );
}

struct grammar* yylval;

int main( void ) {

    if ( !yylex() ) {
        free_grammar( yylval );
    }

    return 0;
}

