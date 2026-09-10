#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

REPS=3
A=0
B=100
OUTDIR="docs/resultados"

detect_ncores() {
    local n=""
    case "$(uname -s)" in
        Darwin)
            n="$(sysctl -n hw.physicalcpu 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || true)"
            ;;
        Linux)
            if [[ -r /proc/cpuinfo ]]; then
                n="$(awk -F: '/physical id/ { p=$2 } /core id/ { print p, $2 }' /proc/cpuinfo \
                    | sort -u | wc -l | awk '{ print $1 }')"
            fi
            if [[ -z "$n" || "$n" == "0" ]]; then
                n="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
            fi
            ;;
        *)
            n="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
            ;;
    esac
    n="$(printf '%s' "$n" | tr -d '[:space:]')"
    if [[ -z "$n" || "$n" == "0" ]]; then
        n=1
    fi
    printf '%s\n' "$n"
}

NCORES="$(detect_ncores)"
THREADS=(1)
if [[ "$NCORES" -ge 2 ]]; then
    THREADS=(1 2)
fi
if [[ "$NCORES" -ge 4 ]]; then
    THREADS=(1 2 4)
fi
if [[ "$NCORES" -ge 8 ]]; then
    THREADS=(1 2 4 8)
fi

echo "SO=$(uname -s) nucleos=${NCORES} hilos=${THREADS[*]}" >&2

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
            out="$(printf '%s %s\n' "$A" "$B" | OMP_NUM_THREADS="$threads" "$bin")"
        else
            out="$(printf '%s %s\n' "$A" "$B" | "$bin")"
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

    i=1
    while [[ "$i" -le "$REPS" ]]; do
        t="$(run_once "$kind" "$bin" "$threads")"
        echo "  corrida ${i}/${REPS}: ${t}s" >&2
        sum="$(awk -v s="$sum" -v x="$t" 'BEGIN { printf "%.12f", s + x }')"
        i=$((i + 1))
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
