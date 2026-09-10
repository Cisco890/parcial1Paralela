# Histograma de mediciones de temperatura

## 1. Contexto y datos

El algoritmo construye un histograma de frecuencias sobre un conjunto grande de mediciones de temperatura. Cada medicion es un float generado en el rango de cero a cien y el histograma las reparte en 100 cubetas.

El tamano utilizado es de 10 millones de elementos. Este tamano permite ejecutar pruebas rapidas y evaluar el rendimiento con 1, 2, 4 y 8 hilos. El trabajo por hilo es suficiente para superar el costo de crear la region paralela.

La semilla fija garantiza que la version secuencial y la paralela procesen exactamente los mismos datos.

### Estructuras de datos

- arreglo: bloque float de N elementos reservado con malloc para guardar las mediciones.
- histograma: bloque long de 100 elementos reservado con calloc para los contadores.

Existe una estructura grande en memoria y el segundo ciclo escribe sobre el arreglo compartido histograma. Este factor determina la estrategia de paralelizacion.

### Calculo del ancho de rango

El ancho de cada cubeta se calcula dividiendo la diferencia entre el valor maximo y minimo entre la cantidad de cubetas.

Este calculo requiere dos ciclos en el siguiente orden:

1. Un primer recorrido para obtener el valor minimo y el valor maximo.
2. Un segundo recorrido para clasificar cada elemento en su cubeta.

El segundo ciclo depende de los valores obtenidos en el primer ciclo.

## 2. Estrategia de paralelizacion

Los dos ciclos tienen requerimientos distintos de paralelizacion.

### Ciclo 1: Minimo y maximo

El primer ciclo utiliza reduccion sobre las variables de minimo y maximo. Cada hilo calcula los extremos de su bloque y OpenMP combina los resultados al cerrar la region. No existen condiciones de carrera.

### Ciclo 2: Conteo de frecuencias

El incremento de contadores en el histograma realiza accesos dispersos en el arreglo compartido. No es posible aplicar reduccion directa sobre una variable escalar.

Proteger cada incremento con atomic o critical genera demasiada sincronizacion y reduce el rendimiento.

La solucion aplicada consiste en histogramas locales por hilo:

1. Se reserva una matriz de contadores en cero segun la cantidad de hilos y cubetas.
2. Cada hilo acumula las frecuencias en su propia fila dentro de la region paralela.
3. Al terminar la region paralela se realiza la suma secuencial de los histogramas locales en el histograma final.

El costo de mezclar los histogramas locales es minimo comparado con el recorrido total.

### Sincronizacion entre ciclos

El ciclo de conteo requiere los valores finales de minimo y maximo. Al usar regiones paralelas separadas, la barrera al cerrar la primera region garantiza el orden correcto sin necesidad de sincronizacion adicional.

### Planificacion estatica

Se utiliza schedule static porque el trabajo por elemento es uniforme. Repartir bloques contiguos reduce el costo de planificacion y aprovecha la localidad de memoria.

### Procesamiento secuencial

La generacion de datos se mantiene secuencial para preservar la repetibilidad de las pruebas. La medicion de tiempo abarca unicamente las secciones paralelas.

## Resultados individuales

### Francisco Martinez

- Maquina: AMD Ryzen AI 7 350 w/ Radeon 860M
- Nucleos: 8 fisicos (16 hilos de hardware)
- Sistema: Linux
- Compilacion: `make all` (`gcc -O2 -fopenmp -Wall -lm`)
- Medicion: promedio de 3 corridas; Speedup(p) = T_secuencial / T_paralelo(p); Eficiencia(p) = Speedup(p) / p
- Fuente: `docs/resultados/histograma_tiempos_juanfrancisco.csv`

| Hilos | Tiempo (s) | Speedup | Eficiencia |
| --- | --- | --- | --- |
| secuencial (T1) | 0.022446 | 1.000000 | 1.000000 |
| 1 | 0.017542 | 1.279558 | 1.279558 |
| 2 | 0.010365 | 2.165557 | 1.082779 |
| 4 | 0.010257 | 2.188359 | 0.547090 |
| 8 | 0.007082 | 3.169444 | 0.396180 |

La version paralela si reduce el tiempo, pero el speedup maximo es de 3.17x con 8 hilos. Con 2 hilos la eficiencia se mantiene cerca de 1; a partir de 4 hilos cae con fuerza (0.55 y 0.40). El tiempo secuencial es de apenas 22 ms: con N = 10,000,000 el overhead de crear hilos y mezclar histogramas locales pesa mas que el trabajo util, y el escalado se aplana entre 2 y 4 hilos.

### Fernando Ruiz

- Maquina: Apple M2
- Nucleos: 8 fisicos (8 hilos de hardware)
- Sistema: macOS 26.5.2
- Compilacion: `make all` (`gcc-16 -O2 -fopenmp -Wall -lm`)
- Medicion: promedio de 3 corridas; Speedup(p) = T_secuencial / T_paralelo(p); Eficiencia(p) = Speedup(p) / p
- Fuente: `docs/resultados/histograma_tiempos_fernando.csv`

| Hilos | Tiempo (s) | Speedup | Eficiencia |
| --- | --- | --- | --- |
| secuencial (T1) | 0.020428 | 1.000000 | 1.000000 |
| 1 | 0.021262 | 0.960775 | 0.960775 |
| 2 | 0.011885 | 1.718805 | 0.859402 |
| 4 | 0.006451 | 3.166641 | 0.791660 |
| 8 | 0.007120 | 2.869101 | 0.358638 |

El mejor resultado se obtiene con 4 hilos: 3.17x de speedup y eficiencia de 0.79. Con 8 hilos el tiempo empeora respecto a 4 (0.007120 s contra 0.006451 s), es decir que agregar mas hilos deja de ayudar. La causa es el tamano del problema: el tiempo secuencial es de apenas 20 ms, asi que el costo de crear los hilos y mezclar los histogramas locales alcanza a competir con el trabajo util. Con 1 hilo el speedup es 0.96, ligeramente por debajo de 1, que es el costo esperado de abrir la region paralela sin ganar nada a cambio.
