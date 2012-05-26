#include <stdlib.h>
#include <stdio.h>
#include <string.h>
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

    grammar->terminals = calloc( 1, 0x100 );

    if ( !grammar->terminals ) {

        free_grammar( grammar );
        memory_error();
    }

    grammar->non_terminals = calloc( 1, 0x100 );

    if ( !grammar->non_terminals ) {

        free_grammar( grammar );
        memory_error();
    }

    memset( grammar->productions, '\0', sizeof( grammar->productions ) );

    return grammar;
}


void free_grammar( struct grammar* grammar ) {

    int i;

    if ( !grammar )
        return;

    if ( grammar->name )
        free( grammar->name );

    if ( grammar->terminals )
        free( grammar->terminals );

    if ( grammar->non_terminals )
        free( grammar->non_terminals );

    for ( i = 0; i < 0x100; i++ )
        if ( grammar->productions[i].rights )
            free( grammar->productions[i].rights );

    free( grammar );
}


char (*grammar_new_production( struct grammar* grammar, char left ))[2] {

    struct production *production;
    char (*rights)[2];

    if ( !grammar )
        return NULL;

    production = grammar->productions + left;

    if ( production->num_rights >= production->cap_rights ) {

        production->cap_rights *= 2;
        production->cap_rights += 1;

        rights = realloc( production->rights, production->cap_rights );

        if ( !rights ) {

            free_grammar( grammar );
            memory_error();
        }

        production->rights = rights;
    }

    return production->rights + production->num_rights;
}

