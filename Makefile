CC = gcc
CFLAGS = -O2 -fopenmp -Wall
LDFLAGS = -lm

.PHONY: all clean

all: secuencial/histograma paralelo/histograma_omp secuencial/riemann paralelo/riemann_omp

secuencial/histograma: secuencial/histograma.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

paralelo/histograma_omp: paralelo/histograma_omp.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

secuencial/riemann: secuencial/riemann.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

paralelo/riemann_omp: paralelo/riemann_omp.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f secuencial/histograma paralelo/histograma_omp secuencial/riemann paralelo/riemann_omp
