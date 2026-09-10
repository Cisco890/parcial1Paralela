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
