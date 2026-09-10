# Suma de Riemann para integracion numerica

## 1. Contexto y datos

El algoritmo aproxima la integral definida de f(x) = x al cuadrado mas seno de x en un intervalo [a, b] mediante una suma de Riemann por la izquierda: cada rectangulo i usa xi = a + i * dx como punto de evaluacion, no el punto medio.

La funcion f(x) tiene primitiva conocida F(x) = x al cubo entre tres menos coseno de x. Esto permite verificar la correctitud del resultado comparando el area aproximada contra el valor exacto F(b) - F(a), en vez de depender solo de la inspeccion visual del resultado.

Se utilizan n = 1,000,000,000 (10^9) rectangulos. Este tamano ya es suficientemente grande por diseno original: a diferencia del histograma, aqui no hizo falta escalar el problema para obtener un tiempo de ejecucion medible y un buen aprovechamiento de los hilos.

Los limites a y b se leen por teclado, pero en todas las corridas de prueba se usa el mismo par fijo (a = 0, b = 100) para que los tiempos sean comparables entre integrantes y entre versiones.

### Estructuras de datos

A diferencia del histograma, esta version no guarda ningun arreglo en memoria. Cada xi se calcula y se reduce al acumulador areaTotal en el momento, por lo que el uso de memoria es constante (O(1)) sin importar que tan grande sea n.

## 2. Estrategia de paralelizacion

El ciclo principal recorre todos los rectangulos y sus iteraciones son completamente independientes entre si: cada una calcula su propio xi, evalua f(xi) y suma su area al acumulador comun.

### Reduccion sobre el acumulador

Se utiliza reduction(+:areaTotal) sobre el ciclo. Cada hilo mantiene una copia privada del acumulador, suma en ella las areas de su bloque de iteraciones, y OpenMP combina las copias parciales al cerrar la region paralela. Esto evita la condicion de carrera sobre areaTotal sin necesitar atomic ni critical en cada suma, y sin serializar a los hilos entre si.

### Cambio de while a for

La version secuencial original recorre los rectangulos con un ciclo while. La directiva parallel for exige un ciclo for con forma canonica, asi que el ciclo se reescribe como for (i = 0; i < n; i++) manteniendo exactamente el mismo cuerpo y el mismo resultado matematico. Es un cambio de sintaxis, no de algoritmo.

### Planificacion estatica

Se utiliza schedule static porque el costo por iteracion es uniforme: cada una hace una evaluacion de f(x) y una multiplicacion, sin ningun desbalance de carga que justifique una planificacion dinamica.

### Contraste con el histograma

El histograma necesito una estrategia mas elaborada porque su segundo ciclo trabaja sobre una estructura compartida (el arreglo de cubetas) con acceso disperso, lo que obligo a usar histogramas locales por hilo. La suma de Riemann, en cambio, reduce todo a un unico acumulador escalar, lo que hace que reduction sea suficiente por si sola: es el caso de paralelizacion natural y sencilla.

## Resultados individuales

### Francisco Martinez

- Maquina: AMD Ryzen AI 7 350 w/ Radeon 860M
- Nucleos: 8 fisicos (16 hilos de hardware)
- Sistema: Linux
- Compilacion: `make all` (`gcc -O2 -fopenmp -Wall -lm`)
- Intervalo de prueba: a = 0, b = 100
- Medicion: promedio de 3 corridas; Speedup(p) = T_secuencial / T_paralelo(p); Eficiencia(p) = Speedup(p) / p
- Fuente: `docs/resultados/riemann_tiempos_juanfrancisco.csv`

| Hilos | Tiempo (s) | Speedup | Eficiencia |
| --- | --- | --- | --- |
| secuencial (T1) | 7.047440 | 1.000000 | 1.000000 |
| 1 | 7.122148 | 0.989510 | 0.989510 |
| 2 | 3.735724 | 1.886499 | 0.943249 |
| 4 | 2.023296 | 3.483148 | 0.870787 |
| 8 | 1.460862 | 4.824165 | 0.603021 |

La version paralela mejora de forma clara: de 7.05 s secuenciales a 1.46 s con 8 hilos (speedup 4.82x). Con 2 y 4 hilos la eficiencia se mantiene alta (0.94 y 0.87). En 8 hilos baja a 0.60, coherente con usar los 8 nucleos fisicos y empezar a competir por recursos compartidos. Este problema escala mejor que el histograma porque cada iteracion es independiente y el trabajo (10^9 rectangulos) amortiza el overhead de OpenMP.

### Fernando Ruiz

- Maquina: Apple M2
- Nucleos: 8 fisicos (8 hilos de hardware)
- Sistema: macOS 26.5.2
- Compilacion: `make all` (`gcc-16 -O2 -fopenmp -Wall -lm`)
- Intervalo de prueba: a = 0, b = 100
- Medicion: promedio de 3 corridas; Speedup(p) = T_secuencial / T_paralelo(p); Eficiencia(p) = Speedup(p) / p
- Fuente: `docs/resultados/riemann_tiempos_fernando.csv`

| Hilos | Tiempo (s) | Speedup | Eficiencia |
| --- | --- | --- | --- |
| secuencial (T1) | 3.526959 | 1.000000 | 1.000000 |
| 1 | 3.605438 | 0.978233 | 0.978233 |
| 2 | 1.778868 | 1.982699 | 0.991349 |
| 4 | 0.979912 | 3.599261 | 0.899815 |
| 8 | 0.779108 | 4.526919 | 0.565865 |

La mejora es clara y sostenida: de 3.53 s secuenciales a 0.78 s con 8 hilos, un speedup de 4.53x. Con 2 hilos la eficiencia es de 0.99, practicamente el escalado ideal, y con 4 hilos se mantiene alta en 0.90. En 8 hilos baja a 0.57, algo esperable al ocupar todos los nucleos fisicos de la maquina. Este problema escala mucho mejor que el histograma porque los 10^9 rectangulos amortizan de sobra el overhead de OpenMP y cada iteracion es independiente, sin ninguna estructura compartida de por medio.
