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


void free_grammar( struct grammar *grammar ) {

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


char (*grammar_new_production( struct grammar *grammar, char left ))[2] {

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

    return production->rights + production->num_rights++;
}


static void add_production( struct grammar *grammar, int left, char right[2] ) {

    struct production *production = grammar->productions + left;

    for ( int i = 0; i < production->num_rights; i++ )

        if ( !memcmp( right, production->rights[i], 2 ) )
            return;

    memcpy( grammar_new_production( grammar, left ), right, 2 );
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

        printf( "Aborting due to lack of upcase letters\n" );
        exit(1);
    }

    for ( int i = 0; i < 0x100; i++ ) {

        struct production *production = grammar->productions + i;

        for ( int j = 0; j < production->num_rights; j++ ) {

            if ( !production->rights[j][1] ) {

                if ( production->rights[j][0] >= 'a' ) {

                    char replace[2];

                    if ( grammar->type == RIGHT_REGULAR_GRAMMAR ) {

                        replace[0] = production->rights[j][0];
                        replace[1] = grammar->empty;

                    } else {

                        replace[0] = grammar->empty;
                        replace[1] = production->rights[j][0];
                    }

                    add_production( grammar, i, replace );

                } else
                if ( production->rights[j][0] <= 'Z' ) {

                    struct production *replace = grammar->productions + production->rights[j][0];

                    for ( int k = 0; k < replace->num_rights; k++ )

                        add_production( grammar, i, replace->rights[k] );
                }
            }
        }

        int num_rights = 0;

        for ( int j = 0; j < production->num_rights; j++ )

            if ( production->rights[j][1] || production->rights[j][0] == '\\' )

                memcpy( production->rights[ num_rights++ ], production->rights[j], 2 );

        production->num_rights = num_rights;
    }

    grammar->num_non_terminals = 0;

    for ( int i = 0; i < 0x100; i++ )

        if ( grammar->productions[i].num_rights )

            grammar->non_terminals[ grammar->num_non_terminals++ ] = i;
}


struct grammar* left_to_right_grammar( struct grammar *left ) {

    if ( !left || left->type == RIGHT_REGULAR_GRAMMAR )
        return left;

    struct grammar *right = new_grammar();

    right->name = malloc( strlen( left->name ) + 1 );

    if ( !right->name )
        memory_error();

    strcpy( right->name, left->name );

    right->type = RIGHT_REGULAR_GRAMMAR;

    normalize_grammar( left );

    for ( int i = 'A'; i <= 'Z'; i++ )

        if ( !left->productions[i].num_rights ) {

            right->initial = i;
            break;
        }

    if ( !right->initial ) {

        printf( "Aborting due to lack of upcase letters\n" );
        exit(1);
    }

    right->empty = left->initial;
    (*grammar_new_production( right, right->empty ))[0] = '\\';

    right->num_terminals = left->num_terminals;
    strcpy( right->terminals, left->terminals );

    right->num_non_terminals = left->num_non_terminals;
    strcpy( right->non_terminals, left->non_terminals );
    right->non_terminals[ right->num_non_terminals++ ] = right->initial;

    for ( int i = 0; i < 0x100; i++ ) {

        struct production* production = left->productions + i;

        for ( int j = 0; j < production->num_rights; j++ ) {

            if ( production->rights[j][1] ) {

                char (*reverse)[2] = grammar_new_production( right, production->rights[j][0] );

                (*reverse)[0] = production->rights[j][1];
                (*reverse)[1] = i;

            } else {

                (*grammar_new_production( right, right->initial ))[0] = i;
            }
        }
    }

    return right;
}


void print_grammar( struct grammar *grammar ) {

    printf( "%s = (\n", grammar->name );

    printf( "\t{" );
    for ( char *nt = grammar->non_terminals; *nt; nt++ )
        printf( " %c,", *nt );
    printf( " }\n" );

    printf( "\t{" );
    for ( char *nt = grammar->terminals; *nt; nt++ )
        printf( " %c,", *nt );
    printf( " }\n" );

    printf( "\t%c,\n", grammar->initial );

    printf( "\t{\n" );

    for ( int i = 0; i < 0x100; i++ ) {

        struct production *production = grammar->productions + i;

        for ( int j = 0; j < production->num_rights; j++ )

            printf( "\t\t%c->%.2s\n", i, production->rights[j] );
    }

    printf( "\t}\n)\n" );
}

