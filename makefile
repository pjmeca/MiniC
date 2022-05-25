# Este código permite pasar argumentos al make run
# Fuente: https://stackoverflow.com/questions/2214575/passing-arguments-to-make-run
ifeq (run,$(firstword $(MAKECMDGOALS)))
  	RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  	$(eval $(RUN_ARGS):;@:)
endif

miniC : miniC.tab.c lex.yy.c main.c listaSimbolos.c listaCodigo.c listaMemoria.c
	@gcc miniC.tab.c lex.yy.c main.c listaSimbolos.c listaCodigo.c listaMemoria.c -lfl -o miniC -ggdb3

lex.yy.c : miniC.l miniC.tab.h miniC.tab.c
	@flex miniC.l

miniC.tab.h miniC.tab.c : miniC.y
	@bison -d miniC.y

clean :
	@rm -f miniC.tab.* miniC lex.yy.c salida.s

debug : miniC
	@valgrind --leak-check=full --track-origins=yes --show-leak-kinds=all ./minic prueba.mc

run : miniC
	@./miniC $(RUN_ARGS) > salida.s
	@echo 'Salida guardada en salida.s'