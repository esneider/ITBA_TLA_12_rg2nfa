%{

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "rg2nfa.h"

extern struct grammar *falval;

static bool ok = false;
static bool terminal;
static char last_left_production;
static char last_right_production;
static char last_left_production_pos;
static char last_right_production_pos;
static char next_non_terminal = 'A';
static struct { char *name; char symbol; bool terminal; char *state; } name_map[0x100];
static int map_size = 0;
static struct grammar *temp;

static int faerror( const char *msg );
static void add_node_name( void );
static void add_state_name( void );
static void add_production_left( void );
static void add_production_right( void );
static void add_production_terminal( void );

%}

whitespace     [ \t\f\v\n\r]
comment        ({whitespace}*"//"[^\n]*)*{whitespace}*

%x NODES NODE_TYPE NODE_BEFORE_NAME NODE_NAME NODE_LABEL PRODUCTION_MIDDLE
%x PRODUCTION_RIGHT PRODUCTION_LABEL PRODUCTION_TERMINAL DEF_END STATE_NAME
%x NODE_LABEL_END

%option yylineno
%option nounput

%%

{comment} { }

{comment}*"digraph"{comment}"{" { falval = new_grammar(); temp = new_grammar(); BEGIN( NODES ); }


<NODES>{comment} { }

<NODES>{comment}"node"{comment}"["{comment}"shape"{comment}"="{comment} { BEGIN( NODE_TYPE ); }

<NODES>{comment}"rankdir"{comment}"="{comment}"\"LR\""{comment}";"{comment} { }

<NODES>[a-zA-Z0-9]+ { add_production_left(); BEGIN( PRODUCTION_MIDDLE ); }

<NODES>{comment}"}"{comment} { ok = true; BEGIN( DEF_END ); }


<NODE_TYPE>{comment} { }

<NODE_TYPE>"circle" { terminal = false; BEGIN( NODE_BEFORE_NAME ); }

<NODE_TYPE>"doublecircle" { terminal = true; BEGIN( NODE_BEFORE_NAME ); }


<NODE_BEFORE_NAME>{comment} { }

<NODE_BEFORE_NAME>{comment}"]"{comment} { BEGIN( NODE_NAME ); }


<NODE_NAME>{comment} { }

<NODE_NAME>[a-zA-Z0-9]+ { add_node_name(); BEGIN( NODE_LABEL ); }


<NODE_LABEL>{comment} { }

<NODE_LABEL>{comment}"["{comment}"label"{comment}"="{comment}"\"" { BEGIN( STATE_NAME ); }


<STATE_NAME>[^\"]* { add_state_name(); BEGIN( NODE_LABEL_END ); }


<NODE_LABEL_END>"\""{comment}"]"{comment}";" { BEGIN( NODES ); }


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

<NODES,NODE_TYPE,NODE_BEFORE_NAME,NODE_NAME,NODE_LABEL,PRODUCTION_MIDDLE,PRODUCTION_RIGHT,PRODUCTION_LABEL,PRODUCTION_TERMINAL,STATE_NAME,NODE_LABEL_END><<EOF>> { return faerror( "unexpected end of file" ); }


. { falval = temp = NULL; return faerror("The input is not a digraph or valid dot file"); }

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

<STATE_NAME>. { return faerror("Invalid character at label name"); }

<NODE_LABEL_END>. { return faerror("Invalid node declaration"); }

%%


static int faerror( const char *msg ) {

    printf( "%d: error: %s\n", yylineno, msg );

    free_grammar( falval );
    free_grammar( temp );

	return 1;
}


static void add_node_name( void ) {

    if ( next_non_terminal > 'Z' ) {

        printf( "Aborting due to lack of upcase letters\n" );
        exit(1);
    }

    name_map[ map_size ].terminal = terminal;
    name_map[ map_size ].symbol = next_non_terminal++;
    name_map[ map_size ].name = malloc( faleng + 1 );

    if ( !name_map[ map_size ].name )
        memory_error();

    strcpy( name_map[ map_size ].name, fatext );

    map_size++;
}


static void add_state_name( void ) {

    name_map[ map_size - 1 ].state = malloc( faleng + 1 );
    strcpy( name_map[ map_size - 1 ].state, fatext );
}


static void add_production_left( void ) {

    last_left_production = 0;

    for ( int i = 0; i < map_size; i++ ) {

        if ( !strcmp( fatext, name_map[i].name ) ) {

            last_left_production = name_map[i].symbol;
            last_left_production_pos = i;
            break;
        }
    }

    if ( !last_left_production ) {

        faerror( "Invalid node name" );
        exit(1);
    }
}


static void add_production_right( void ) {

    last_right_production = 0;

    for ( int i = 0; i < map_size; i++ ) {

        if ( !strcmp( fatext, name_map[i].name ) ) {

            last_right_production = name_map[i].symbol;
            last_right_production_pos = i;
            break;
        }
    }

    if ( !last_right_production ) {

        faerror( "Invalid node name" );
        exit(1);
    }
}


static void add_production_terminal( void ) {

    char (*production)[2] = grammar_new_production( falval, last_left_production );
    char (*temp_production)[2] = grammar_new_production( temp, last_left_production_pos );

    (*temp_production)[0] = fatext[0];
    (*temp_production)[1] = last_right_production_pos;

    if ( fatext[0] == '\\' ) {

        (*production)[0] = last_right_production;

    } else {

        (*production)[0] = fatext[0];
        (*production)[1] = last_right_production;
    }
}


int fawrap( void ) {

    if ( ok ) {

        for ( int i = 0; i < map_size; i++ )

            if ( name_map[i].terminal )

                (*grammar_new_production( falval, name_map[i].symbol ))[0] = '\\';

        falval->name = malloc(10);

        if ( !falval->name )
            memory_error();

        strcpy( falval->name, "no_name" );

        falval->num_non_terminals = 0;
        falval->num_terminals = 0;
        falval->initial = name_map[0].symbol;
        bool terminals[0x100] = {0};

        for ( int i = 0; i < 0x100; i++ ) {

            struct production* production = falval->productions + i;

            if ( production->num_rights )

                falval->non_terminals[ falval->num_non_terminals++ ] = i;

            for ( int j = 0; j < production->num_rights; j++ )

                terminals[ (int)production->rights[j][0] ] = true;
        }

        for ( int i = 'a'; i <= 'z'; i++ )

            if ( terminals[i] )

                falval->terminals[ falval->num_terminals++ ] = i;

        /* print info */

        for ( int i = 0; i < falval->num_terminals; i++ )

            printf( "terminal symbol: %c\n", falval->terminals[i] );

        for ( int i = 0; i < map_size; i++ )

            printf( "state: %s\n", name_map[i].state );

        printf( "initial state: %s\n", name_map[0].state );

        for ( int i = 0; i < map_size; i++ )

            if ( name_map[i].terminal )

                printf( "final state: %s\n", name_map[i].state );

        for ( int i = 0; i < 0x100; i++ ) {

            struct production* production = temp->productions + i;

            for ( int j = 0; j < production->num_rights; j++ ) {

                printf( "delta( %s, %c ) = %s\n", name_map[i].state, production->rights[j][0], name_map[ (int)production->rights[j][1] ].state );
            }
        }

        free_grammar( temp );
    }
    return 1;
}

