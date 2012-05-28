#ifndef __RG2NFA_H__
#define __RG2NFA_H__


struct grammar {

    char *name;

    enum {

        LEFT_REGULAR_GRAMMAR = 1,
        RIGHT_REGULAR_GRAMMAR = 2,
        NON_REGULAR_GRAMMAR = 3,

    } type;

    int num_terminals;
    int num_non_terminals;
    int num_productions;

    char *terminals;
    char *non_terminals;
    char initial;
    char empty;

    struct production {

        char (*rights)[2];
        int num_rights;
        int cap_rights;

    } productions[ 0x100 ];

};


void memory_error( void );

struct grammar* new_grammar( void );

void free_grammar( struct grammar *grammar );

char (*grammar_new_production( struct grammar *grammar, char left ))[2];

void normalize_grammar( struct grammar *grammar );

struct grammar* left_to_right_grammar( struct grammar *left );

void print_grammar( FILE *file, struct grammar *grammar );

struct grammar* clean_grammar( struct grammar *grammar );


#endif /* __RG2NFA_H__ */

