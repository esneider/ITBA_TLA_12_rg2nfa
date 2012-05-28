%{

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "rg2nfa.h"

extern struct grammar *grlval;

static char last_left_production = 0;

static bool ok = false;

static int grerror( const char *msg );
static void set_grammar_name( void );
static void add_non_terminal( void );
static void add_terminal( void );
static void add_initial_symbol( void );
static void add_production_left( void );
static void add_production_right( void );

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
%x PRODUCTIONS_RIGHT PRODUCTIONS_RIGHT_COMMA DEF_END

%option yylineno
%option nounput

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

<PRODUCTIONS_RIGHT_COMMA,PRODUCTIONS_LEFT>{def_end} { ok = true; BEGIN( DEF_END ); }


<DEF_END><<EOF>> { return grlval->type == NON_REGULAR_GRAMMAR; }

<INITIAL,DEF_BEGIN,NON_TERMINALS,NON_TERMINALS_COMMA,TERMINALS,TERMINALS_COMMA,INITIAL_SYM,INITIAL_SYM_END,PRODUCTIONS_LEFT,PRODUCTIONS_ARROW,PRODUCTIONS_RIGHT,PRODUCTIONS_RIGHT_COMMA><<EOF>> { return grerror( "unexpected end of file" ); }

. { grlval = NULL; return grerror( "illegal grammar name" ); }

<DEF_BEGIN>. { return grerror( "invalid grammar, it should be `name=({non-terminals},{terminals},initial,{productions})'" ); }

<NON_TERMINALS>. { return grerror( "illegal non-terminal symbol, it should be an upper case letter" ); }

<NON_TERMINALS_COMMA>. { return grerror( "missing comma between non-terminal symbols" ); }

<TERMINALS>. { return grerror( "illegal terminal symbol, it should be a lower case letter" ); }

<TERMINALS_COMMA>. { return grerror( "missing comma between terminal symbols" ); }

<INITIAL_SYM>. { return grerror( "illegal initial symbol, it should be an upper case letter" ); }

<INITIAL_SYM_END>. { return grerror( "missing comma after the initial symbol" ); }

<PRODUCTIONS_LEFT>. { return grerror( "illegal left side of production, it should be an upper case letter" ); }

<PRODUCTIONS_ARROW>. { return grerror( "missing `->' after left side of production" ); }

<PRODUCTIONS_RIGHT>. { return grerror( "illegal right side of production, it shoud be a sequence of letters" ); }

<PRODUCTIONS_RIGHT_COMMA>. { return grerror( "missing comma, pipe or '})' after production" ); }

<DEF_END>. { return grerror( "illegal character after grammar definition" ); }


%%


static int grerror( const char *msg ) {

    printf( "%d: error: %s\n", yylineno, msg );

    free_grammar( grlval );

	return 1;
}


static void set_grammar_name( void ) {

    grlval = new_grammar();

    grlval->name = malloc( grleng + 1 );

    if ( !grlval->name ) {

        free_grammar( grlval );
        memory_error();
    }

    strcpy( grlval->name, grtext );
}


static void add_non_terminal( void ) {

    printf( "non-terminal symbol: '%s'\n", grtext );

    grlval->non_terminals[ grlval->num_non_terminals++ ] = grtext[0];
}


static void add_terminal( void ) {

    printf( "terminal symbol: '%s'\n", grtext );

    grlval->terminals[ grlval->num_terminals++ ] = grtext[0];
}


static void add_initial_symbol( void ) {

    printf( "initial symbol: '%s'\n", grtext );

    grlval->initial = grtext[0];
}


static void add_production_left( void ) {

    last_left_production = grtext[0];
}


static void add_production_right( void ) {

    char (*right)[2] = grammar_new_production( grlval, last_left_production );

    for ( int pos_text = 0, pos_right = 0; pos_text < (int)grleng; pos_text++ ) {

        if ( grtext[ pos_text ] != ' '  && grtext[ pos_text ] != '\t' &&
             grtext[ pos_text ] != '\f' && grtext[ pos_text ] != '\v' &&
             grtext[ pos_text ] != '\n' && grtext[ pos_text ] != '\r' ) {

            switch ( pos_right++ ) {

                case 0:

                    (*right)[0] = grtext[ pos_text ];

                    if ( (*right)[0] == '\\' )
                        grlval->empty = last_left_production;

                    break;

                case 1:

                    (*right)[1] = grtext[ pos_text ];

                    if ( !( ( (*right)[0] < 'a' ) ^ ( (*right)[1] < 'a' ) ) )
                        grlval->type = NON_REGULAR_GRAMMAR;
                    else
                    if ( (*right)[0] < 'a' )
                        grlval->type |= LEFT_REGULAR_GRAMMAR;
                    else
                        grlval->type |= RIGHT_REGULAR_GRAMMAR;

                    break;

                default:

                    grlval->type = NON_REGULAR_GRAMMAR;

                    break;
            }
        }
    }
}


int grwrap( void ) {

    const char* out[] = {

        [ LEFT_REGULAR_GRAMMAR ]  = "left ",
        [ RIGHT_REGULAR_GRAMMAR ] = "right ",
        [ NON_REGULAR_GRAMMAR ]   = "non-",
    };

    if ( ok ) {

        printf( "the input is a valid %sregular grammar\n", out[ grlval->type ] );

        if ( grlval->type == NON_REGULAR_GRAMMAR )
            grerror( "non-regular grammar" );
    }

    return 1;
}

