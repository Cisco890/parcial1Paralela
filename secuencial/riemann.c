#include <stdio.h>
#include <math.h>
#include <omp.h>

// Definir la función f(x)
double f(double x)
{
    return x * x + sin(x);   // Ejemplo: f(x) = x²
}

// Primitiva de f(x), usada para verificar la correctitud del resultado
double F(double x)
{
    return (x * x * x) / 3.0 - cos(x);
}

int main()
{
    // Declaración de variables
    double a, b;
    double dx;
    double areaTotal = 0.0;
    double xi, altura, areaRectangulo;

    long long n = 1000000000LL; // 10^9 rectángulos
    long long i = 0;

    // Variables para medir el tiempo
    double inicio, fin, tiempo;

    printf("Integracion Numerica (Suma de Riemann)\n");

    printf("Ingrese el limite inferior (a): ");
    scanf("%lf", &a);

    printf("Ingrese el limite superior (b): ");
    scanf("%lf", &b);

    // Calcular ancho del rectángulo
    dx = (b - a) / n;

    // Inicializar área total
    areaTotal = 0.0;

    // Iniciar temporizador
    inicio = omp_get_wtime();

    // Ciclo principal
    while (i < n)
    {
        // Calcular xi
        xi = a + i * dx;

        // Evaluar altura
        altura = f(xi);

        // Calcular área del rectángulo
        areaRectangulo = altura * dx;

        // Sumar al área total
        areaTotal += areaRectangulo;

        // Incrementar contador
        i++;
    }

    // Detener temporizador
    fin = omp_get_wtime();

    // Calcular tiempo en segundos
    tiempo = fin - inicio;

    // Valor exacto de la integral, calculado con la primitiva conocida de f(x)
    double areaExacta = F(b) - F(a);

    // Mostrar resultados
    printf("Area total aproximada = %.15lf\n", areaTotal);
    printf("Area exacta (primitiva) = %.15lf\n", areaExacta);
    printf("Diferencia con el valor exacto = %.15lf\n", fabs(areaTotal - areaExacta));
    printf("Rectangulos utilizados = %lld\n", n);
    printf("Tiempo de ejecucion = %.6lf segundos\n", tiempo);
    printf("TIEMPO_SEG,%.6lf\n", tiempo);
    return 0;
}
