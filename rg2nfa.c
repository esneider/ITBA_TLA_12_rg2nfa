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

        char (*rights)[2] = realloc( production->rights, production->cap_rights * 2 );

        if ( !rights ) {

            free_grammar( grammar );
            memory_error();
        }

        memset( rights + production->num_rights, '\0', (production->cap_rights - production->num_rights) * 2 );

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


void normalize_grammar( struct grammar *grammar ) {

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

    /* name */

    right->name = malloc( strlen( left->name ) + 1 );

    if ( !right->name )
        memory_error();

    strcpy( right->name, left->name );

    /* type */
    right->type = RIGHT_REGULAR_GRAMMAR;

    normalize_grammar( left );

    /* initial */

    for ( int i = 'A'; i <= 'Z'; i++ )

        if ( !left->productions[i].num_rights ) {

            right->initial = i;
            break;
        }

    if ( !right->initial ) {

        printf( "Aborting due to lack of upcase letters\n" );
        exit(1);
    }

    /* empty */

    right->empty = left->initial;
    (*grammar_new_production( right, right->empty ))[0] = '\\';

    /* terminals */

    right->num_terminals = left->num_terminals;
    strcpy( right->terminals, left->terminals );

    /* non-terminals */

    right->num_non_terminals = left->num_non_terminals;
    strcpy( right->non_terminals, left->non_terminals );
    right->non_terminals[ right->num_non_terminals++ ] = right->initial;

    /* productions */

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


void print_grammar( FILE* file, struct grammar *grammar ) {

    fprintf( file, "%s = (\n", grammar->name );

    fprintf( file, "\t{" );
    for ( char *nt = grammar->non_terminals; *nt; nt++ )
        fprintf( file, " %c,", *nt );
    fprintf( file, " }\n" );

    fprintf( file, "\t{" );
    for ( char *nt = grammar->terminals; *nt; nt++ )
        fprintf( file, " %c,", *nt );
    fprintf( file, " }\n" );

    fprintf( file, "\t%c,\n", grammar->initial );

    fprintf( file, "\t{\n" );

    for ( int i = 0; i < 0x100; i++ ) {

        struct production *production = grammar->productions + i;

        for ( int j = 0; j < production->num_rights; j++ )

            fprintf( file, "\t\t%c->%.2s\n", i, production->rights[j] );
    }

    fprintf( file, "\t}\n)\n" );
}


static void walk_grammar( struct grammar *grammar, int letter, bool *visited ) {

    if ( !letter || visited[ letter ] )
        return;

    visited[ letter ] = true;

    for ( int i = 0; i < grammar->productions[ letter ].num_rights; i++ )

        walk_grammar( grammar, grammar->productions[ letter ].rights[i][1], visited );
}


struct grammar* clean_grammar( struct grammar *grammar ) {

    struct grammar *new = new_grammar();

    /* name */

    new->name = malloc( strlen( grammar->name ) + 1 );

    if ( !new->name )
        memory_error();

    strcpy( new->name, grammar->name );

    /* type */

    bool left = false;

    if ( grammar->type == LEFT_REGULAR_GRAMMAR ) {

        left = true;
        grammar = left_to_right_grammar( grammar );
    }

    normalize_grammar( grammar );

    new->type = RIGHT_REGULAR_GRAMMAR;

    /* terminals */

    new->num_terminals = grammar->num_terminals;
    strcpy( new->terminals, grammar->terminals );

    /* initial */

    new->initial = grammar->initial;

    /* productions */

    bool visited_down[ 0x100 ] = {1, 0};

    walk_grammar( grammar, grammar->initial, visited_down );


    bool visited_up[ 0x100 ] = {1, 0};

    char empty[ 0x100 ] = {0};
    int num_empty = 0;

    struct grammar *reversed = new_grammar();

    for ( int i = 0; i < 0x100; i++ ) {

        struct production *production = grammar->productions + i;

        for ( int j = 0; j < production->num_rights; j++ ) {

            if ( production->rights[j][1] ) {

                (*grammar_new_production( reversed, production->rights[j][1] ))[1] = i;

            } else {

                empty[ num_empty++ ] = i;
            }
        }
    }

    for ( int i = 0; i < num_empty; i++ )
        walk_grammar( reversed, empty[i], visited_up );

    for ( int i = 0; i < 0x100; i++ )
        visited_up[i] &= visited_down[i];

    for ( int i = 0; i < 0x100; i++ ) {

        if ( visited_up[i] ) {

            struct production* production = grammar->productions + i;

            for ( int j = 0; j < production->num_rights; j++ ) {

                if ( visited_up[ (int)production->rights[j][1] ] ) {

                    memcpy( grammar_new_production( new, i ), production->rights[j], 2 );

                    if ( !production->rights[j][1] )

                        new->empty = i;
                }
            }
        }
    }

    free_grammar( reversed );

    /* non-terminals */

    new->num_non_terminals = 0;

    for ( int i = 0; i < 0x100; i++ )

        if ( new->productions[i].num_rights )

            new->non_terminals[ new->num_non_terminals++ ] = i;

    /* clean after */

    if ( left )
        free_grammar( grammar );

    normalize_grammar( new );

    return new;
}


static void print_automata( FILE *file, struct grammar *grammar ) {

    fprintf( file, "digraph {\nrankdir = \"LR\";\n" );

    char positions[0x100] = {0};

    positions[ (int)grammar->initial ] = 1;

    for ( int i = 0, pos = 2; i < 0x100; i++ ) {

        struct production *production = grammar->productions + i;

        if ( !production->num_rights )
            continue;

        bool final = false;

        for ( int j = 0; j < production->num_rights; j++ ) {

            if ( production->rights[j][0] == '\\' ) {

                final = true;
                break;
            }
        }

        if ( !positions[i] )
            positions[i] = pos++;

        fprintf( file, "node [shape=%scircle] Node%d [label=\"%d\"];\n", final ? "double" : "", positions[i], positions[i] );
    }

    for ( int i = 'A'; i <= 'Z'; i++ ) {

        struct production *production = grammar->productions + i;

        for ( int j = 'A'; j <= 'Z'; j++ ) {

            bool first = true;

            for ( int p = 0; p < production->num_rights; p++ ) {

                if ( (int)production->rights[p][1] == j ) {

                    if ( first ) {

                        first = false;
                        fprintf( file, "Node%d -> Node%d [label=\"%c", positions[i], positions[j], production->rights[p][0] );

                    } else {

                        fprintf( file, "/%c", production->rights[p][0] );
                    }
                }
            }

            if ( !first )

                fprintf( file, "\"];\n" );
        }
    }

    fprintf( file, "}\n" );
}


struct grammar *grlval;
struct grammar *falval;


int grlex( void );
int falex( void );

void* gr_create_buffer( FILE *file, int size );
void  gr_switch_to_buffer( void* new_buffer );

void* fa_create_buffer( FILE *file, int size );
void  fa_switch_to_buffer( void* new_buffer );

#define YY_BUF_SIZE 16384


int main ( int argc, char **argv ) {

    if ( argc < 2 || argc > 3 ) {

        printf( "Usage:\n\trg2nfa input_file [output_file]\n" );
        return 1;
    }

    FILE* file = fopen( argv[1], "r" );

    if ( !file ) {

        printf( "Error opening file\n" );
        return 1;
    }

    switch ( argv[1][ strlen( argv[1] ) - 1 ] ) {

        case 'r':

            gr_switch_to_buffer( gr_create_buffer( file, YY_BUF_SIZE ) );

            if ( !grlex() ) {

                struct grammar *temp = clean_grammar( grlval );

                free_grammar( grlval );

                grlval = temp;

                FILE *output = fopen( "temp", "w" );

                if ( !output ) {

                    printf( "Error writing output file\n" );

                } else {

                    print_automata( output, grlval );

                    fclose( output );

                    if ( argc < 3 ) {

                        if ( system( "dot temp -Tpng -o out.png; rm temp" ) )

                            printf( "Error writing output file\n" );

                    } else {

                        char *s = malloc ( 50 + strlen( argv[2] ) );

                        if ( !s )
                            memory_error();

                        sprintf( s, "dot temp -Tpng -o %s; rm temp", argv[2] );

                        if ( system(s) )

                            printf( "Error writing output file\n" );
                    }
                }

                free_grammar( grlval );
            }

            break;

        case 't':

            fa_switch_to_buffer( fa_create_buffer( file, YY_BUF_SIZE ) );

            if ( !falex() ) {

                FILE *output;

                if ( argc > 2 )
                    output = fopen( argv[2], "w" );
                else
                    output = fopen( "out.rg", "w" );

                if ( !output ) {

                    printf( "Error writing output file\n" );

                } else {

                    print_grammar( output, falval );

                    fclose( output );
                }

                free_grammar( falval );
            }
            break;

        default:

            printf( "The input file should have one of the following extensions: dot, gr\n" );

            fclose( file );

            return 1;
    }

    fclose( file );

    return 0;
}

