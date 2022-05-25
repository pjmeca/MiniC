#include "listaSimbolos.h"
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

struct ListaRep {
  PosicionLista cabecera;
  PosicionLista ultimo;
  int n;
};
struct PosicionListaRep {
  Simbolo dato;
  struct PosicionListaRep *sig;
};
typedef struct PosicionListaRep *NodoPtr;

Lista creaLS() {
  Lista nueva = malloc(sizeof(struct ListaRep));
  nueva->cabecera = malloc(sizeof(struct PosicionListaRep));
  nueva->cabecera->sig = NULL;
  nueva->ultimo = nueva->cabecera;
  nueva->n = 0;
  return nueva;
}

void liberaLS(Lista lista) {
  while (lista->cabecera != NULL) {
    NodoPtr borrar = lista->cabecera;
    lista->cabecera = borrar->sig;
    free(borrar);
  }
  free(lista);
}

void insertaLS(Lista lista, PosicionLista p, Simbolo s) {
  NodoPtr nuevo = malloc(sizeof(struct PosicionListaRep));
  nuevo->dato = s;
  nuevo->sig = p->sig;
  p->sig = nuevo;
  if (lista->ultimo == p) {
    lista->ultimo = nuevo;
  }
  (lista->n)++;
}

void suprimeLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  NodoPtr borrar = p->sig;
  p->sig = borrar->sig;
  if (lista->ultimo == borrar) {
    lista->ultimo = p;
  }
  free(borrar);
  (lista->n)--;
}

Simbolo recuperaLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  return p->sig->dato;
}

PosicionLista buscaLS(Lista lista, char *nombre) {
  NodoPtr aux = lista->cabecera;
  while (aux->sig != NULL && strcmp(aux->sig->dato.nombre,nombre) != 0) {
    aux = aux->sig;
  }
  return aux;
}

void asignaLS(Lista lista, PosicionLista p, Simbolo s) {
  assert(p != lista->ultimo);
  p->sig->dato = s;
}

int longitudLS(Lista lista) {
  return lista->n;
}

PosicionLista inicioLS(Lista lista) {
  return lista->cabecera;
}

PosicionLista finalLS(Lista lista) {
  return lista->ultimo;
}

PosicionLista siguienteLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  return p->sig;
}

int esUltimo(Lista lista, PosicionLista p){
  if(p == lista->ultimo)
    return 1;
  return 0;
}

void imprimeLS(Lista tS){
  printf("############################\n.data\n\n# STRINGS ##################\n");
	//Strings
	for(PosicionLista i = inicioLS(tS); i!=finalLS(tS); i=siguienteLS(tS, i)){
		if(recuperaLS(tS, i).tipo == CADENA){
			printf("$str%d:\n\t.asciiz %s\n", recuperaLS(tS, i).valor,recuperaLS(tS, i).nombre);
		}
	}

	//Variables
	printf("\n# IDENTIFIERS ##############\n");
	for(PosicionLista i = inicioLS(tS); i!=finalLS(tS); i=siguienteLS(tS, i)){
		if(recuperaLS(tS, i).tipo != CADENA){
				printf("_%s:\n\t.word 0\n",recuperaLS(tS, i).nombre);
		}
	}
  printf("\n\n");
}