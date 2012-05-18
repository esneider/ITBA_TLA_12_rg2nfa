#include <stdlib.h>
#include <stdio.h>
#include "rg2nfa.h"


void memory_error( void ) {

    printf( "Aborting due to memory error\n" );
    exit(1);
}


struct grammar* new_grammar( void ) {

    struct grammar *grammar;

    grammar = calloc( 1, sizeof( struct grammar ) );

    if ( !grammar ) {

        memory_error();
    }

    grammar->terminals = calloc( 1, 256 );

    if ( !grammar->terminals ) {

        free_grammar( grammar );
        memory_error();
    }

    grammar->non_terminals = calloc( 1, 256 );

    if ( !grammar->non_terminals ) {

        free_grammar( grammar );
        memory_error();
    }

    return grammar;
}


void free_grammar( struct grammar* grammar ) {

    if ( !grammar )
        return;

    if ( grammar->name )
        free( grammar->name );

    if ( grammar->terminals )
        free( grammar->terminals );

    if ( grammar->non_terminals )
        free( grammar->non_terminals );

    if ( grammar->productions ) {

        while ( grammar->num_productions ) {

            free( grammar->productions[ --grammar->num_productions ].right );
        }

        free( grammar->productions );
    }

    free( grammar );
}


struct production* grammar_new_production( struct grammar* grammar ) {

    struct production* productions;

    if ( !grammar )
        return NULL;

    if ( grammar->num_productions >= grammar->productions_capacity ) {

        grammar->productions_capacity *= 2;
        grammar->productions_capacity += 1;

        productions = realloc( grammar->productions, grammar->productions_capacity );

        if ( !productions ) {

            free_grammar( grammar );
            memory_error();
        }

        grammar->productions = productions;
    }

    return grammar->productions + grammar->num_productions++;
}

