# gcc -O2 -fopenmp -Wall -lm
# En macOS, /usr/bin/gcc suele ser Clang sin OpenMP. Se busca un GCC de
# Homebrew (gcc-17 ... gcc-11) y, si no hay, Clang con libomp.

UNAME_S := $(shell uname -s)

CFLAGS = -O2 -fopenmp -Wall
LDFLAGS = -lm

ifeq ($(origin CC),default)
  CC = gcc
endif

ifeq ($(UNAME_S),Darwin)
  BREW_GCC := $(shell command -v gcc-17 2>/dev/null || command -v gcc17 2>/dev/null || command -v gcc-16 2>/dev/null || command -v gcc16 2>/dev/null || command -v gcc-15 2>/dev/null || command -v gcc-14 2>/dev/null || command -v gcc-13 2>/dev/null || command -v gcc-12 2>/dev/null || command -v gcc-11 2>/dev/null || true)
  ifneq ($(BREW_GCC),)
    CC = $(BREW_GCC)
  else
    LIBOMP_PREFIX := $(shell brew --prefix libomp 2>/dev/null || true)
    ifneq ($(LIBOMP_PREFIX),)
      CC = clang
      CFLAGS = -O2 -Xpreprocessor -fopenmp -Wall -I$(LIBOMP_PREFIX)/include
      LDFLAGS = -L$(LIBOMP_PREFIX)/lib -lomp -lm
    endif
  endif
endif

.PHONY: all clean print-config

all: print-config secuencial/histograma paralelo/histograma_omp secuencial/riemann paralelo/riemann_omp

print-config:
	@echo "SO=$(UNAME_S) CC=$(CC)"
	@echo "CFLAGS=$(CFLAGS)"
	@echo "LDFLAGS=$(LDFLAGS)"

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
