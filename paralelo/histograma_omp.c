#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define N 10000000
#define NUM_BINS 100

int main() {
    // Reservar memoria para mediciones e histograma
    float *arreglo = malloc(N * sizeof(float));
    long *histograma = calloc(NUM_BINS, sizeof(long));

    if (arreglo == NULL || histograma == NULL) {
        printf("Error al reservar memoria\n");
        return 1;
    }

    // Generar datos aleatorios de temperatura de forma secuencial
    srand(42);
    for (int j = 0; j < N; j++) {
        arreglo[j] = ((float)rand() / RAND_MAX) * 100.0f;
    }

    // Medir tiempo de la seccion paralela
    double t_inicio = omp_get_wtime();

    // Primer ciclo: reduccion para encontrar minimo y maximo
    float Max = arreglo[0];
    float Min = arreglo[0];
    #pragma omp parallel for reduction(max:Max) reduction(min:Min) schedule(static)
    for (int i = 1; i < N; i++) {
        float dato = arreglo[i];

        if (dato > Max) Max = dato;
        if (dato < Min) Min = dato;
    }

    // Calcular ancho del rango
    double anchoRango = (Max - Min) / NUM_BINS;

    // Segundo ciclo: reduccion con histogramas locales por hilo
    int nthreads = omp_get_max_threads();
    long *locales = calloc((size_t)nthreads * NUM_BINS, sizeof(long));
    if (locales == NULL) {
        printf("Error al reservar memoria\n");
        return 1;
    }

    #pragma omp parallel
    {
        long *mio = locales + (size_t)omp_get_thread_num() * NUM_BINS;

        #pragma omp for schedule(static)
        for (int i = 0; i < N; i++) {
            float dato = arreglo[i];

            int indice = (int)((dato - Min) / anchoRango);

            if (indice >= NUM_BINS) indice = NUM_BINS - 1;
            if (indice < 0) indice = 0;

            mio[indice]++;
        }
    }

    // Mezclar histogramas locales en el histograma final
    for (int t = 0; t < nthreads; t++) {
        for (int b = 0; b < NUM_BINS; b++) {
            histograma[b] += locales[(size_t)t * NUM_BINS + b];
        }
    }

    double t_fin = omp_get_wtime();

    // Imprimir resultados
    long total = 0;
    printf("Min encontrado: %.4f | Max encontrado: %.4f\n\n", Min, Max);
    for (int b = 0; b < NUM_BINS; b++) {
        printf("Bin %3d [%.2f - %.2f): %ld mediciones\n",
               b, Min + b * anchoRango, Min + (b + 1) * anchoRango, histograma[b]);
        total += histograma[b];
    }
    printf("\nTotal clasificado: %ld (deberia ser %d)\n", total, N);
    printf("Hilos utilizados: %d\n", nthreads);

    // Formato de salida para benchmark
    printf("TIEMPO_SEG,%.6f\n", t_fin - t_inicio);

    free(locales);
    free(arreglo);
    free(histograma);
    return 0;
}
