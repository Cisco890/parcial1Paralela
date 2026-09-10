# OptiNúcleo HPC

Consultora de optimización de software de alto rendimiento.

## Equipo

- Fernando Ruiz
- Iris Ayala
- Francisco Martinez

## Qué hace este repositorio

Este proyecto documenta una consultoría de paralelización con OpenMP sobre dos problemas: un histograma de mediciones de temperatura y una suma de Riemann para integración numérica. Cada problema incluye una versión secuencial de referencia y una versión paralela, junto con la evidencia de speedup y eficiencia.

Estructura del repositorio:

- `/secuencial` — implementaciones originales, con medición de tiempo comparable.
- `/paralelo` — versiones OpenMP de Histograma y Suma de Riemann.
- `/docs` — contexto, estrategia de paralelización, scripts de benchmark y evidencia de corridas.

## Compilación (Linux y macOS)

```bash
make all
make clean
```

Los cuatro binarios se compilan con optimización `-O2` y OpenMP. En Linux se usa `gcc -fopenmp`. En macOS, `gcc` del sistema suele ser Clang sin OpenMP; el Makefile busca un GCC de Homebrew (`gcc-17`, `gcc-16`, `gcc-15`, …) y, si no está, Clang con `libomp`:

```bash
brew install gcc
# o, como alternativa:
brew install libomp
```

El script `docs/scripts/benchmark.sh` corre en ambos sistemas: detecta núcleos, recorta la lista 1/2/4/8 si la máquina tiene menos de 8, y alimenta `a`/`b` por stdin en Suma de Riemann.
