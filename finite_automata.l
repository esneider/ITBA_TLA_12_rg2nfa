%{

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "rg2nfa.h"

extern struct grammar *falval;

static bool terminal;
static char last_left_production;
static char last_right_production;

static int faerror( const char *msg );
static void add_node_name( void );
static void add_production_left( void );
static void add_production_right( void );
static void add_production_terminal( void );

%}

whitespace     [ \t\f\v\n\r]
comment        ({whitespace}*"//"[^\n]*)*{whitespace}*

%x NODES NODE_TYPE NODE_BEFORE_NAME NODE_NAME NODE_LABEL PRODUCTION_MIDDLE
%x PRODUCTION_RIGHT PRODUCTION_LABEL PRODUCTION_TERMINAL DEF_END

%option yylineno
%option nounput

%%

{comment} { }

{comment}*"digraph"{comment}"{" { BEGIN( NODES ); }


<NODES>{comment} { }

<NODES>{comment}"node"{comment}"["{comment}"shape"{comment}"="{comment} { BEGIN( NODE_TYPE ); }

<NODES>{comment}"rankdir"{comment}"="{comment}"\"LR\""{comment}";"{comment} { }

<NODES>[a-zA-Z0-9]+ { add_production_left(); BEGIN( PRODUCTION_MIDDLE ); }

<NODES>{comment}"}"{comment} { BEGIN( DEF_END ); }


<NODE_TYPE>{comment} { }

<NODE_TYPE>"circle" { terminal = false; BEGIN( NODE_BEFORE_NAME ); }

<NODE_TYPE>"doublecircle" { terminal = true; BEGIN( NODE_BEFORE_NAME ); }


<NODE_BEFORE_NAME>{comment} { }

<NODE_BEFORE_NAME>{comment}"]"{comment} { BEGIN( NODE_NAME ); }


<NODE_NAME>{comment} { }

<NODE_NAME>[a-zA-Z0-9]+ { add_node_name(); BEGIN( NODE_LABEL ); }


<NODE_LABEL>{comment} { }

<NODE_LABEL>{comment}"["{comment}"label"{comment}"="{comment}\"[^\"]*\"{comment}"]"{comment}";" { BEGIN( NODES ); }


<PRODUCTION_MIDDLE>{comment}

<PRODUCTION_MIDDLE>{comment}"->"{comment} { BEGIN( PRODUCTION_RIGHT ); }


<PRODUCTION_RIGHT>{comment}

<PRODUCTION_RIGHT>[a-zA-Z0-9]+ { add_production_right(); BEGIN( PRODUCTION_LABEL ); }


<PRODUCTION_LABEL>{comment}

<PRODUCTION_LABEL>{comment}"["{comment}"label"{comment}"="{comment}"\"" { BEGIN( PRODUCTION_TERMINAL ); }


<PRODUCTION_TERMINAL>[a-z] { add_production_terminal(); }

<PRODUCTION_TERMINAL>"\\\\" { add_production_terminal(); }

<PRODUCTION_TERMINAL>"|" { }

<PRODUCTION_TERMINAL>"/" { }

<PRODUCTION_TERMINAL>"\""{comment}"]"{comment}";"{comment} { BEGIN( NODES ); }


<DEF_END><<EOF>> { return 0; }

<NODES,NODE_TYPE,NODE_BEFORE_NAME,NODE_NAME,NODE_LABEL,PRODUCTION_MIDDLE,PRODUCTION_RIGHT,PRODUCTION_LABEL,PRODUCTION_TERMINAL><<EOF>> { return faerror( "unexpected end of file" ); }


. { return faerror("The input is not a digraph or valid dot file"); }

<NODES>. { return faerror("Invalid node declaration"); }

<NODE_TYPE>. { return faerror("Node type is not one of circle or doublecircle"); }

<NODE_BEFORE_NAME>. { return faerror("No idea what this is."); }

<NODE_NAME>. { return faerror("A node name must only contain alphanumeric characters."); }

<NODE_LABEL>. { return faerror("Invalid node label format."); }

<PRODUCTION_MIDDLE>. { return faerror("An edge must be defined as src -> dest"); }

<PRODUCTION_RIGHT>. { return faerror("The right side of -> must be a valid node name."); }

<PRODUCTION_LABEL>. { return faerror("An edge label must be present"); }

<PRODUCTION_TERMINAL>. { return faerror("Invalid label. It must only contain alpha characters."); }

<DEF_END>. { return faerror("Invalid character at end of definition"); }

%%


static int faerror( const char *msg ) {

    printf( "%d: error: %s\n", yylineno, msg );

//    free_grammar( grlval );

	return 1;
}


static void add_node_name( void ) {

    printf( "node: %s\n", fatext );
}


static void add_production_left( void ) {

    printf( "prod_left: %s\n", fatext );
}


static void add_production_right( void ) {

    printf( "prod_right: %s\n", fatext );
}


static void add_production_terminal( void ) {

    printf( "terminal: %c\n", fatext[0] );
}


int fawrap( void ) {

    return 1;
}


int main ( void ) {

    falex();
}

