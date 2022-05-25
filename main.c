#include <stdio.h>
#include <stdlib.h>

extern int yyleng, yylex(), nerrores, yylex_destroy();
extern char *yytext;
extern FILE *yyin;
extern int yyparse();

extern int errores_sintacticos, errores_semanticos, hayErrores;

int main(int argc, char* argv[]) {

    /* Abrir archivo pasado por argumentos */
    if(argc != 2){
        printf("Uso: %s fichero\n", argv[0]);
        exit(1);
    }

    // Lo abrimos y se lo pasamos a Flex
    FILE* archivo = fopen(argv[1], "r");
    yyin = archivo;

    // Si es nulo
    if (yyin == NULL){
        printf("No se puede abrir %s\n", argv[1]);
        exit(2);
    }

    /*------------------------------------------------*/

    int token;

    yyparse();
    yylex_destroy(); //para eliminar restos de memoria dinámica de yyparse()

    if(hayErrores){
        //Hay errores
        printf("----------------------\nErrores léxicos totales: %d\n", nerrores);
        printf("Errores sintácticos totales: %d\n", errores_sintacticos);
        printf("Errores semánticos totales: %d\n", errores_semanticos);
    }

    if(archivo != NULL)
        fclose(archivo);
}