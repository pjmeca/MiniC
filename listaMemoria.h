#ifndef __LISTA_MEMORIA__
#define __LISTA_MEMORIA__

/* ListaC es una lista enlazada de código, que contiene instancias de Operacion */
typedef struct ListaMRep * ListaM;
typedef struct PosicionListaMRep *PosicionListaM;

ListaM creaLM();
void liberaLM(ListaM codigo);
void insertaLM(ListaM codigo, char* c);
char* recuperaLM(ListaM codigo, PosicionListaM p);
int longitudLM(ListaM codigo);
PosicionListaM inicioLM(ListaM codigo);
PosicionListaM finalLM(ListaM codigo);
PosicionListaM siguienteLM(ListaM codigo, PosicionListaM p);

#endif