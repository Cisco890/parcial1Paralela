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

Se completa en la corrida final de cada integrante.
