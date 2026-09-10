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

Se completa en la corrida final de cada integrante.
