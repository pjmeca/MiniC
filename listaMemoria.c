#include "listaMemoria.h"
#include <stdlib.h>
#include <string.h>
#include <assert.h>

struct PosicionListaMRep {
  char* dato;
  struct PosicionListaMRep *sig;
};

struct ListaMRep {
  PosicionListaM cabecera;
  PosicionListaM ultimo;
  int n;
};

typedef struct PosicionListaMRep *NodoPtr;

ListaM creaLM() {
  ListaM nueva = malloc(sizeof(struct ListaMRep));
  nueva->cabecera = malloc(sizeof(struct PosicionListaMRep));
  nueva->cabecera->sig = NULL;
  nueva->ultimo = nueva->cabecera;
  return nueva;
}

void liberaLM(ListaM codigo) {
  while (codigo->cabecera != NULL) {
    NodoPtr borrar = codigo->cabecera;
    codigo->cabecera = borrar->sig;
    free(borrar->dato);
    free(borrar);
  }
  free(codigo);
}

void insertaLM(ListaM codigo, char* c) {
  NodoPtr nuevo = malloc(sizeof(struct PosicionListaMRep));
  nuevo->dato = c;
  nuevo->sig = codigo->ultimo->sig;
  codigo->ultimo->sig = nuevo;
  codigo->ultimo = nuevo;
  (codigo->n)++;
}

char* recuperaLM(ListaM codigo, PosicionListaM p) {
  assert(p != codigo->ultimo);
  return p->sig->dato;
}

int longitudLM(ListaM codigo) {
  return codigo->n;
}

PosicionListaM inicioLM(ListaM codigo) {
  return codigo->cabecera;
}

PosicionListaM finalLM(ListaM codigo) {
  return codigo->ultimo;
}

PosicionListaM siguienteLM(ListaM codigo, PosicionListaM p) {
  assert(p != codigo->ultimo);
  return p->sig;
}