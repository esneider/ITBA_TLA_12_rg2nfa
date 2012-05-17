%{

void set_grammar_name( void );
void add_non_terminal( void );
void add_terminal( void );
void add_initial_symbol( void );
void add_production_left( void );
void add_production_right( void );

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
%x PRODUCTIONS_RIGHT PRODUCTIONS_RIGHT_COMMA

%%

{whitespace} { }

{grammar_name} { set_grammar_name(); BEGIN( DEF_BEGIN ); }

<DEF_BEGIN>{def_begin} { BEGIN( NON_TERMINALS ); }


<NON_TERMINALS,NON_TERMINALS_COMMA>{whitespace} { }

<NON_TERMINALS>{non_terminals}+ { add_non_terminal(); BEGIN( NON_TERMINALS_COMMA ); }

<NON_TERMINALS_COMMA>"," { BEGIN( NON_TERMINALS ); }

<NON_TERMINALS,NON_TERMINALS_COMMA>{def_delimiter} { BEGIN( TERMINALS ); }


<TERMINALS,TERMINALS_COMMA>{whitespace} { }

<TERMINALS>{terminals}+ { add_terminal(); BEGIN( TERMINALS_COMMA ); }

<TERMINALS_COMMA>"," { BEGIN( TERMINALS ); }

<TERMINALS,TERMINALS_COMMA>{def_delimiter_initial_sym_begin} { BEGIN( INITIAL_SYM ); }


<INITIAL_SYM,INITIAL_SYM_END>{whitespace} { }

<INITIAL_SYM>{non_terminals}+ { add_initial_symbol(); BEGIN( INITIAL_SYM_END ); }

<INITIAL_SYM_END>{def_delimiter_initial_sym_end} { BEGIN( PRODUCTIONS_LEFT ); }


<PRODUCTIONS_LEFT,PRODUCTIONS_ARROW,PRODUCTIONS_RIGHT,PRODUCTIONS_RIGHT_COMMA>{whitespace} { }

<PRODUCTIONS_LEFT>{non_terminals} { add_production_left(); BEGIN( PRODUCTIONS_ARROW ); }

<PRODUCTIONS_ARROW>"->" { BEGIN( PRODUCTIONS_RIGHT ); }

<PRODUCTIONS_RIGHT>{productions} { add_production_right(); BEGIN( PRODUCTIONS_RIGHT_COMMA ); }

<PRODUCTIONS_RIGHT>"\\" { add_production_right(); BEGIN( PRODUCTIONS_RIGHT_COMMA ); }

<PRODUCTIONS_RIGHT_COMMA>"|" { BEGIN( PRODUCTIONS_RIGHT ); }

<PRODUCTIONS_RIGHT_COMMA>"," { BEGIN( PRODUCTIONS_LEFT ); }

<PRODUCTIONS_RIGHT_COMMA,PRODUCTIONS_LEFT>{def_end} { }

%%

void set_grammar_name( void ) {

    printf( "grammar name: '%s'\n", yytext );
}

void add_non_terminal( void ) {

    printf( "non-terminal: '%s'\n", yytext );
}

void add_terminal( void ) {

    printf( "terminal: '%s'\n", yytext );
}

void add_initial_symbol( void ) {

    printf( "initial symbol: '%s'\n", yytext );
}

void add_production_left( void ) {

    printf( "\n%s ->\n", yytext );
}

void add_production_right( void ) {

    printf( "\t%s\n", yytext );
}

int main( void ) {

    yylex();
    return 0;
}
