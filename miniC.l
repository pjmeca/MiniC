/* Analizador léxico de calculadora */

/* NOTAS:
    - Dentro del [] el asterisco pierde su función especial.
    - Al poner la expresión regular, FLEX se desentiende, por lo que hay que poner manualmente el return 0.

*/

%{
    /* Código C verbatim */
    // Lo que escribo aquí, Flex no lo analiza, lo pone al principio del
    // .C final
    #include "miniC.tab.h"
    #include <stdio.h>
    #include <stdlib.h>
    #include "listaMemoria.h"
    int inicio_comentario;
    int nerrores;
%}

/* Macros de expresiones regulares */
D           [0-9]
L           [a-zA-Z_]
ID          {L}(({L}|{D})?){15}
NOTID       {L}({L}|{D})*

/* Opciones de flex */

/* Vamos a cambiar yylineno para que calcule la línea en la que se encuentra cada error (de forma
predeterminada no lo hace para ahorrar recursos. */
%option yylineno    
/* Para hacer debug poner %option debug */
/* Si estuviese en Fedora hay que poner también %%option yynowrath*/


/* Condición de contexto para comentarios multilínea */
%x comentario

/* Reglas de blancos y comentarios */
%%

[ \n\t\r]+              ;
"//".*                  ;
"/*"                    { BEGIN(comentario); inicio_comentario = yylineno; }
<comentario>(.|\n)      ;
<comentario>"*/"        { BEGIN(0); } /* Vuelve al autómata inicial, también se puede poner INITIAL */
<comentario><<EOF>>     { printf("Error léxico: comentario sin cerrar desde la línea: %d\n", inicio_comentario); nerrores++; return 0; }
"#define "{ID}" "{D}+   ;

 /* Reglas de tokens/expresiones regulares (aquí hay que poner un espacio antes de los comentarios */
"print"             { return(PRINT); }
"void"              { return(VOID); }
"var"               { return(VAR);  }
"const"             { return(CONST);}
"if"                { return(IF);   }
"else"              { return(ELSE); }
"while"             { return(WHILE);}
"read"              { return(READ); }
{ID}                { yylval.cadena = strdup(yytext); return(ID); }
{NOTID}             { printf("Error léxico en la linea %d: longitud del identificador <%s> excedida\n", yylineno, yytext); nerrores++; return(ID); }
{D}+                { yylval.cadena = strdup(yytext); if(atol(yytext) > 2146500608){printf("Error léxico en la linea %d: tamaño de número \"%s\" excedido\n", yylineno, yytext); nerrores++;} else return(NUM);  }
"+"                 { return(MAS); }
"*"                 { return(POR); } 
"/"                 { return(DIV); }
"-"                 { return(MENOS); }
"="                 { return(IGUAL); }
";"                 { return(PYC); }
"{"                 { return(LLAVI); }
"}"                 { return(LLAVD); }
"("                 { return(PARI); }
")"                 { return(PARD); }
","                 { return(COMA); }
\"([^\"\n]|\\\")*\" { yylval.cadena = strdup(yytext); return(STRING); }
\"([^\"\n]|\\\")*   { printf("Error léxico en la línea %d: cadena sin cerrar\n", yylineno); nerrores++;}

 /* Tratamiento de errores */
[^ \n\r\ta-zA-Z_0-9+*/\-=;(){},"]+  { printf("Error léxico en la linea %d: %s\n", yylineno, yytext); nerrores++;}

%%