#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

REPS=3
A=0
B=100
OUTDIR="docs/resultados"
THREADS=(1 2 4 8)

mkdir -p "$OUTDIR"
make all

extract_time() {
    local out="$1"
    local t
    t="$(printf '%s\n' "$out" | awk -F, '/TIEMPO_SEG/ { print $2 }' | tail -n1)"
    if [[ -z "$t" ]]; then
        echo "error: no se encontro TIEMPO_SEG en la salida" >&2
        printf '%s\n' "$out" >&2
        return 1
    fi
    printf '%s\n' "$t"
}

run_once() {
    local kind="$1"
    local bin="$2"
    local threads="${3:-}"
    local out

    if [[ "$kind" == "riemann" ]]; then
        if [[ -n "$threads" ]]; then
            out="$(echo "$A $B" | OMP_NUM_THREADS="$threads" "$bin")"
        else
            out="$(echo "$A $B" | "$bin")"
        fi
    else
        if [[ -n "$threads" ]]; then
            out="$(OMP_NUM_THREADS="$threads" "$bin")"
        else
            out="$("$bin")"
        fi
    fi

    extract_time "$out"
}

measure_avg() {
    local kind="$1"
    local bin="$2"
    local threads="${3:-}"
    local sum="0"
    local i t

    for i in $(seq 1 "$REPS"); do
        t="$(run_once "$kind" "$bin" "$threads")"
        echo "  corrida ${i}/${REPS}: ${t}s" >&2
        sum="$(awk -v s="$sum" -v x="$t" 'BEGIN { printf "%.12f", s + x }')"
    done

    awk -v s="$sum" -v n="$REPS" 'BEGIN { printf "%.6f", s / n }'
}

benchmark_problem() {
    local name="$1"
    local seq_bin="$2"
    local par_bin="$3"
    local kind="$4"
    local csv="${OUTDIR}/${name}_tiempos.csv"
    local t1 tp p speedup efi

    echo "==> ${name}: version secuencial (${REPS} corridas, T1)" >&2
    t1="$(measure_avg "$kind" "$seq_bin")"

    {
        echo "hilos,tiempo_seg,speedup,eficiencia"
        awk -v t1="$t1" 'BEGIN { printf "secuencial,%.6f,1.000000,1.000000\n", t1 }'

        for p in "${THREADS[@]}"; do
            echo "==> ${name}: paralelo OMP_NUM_THREADS=${p} (${REPS} corridas)" >&2
            tp="$(measure_avg "$kind" "$par_bin" "$p")"
            speedup="$(awk -v t1="$t1" -v tp="$tp" 'BEGIN { printf "%.6f", t1 / tp }')"
            efi="$(awk -v s="$speedup" -v p="$p" 'BEGIN { printf "%.6f", s / p }')"
            awk -v p="$p" -v tp="$tp" -v s="$speedup" -v e="$efi" \
                'BEGIN { printf "%s,%.6f,%.6f,%.6f\n", p, tp, s, e }'
        done
    } > "$csv"

    echo "escrito ${csv}"
}

benchmark_problem histograma secuencial/histograma paralelo/histograma_omp hist
benchmark_problem riemann secuencial/riemann paralelo/riemann_omp riemann

echo "benchmark terminado"
