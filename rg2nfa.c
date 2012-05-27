#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "rg2nfa.h"


void memory_error( void ) {

    printf( "Aborting due to memory error\n" );
    exit(1);
}


struct grammar* new_grammar( void ) {

    struct grammar *grammar = calloc( 1, sizeof( struct grammar ) );

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

    if ( !grammar )
        return;

    if ( grammar->name )
        free( grammar->name );

    if ( grammar->terminals )
        free( grammar->terminals );

    if ( grammar->non_terminals )
        free( grammar->non_terminals );

    for ( int i = 0; i < 0x100; i++ )
        if ( grammar->productions[i].rights )
            free( grammar->productions[i].rights );

    free( grammar );
}


char (*grammar_new_production( struct grammar* grammar, char left ))[2] {

    if ( !grammar )
        return NULL;

    struct production *production = grammar->productions + left;

    if ( production->num_rights >= production->cap_rights ) {

        production->cap_rights *= 2;
        production->cap_rights += 1;

        char (*rights)[2] = realloc( production->rights, production->cap_rights );

        if ( !rights ) {

            free_grammar( grammar );
            memory_error();
        }

        production->rights = rights;
    }

    return production->rights + production->num_rights;
}


void normalize_grammar( struct grammar* grammar ) {

    if ( !grammar->empty )

        for ( int i = 'A'; i <= 'Z'; i++ )

            if ( !grammar->productions[i].num_rights ) {

                grammar->empty = i;

                (*grammar_new_production( grammar, i ))[0] = '\\';

                break;
            }

    if ( !grammar->empty ) {

        printf( "Aborting since *all* upcase letters are used for non empty rules\n" );
        exit(1);
    }

    for ( int i = 0; i < 0x100; i++ ) {

        struct production *production = grammar->productions + i;

        for ( int j = 0; j < production->num_rights; j++ ) {

            if ( !production->rigths[j][1] ) {

                if ( production->rights[j][0] >= 'a' ) {

                    if ( grammar->type == RIGHT_REGULAR_GRAMMAR ) {

                        production->rights[j][1] = grammar->empty;

                    } else {

                        production->rights[j][1] = production->rights[j][0];
                        production->rights[j][0] = grammar->empty;
                    }

                } else
                if ( production->rights[j][0] <= 'Z' ) {

                    struct production *replace = grammar->productions + productions->rights[j][0];

                    for ( int k = 0; k < replace->num_rights; k++ ) {

                        bool repeated = false;

                        for ( int l = 0; l < production->num_rights; l++ )

                            if ( !memcmp( replace->rights[k], production->rights[l], 2 ) ) {

                                repeated = true;
                                break;
                            }

                        if ( !repeated ) {

                            memcpy( grammar_new_production( grammar, i ), replace->rights[k], 2 );
                        }
                    }
                }
            }
        }

        int num_rights = 0;

        for ( int j = 0; j < production->num_rights; j++ )

            if ( production->rigths[j][1] )

                memcpy( production->rights[ num_rights++ ], production->rights[j], 2 );

        production->num_rights = num_rights;
    }
}

