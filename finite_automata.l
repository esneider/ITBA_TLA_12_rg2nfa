%{

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

extern struct grammar *grlval;

bool terminal;

%}

whitespace     [ \t\f\v\n\r]
comment        ({whitespace}*"//"[^\n]*)*{whitespace}*

%x NODES NODE_TYPE NODE_BEFORE_NAME NODE_NAME NODE_LABEL PRODUCTION_MIDDLE
%x PRODUCTION_RIGHT PRODUCTION_LABEL PRODUCTION_TERMINAL DEF_END

%optino yylineno
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


<PRODUCTION_TERMINAL>[a-z]"\""{comment}"]"{comment}";"{comment} { add_production_terminal(); BEGIN( NODES ); }


<DEF_END><<EOF>> {}

<NODES,NODE_TYPE,NODE_BEFORE_NAME,NODE_NAME,NODE_LABEL,PRODUCTION_MIDDLE,PRODUCTION_RIGHT,PRODUCTION_LABEL,PRODUCTION_TERMINAL><<EOF>> { return faerror( "unexpected end of file" ); }


. {}


%%


static int faerror( const char *msg ) {

    printf( "%d: error: %s\n", yylineno, msg );

//    free_grammar( grlval );

	return 1;
}



