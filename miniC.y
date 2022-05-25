%{
	#include <stdio.h>
    #include <stdlib.h>
	#include <string.h>
	#include "listaSimbolos.h"
	#include "listaCodigo.h"
	#include "listaMemoria.h"

	// Métodos y variables de Flex
	extern int yylex();
	extern int yylineno;
	extern int nerrores; // errores lexicos

	// Función para mensajes de error
	void yyerror(const char* msg);

	// Valores de registros
	int r[10];
	void inicializar_regs();
	char* obtenerReg();
	void liberarReg();
	char* concatenar(char* a, char* b);
	char* concatenar_entero(char* a, int b);
	char* nuevaEtiqueta();

	// Número de errores sintácticos
	int errores_sintacticos = 0;
	// Número de errores semánticos
	int errores_semanticos = 0;

	//Analizador semántico
	Lista tS; //tabla de símbolos
	//ListaM memoriaDinamica; //tabla con todos los elementos dinámicos
	Tipo tipo;
	int hayErrores; //comprueba si hay errores para imprimir o no la salida
	int contString = 1; //contador de $str

	//Etiquetas de salto
	int contador_etiq = 1;

	ListaM memoriaDinamica;
%}

%code requires{
	#include "listaCodigo.h"
}

/* Tipos de dato de tokens y no terminales */
%union{
	char* cadena;
	ListaC codigo;
}

%type <codigo> expression declarations identifier_list asig statement statement_list print_item print_list read_list;

%token MAS "+"
%token MENOS "-"
%token POR "*"
%token DIV "/"
%token PARI "("
%token PARD ")"
%token LLAVI "{"
%token LLAVD "}"
%token <cadena> NUM "number"
%token COMA ","
%token PYC ";"
%token IGUAL "="
%token VOID "void"
%token VAR "var"
%token CONST "const"
%token IF "if"
%token ELSE "else"
%token WHILE "while"
%token PRINT "print"
%token READ "read"
%token <cadena> STRING "string"
%token <cadena> ID "id"

/* Precedencia y asociatividad de operadores
%left - izquierda
%right - derecha
%nonassoc - el operador no tiene asociatividad (marcaría error sintáctico en caso de ambiguedad) 
Los operadores con misma precedencia deben situarse en la misma línea.
Conforme se pasa a nueva línea, se indica más precedencia.*/
%left "+" "-" 
%left  "*" "/"
%precedence UMENOS // Para poder cambiar la precedencia de un caso del tipo -2*3, para que sea (-2)*3

%define parse.error verbose

%%
 /* Reglas de producción */

program			: VOID ID "(" ")" "{"{ tS = creaLS(); memoriaDinamica = creaLM(); inicializar_regs();} declarations statement_list "}" 	{ 	//printf("P->void id() {D SL}\n"); 
																							// Volcar lista de símbolos a salida para generar .data
																								insertaLM(memoriaDinamica, $2);
																								if(!nerrores && !errores_sintacticos && !errores_semanticos){
																									hayErrores = 0;
																									
																									imprimeLS(tS);

																									//Main
																									printf("\t.text\n\t.globl main\nmain:\n");
																									concatenaLC($7, $8);
																									imprimeLC($7);
																									
																									printf("\n# END ##############\n");
																									printf("\tli\t$v0, 10\n\tsyscall\n"); //exit (jr $ra falla en Mars)

																									liberaLS(tS);
																									liberaLC($7);
																									liberaLC($8);
																									liberaLM(memoriaDinamica);

																								}else
																									hayErrores = 1;
																							}
				;

declarations	: declarations VAR { tipo = VARIABLE; } identifier_list ";"					{ /*printf("D->D var IDL ;\n"); */
																								$$=$1;
																								concatenaLC($$, $4);
																								liberaLC($4);
																							}
				| declarations CONST { tipo = CONSTANTE; } identifier_list ";"			  	{ /*printf("D->D const IDL ;\n"); */
																								$$=$1;
																								concatenaLC($$, $4);
																								liberaLC($4);
																							}
				| %empty																	{ /*printf("D->lambda\n"); */
																								$$=creaLC();
																							}
				;

identifier_list : asig													{ /*printf("IDL->AS\n"); */
																			$$=$1;
																		}
				| identifier_list "," asig								{ /*printf("IDL->IDL , AS\n"); */
																			$$=$1;
																			concatenaLC($$, $3);
																			liberaLC($3);
																		}
				| %empty												{ /*printf("IDL->lambda\n"); */
																			$$=creaLC();
																		}
				;

asig			: ID													{ /* Insertar identificador $1 con tipo */
																			insertaLM(memoriaDinamica, $1);
																			PosicionLista pos = buscaLS(tS,$1);

																			if(tipo == CONSTANTE){
																				printf("Error en semántico la linea %d: Constante no inicializada.\n", yylineno);
																				errores_semanticos++;
																				$$=creaLC();
																			}
																			else if(!esUltimo(tS, pos)){
																				//Error
																				printf("Error en semántico la linea %d: Declaración duplicada.\n", yylineno);
																				errores_semanticos++;
																				$$=creaLC();
																			}
																			else{
																				Simbolo s;
																				s.nombre = $1; // ID de la variable
																				s.tipo = tipo;
																				s.valor = 0;
																				insertaLS(tS, finalLS(tS), s);


																				//Lista de Código
																				$$ = creaLC();
																			}
																			/*printf("AS->id\n"); */}
				| ID "=" expression										{ /* Caso inicializado */
																			insertaLM(memoriaDinamica, $1);
																			PosicionLista pos = buscaLS(tS,$1);

																			if(!esUltimo(tS, pos) && strcmp(recuperaLS(tS, pos).nombre,$1) == 0){
																				//Error
																				printf("Error en semántico la linea %d: Declaración duplicada.\n", yylineno);
																				errores_semanticos++;
																				$$=$3;
																			}
																			else{
																				Simbolo s;
																				s.nombre = $1; // ID de la variable
																				s.tipo = tipo;
																				s.valor = 0;
																				insertaLS(tS, finalLS(tS), s);


																				//Lista de Código
																				Operacion o;
																				o.op = "sw";
																				o.res = recuperaResLC($3);
																				o.arg1 = concatenar("_",$1);
																				o.arg2 = NULL;
																				$$=$3;
																				insertaLC($$, finalLC($$), o);
																				liberarReg(recuperaResLC($3));
																			}
																			/*printf("AS->id = EX\n"); */}
				;

statement_list 	: statement_list statement								{ /*printf("SL->SL S\n"); */
																			$$=$1;
																			concatenaLC($$, $2);
																			liberaLC($2);
																		}
				| %empty												{ /*printf("SL->lambda\n"); */
																			$$=creaLC();
																		}				
				;

statement		: ID "=" expression ";"									{ 	insertaLM(memoriaDinamica, $1);
																			PosicionLista pos = buscaLS(tS,$1);

																			if(esUltimo(tS, pos)){
																				printf("Error en linea %d: identificador %s no declarado.\n", yylineno, $1);
																				errores_semanticos++;
																				$$=$3;
																			}
																			else if(recuperaLS(tS, pos).tipo == CONSTANTE){
																				printf("Error en linea %d: asignación de valor %s constante.\n", yylineno, recuperaLS(tS, pos).nombre);
																				errores_semanticos++;
																				$$=$3;
																			}else{
																				Operacion o;
																				o.op = "sw";
																				o.res = recuperaResLC($3);
																				o.arg1 = concatenar("_",$1);
																				o.arg2 = NULL;
																				$$=$3;
																				insertaLC($$, finalLC($$), o);
																				liberarReg(recuperaResLC($3));

																			}
																			
																			/*printf("S->id = EX;\n"); */}
				| "{" statement_list "}"								{ /*printf("S->{SL}\n"); */
																			$$=$2;
																		}
				| IF "(" expression ")" statement ELSE statement		{ /*printf("S->if(EX) S else S\n"); */
																			$$=$3; //contenido if
																			liberarReg(recuperaResLC($3));

																			//beqz
																			Operacion o;
																			o.op = "beqz";
																			o.res = recuperaResLC($3);
																			char* etiqueta = nuevaEtiqueta();
																			o.arg1 = etiqueta;
																			o.arg2 = NULL;

																			//b
																			Operacion b;
																			b.op = "b";
																			char* etiqueta2 = nuevaEtiqueta();
																			b.res = etiqueta2;
																			b.arg1 = NULL;
																			b.arg2 = NULL;

																			//etiqueta
																			Operacion salto;
																			salto.op = concatenar(etiqueta, ":");
																			salto.res = NULL;
																			salto.arg1 = NULL;
																			salto.arg2 = NULL;

																			//etiqueta2
																			Operacion salto2;
																			salto2.op = concatenar(etiqueta2, ":");
																			salto2.res = NULL;
																			salto2.arg1 = NULL;
																			salto2.arg2 = NULL;																			

																			insertaLC($$, finalLC($$), o); //beqz
																			concatenaLC($$, $5); //se cumple
																			liberaLC($5);
																			insertaLC($$, finalLC($$), b); //b
																			insertaLC($$, finalLC($$), salto); //no se cumple
																			concatenaLC($$, $7); //codigo del else
																			liberaLC($7);
																			insertaLC($$, finalLC($$), salto2);
																		}
				| IF "(" expression ")" statement						{ /*printf("S->if(EX) S\n"); */
																			$$=$3;
																			liberarReg(recuperaResLC($3));

																			//beqz
																			Operacion o;
																			o.op = "beqz";
																			o.res = recuperaResLC($3);
																			char* etiqueta = nuevaEtiqueta();
																			o.arg1 = etiqueta;
																			o.arg2 = NULL;

																			//etiqueta
																			Operacion salto;
																			salto.op = concatenar(etiqueta, ":");
																			salto.res = NULL;
																			salto.arg1 = NULL;
																			salto.arg2 = NULL;

																			insertaLC($$, finalLC($$), o);
																			concatenaLC($$, $5);
																			liberaLC($5);
																			insertaLC($$, finalLC($$), salto);
																		}
				| WHILE "(" expression ")" statement					{ /*printf("S->while(EX) S\n"); */
																			$$=$3;
																			liberarReg(recuperaResLC($3));

																			char* etiqueta = nuevaEtiqueta();
																			//etiqueta inicio
																			Operacion inicio;
																			inicio.op = concatenar(etiqueta, ":");
																			inicio.res = NULL;
																			inicio.arg1 = NULL;
																			inicio.arg2 = NULL;
																			insertaLC($$, inicioLC($$), inicio);

																			//beqz
																			Operacion o;
																			o.op = "beqz";
																			o.res = recuperaResLC($3);
																			char* etiqueta2 = nuevaEtiqueta();
																			o.arg1 = etiqueta2;
																			o.arg2 = NULL;
																			insertaLC($$, finalLC($$), o);

																			concatenaLC($$, $5);
																			liberaLC($5);

																			Operacion b;
																			b.op = "b";
																			b.res = etiqueta;
																			b.arg1 = NULL;
																			b.arg2 = NULL;
																			insertaLC($$, finalLC($$), b);

																			//etiqueta final
																			Operacion final;
																			inicio.op = concatenar(etiqueta2, ":");
																			inicio.res = NULL;
																			inicio.arg1 = NULL;
																			inicio.arg2 = NULL;
																			insertaLC($$, finalLC($$), inicio);
																		}
				| PRINT print_list ";"									{ /*printf("S->print PL ;\n"); */
																			$$=$2;
																		}
				| READ read_list ";"									{ /*printf("S->read RL ;\n"); */
																			$$=$2;
																		}
				;

print_list		: print_item 											{ /*printf("PL->PI\n"); */ 
																			$$=$1;
																		}
				| print_list "," print_item								{ /*printf("PL->PL,PI\n"); */
																			$$=$1;
																			concatenaLC($$, $3);
																			liberaLC($3);
																		}

				;

print_item		: expression 											{ /*printf("PI->EX\n"); */
																			
																			//Lista de Código
																			//li
																			Operacion li;
																			li.op = "li";
																			li.res = "$v0";
																			li.arg1 = "1";
																			li.arg2 = NULL;

																			//move
																			Operacion la;
																			la.op = "move";
																			la.res = "$a0";
																			la.arg1 = recuperaResLC($1);
																			la.arg2 = NULL;

																			//syscall
																			Operacion sys;
																			sys.op = "syscall";
																			sys.res = NULL;
																			sys.arg1 = NULL;
																			sys.arg2 = NULL;

																			$$=$1;
																			liberarReg(recuperaResLC($1));
																			insertaLC($$,finalLC($$), li);
																			insertaLC($$,finalLC($$), la);
																			insertaLC($$,finalLC($$), sys);
																		}
				| STRING												{ 	//Tabla de Símbolos					Simbolo s;
																			insertaLM(memoriaDinamica, $1);

																			Simbolo s;
																			s.nombre = $1;
																			s.tipo = CADENA;
																			s.valor = contString++; //número de cadena
																			insertaLS(tS, finalLS(tS), s);

																			//Lista de Código
																			//li
																			Operacion li;
																			li.op = "li";
																			li.res = "$v0";
																			li.arg1 = "4";
																			li.arg2 = NULL;

																			//la
																			Operacion la;
																			la.op = "la";
																			la.res = "$a0";
																			la.arg1 = concatenar_entero("$str", s.valor);
																			la.arg2 = NULL;

																			//syscall
																			Operacion sys;
																			sys.op = "syscall";
																			sys.res = NULL;
																			sys.arg1 = NULL;
																			sys.arg2 = NULL;

																			$$ = creaLC();
																			insertaLC($$,finalLC($$), li);
																			insertaLC($$,finalLC($$), la);
																			insertaLC($$,finalLC($$), sys);

																			/*printf("PI->string\n"); */}
				;

read_list		: ID													{ 	insertaLM(memoriaDinamica, $1);
																			
																			PosicionLista pos = buscaLS(tS,$1);
																			if(esUltimo(tS, pos)){
																				printf("Error en linea %d: identificador %s no declarado.\n", yylineno, $1);
																				errores_semanticos++;
																				$$=creaLC();
																			}
																			else if(recuperaLS(tS, pos).tipo == CONSTANTE){
																				printf("Error en linea %d: asignación de valor %s constante.\n", yylineno, recuperaLS(tS, pos).nombre);
																				errores_semanticos++;
																				$$=creaLC();
																			}else{
																				//Lista de Código
																				$$=creaLC();

																				//li
																				Operacion li;
																				li.op = "li";
																				li.res = "$v0";
																				li.arg1 = "5";
																				li.arg2 = NULL;

																				//syscall
																				Operacion sys;
																				sys.op = "syscall";
																				sys.res = NULL;
																				sys.arg1 = NULL;
																				sys.arg2 = NULL;

																				//sw
																				Operacion sw;
																				sys.op = "sw";
																				sys.res = "$v0";
																				sys.arg1 = concatenar("_",$1);
																				sys.arg2 = NULL;

																				//Componer lista
																				insertaLC($$, finalLC($$), li);
																				insertaLC($$, finalLC($$), sys);
																				insertaLC($$, finalLC($$), sw);
																			}


																			/*printf("RL->id\n"); */}
				| read_list "," ID										{ /*printf("RL->RL,id\n"); */
																			insertaLM(memoriaDinamica, $3);
																			
																			$$=$1;

																			//li
																			Operacion li;
																			li.op = "li";
																			li.res = "$v0";
																			li.arg1 = "5";
																			li.arg2 = NULL;

																			//syscall
																			Operacion sys;
																			sys.op = "syscall";
																			sys.res = NULL;
																			sys.arg1 = NULL;
																			sys.arg2 = NULL;

																			//sw
																			Operacion sw;
																			sys.op = "sw";
																			sys.res = "$v0";
																			sys.arg1 = concatenar("_",$3);
																			sys.arg2 = NULL;

																			//Componer lista
																			insertaLC($$, finalLC($$), li);
																			insertaLC($$, finalLC($$), sys);
																			insertaLC($$, finalLC($$), sw);
																		}
				;

expression		: expression "+" expression								{ /*printf("E->E+E\n"); */
																			Operacion o;
																			o.op = "add";
																			o.res = recuperaResLC($1);
																			o.arg1 = recuperaResLC($1);
																			o.arg2 = recuperaResLC($3);
																			concatenaLC($1,$3);
																			liberarReg(recuperaResLC($3));
																			liberaLC($3);
																			$$=$1;
																			insertaLC($$,finalLC($$),o);
																			guardaResLC($$, o.res);
																		}
				| expression "-" expression								{ /*printf("E->E-E\n"); */
																			Operacion o;
																			o.op = "sub";
																			o.res = recuperaResLC($1);
																			o.arg1 = recuperaResLC($1);
																			o.arg2 = recuperaResLC($3);
																			concatenaLC($1, $3);
																			liberarReg(recuperaResLC($3));
																			liberaLC($3);
																			$$=$1;
																			insertaLC($$,finalLC($$),o);
																			guardaResLC($$, o.res);
																		}
				| expression "*" expression								{ /*printf("E->E*E\n"); */
																			Operacion o;
																			o.op = "mul";
																			o.res = recuperaResLC($1);
																			o.arg1 = recuperaResLC($1);
																			o.arg2 = recuperaResLC($3);
																			concatenaLC($1, $3);
																			liberarReg(recuperaResLC($3));
																			liberaLC($3);
																			$$=$1;
																			insertaLC($$,finalLC($$),o);
																			guardaResLC($$, o.res);
																		}
				| expression "/" expression								{ /*printf("E->E/E\n"); */
																			Operacion o;
																			o.op = "div";
																			o.res = recuperaResLC($1);
																			o.arg1 = recuperaResLC($1);
																			o.arg2 = recuperaResLC($3);
																			concatenaLC($1, $3);
																			liberarReg(recuperaResLC($3));
																			liberaLC($3);
																			$$=$1;
																			insertaLC($$,finalLC($$),o);
																			guardaResLC($$, o.res);
																		}
				| "-" expression %prec UMENOS							{/* printf("E->-E\n"); */
																			Operacion o;
																			o.op = "neg";
																			o.res = recuperaResLC($2);
																			o.arg1 = recuperaResLC($2);
																			o.arg2 = NULL;
																			$$=$2;
																			insertaLC($$,finalLC($$),o);
																			guardaResLC($$, o.res);
																		}
				| "(" expression ")"									{ /*printf("E->(E)\n"); */
																			$$=$2;
																		}	
				| ID													{ 	insertaLM(memoriaDinamica, $1);
																			PosicionLista pos = buscaLS(tS,$1);
																			if(esUltimo(tS, pos)){
																				printf("Error en linea %d: identificador %s no declarado.\n", yylineno, $1);
																				errores_semanticos++;
																			}
																			$$ = creaLC();
																			Operacion o;
																			o.op = "lw";
																			o.res = obtenerReg();
																			o.arg1 = concatenar("_",$1);
																			o.arg2 = NULL;
																			insertaLC($$,inicioLC($$),o);
																			guardaResLC($$,o.res);
																			/*printf("E->id\n"); */
																		}
				| NUM													{/* printf("E->num\n");*/ 
																			insertaLM(memoriaDinamica, $1);

																			$$ = creaLC();
																			Operacion o;
																			o.op = "li";
																			o.res = obtenerReg();
																			o.arg1= $1;
																			o.arg2 = NULL;
																			insertaLC($$,inicioLC($$),o);
																			guardaResLC($$,o.res);
																		}
				;
%%				

void yyerror(const char *msg){
	printf("Error en sintáctico la linea %d: %s\n", yylineno, msg);
	errores_sintacticos++;
}

void inicializar_regs(){
	for(int i=0; i<10; i++)
		r[i]=0;
}

char* obtenerReg(){
	for(int i=0; i<10; i++){
		if(!r[i]){
			r[i]=1;
			char num[2];
			sprintf(num,"%d",i);
			return concatenar("$t",num);
		}
	}

	fprintf(stderr, "[ERROR] No quedan registros disponibles!\n");
	exit(1);
}

void liberarReg(char* reg){
	int i = reg[2] - '0';
	r[i]=0;
}

char* concatenar(char* a, char* b){
	char* resultado = (char*) malloc(strlen(a)+strlen(b)+1);
	strcpy(resultado,a);
	strcat(resultado,b);

	insertaLM(memoriaDinamica, resultado);

	return resultado;
}

char* concatenar_entero(char* a, int b){
	char* b_char = (char*) malloc(sizeof(int));
	*b_char = b+'0';

	insertaLM(memoriaDinamica, b_char);

	return concatenar(a, b_char);
}

char* nuevaEtiqueta(){
	char aux[16];
	sprintf(aux, "$l%d", contador_etiq++);
	char* resultado = strdup(aux);

	insertaLM(memoriaDinamica, resultado);

	return resultado;
}