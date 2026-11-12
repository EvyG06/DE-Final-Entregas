#!/usr/bin/env bash
# Compara los resultados obtenidos en Athena con las referencias suministradas
# Uso: bash scripts/comparar_resultados.sh <inicial|final>
set -uo pipefail
cd "$(dirname "$0")/.."

etapa=${1:?Uso: bash scripts/comparar_resultados.sh <inicial|final>}
case "$etapa" in
    inicial) pares="intentos_por_fecha_estado:intentos_por_fecha_estado_inicial
porcentaje_exito_por_fecha_ciudad:porcentaje_exito_por_fecha_ciudad_inicial
duracion_promedio_2026-10-02:duracion_promedio_2026-10-02" ;;
    final) pares="intentos_por_fecha_estado:intentos_por_fecha_estado_final
porcentaje_exito_por_fecha_ciudad:porcentaje_exito_por_fecha_ciudad_final" ;;
    *) echo "La etapa debe ser inicial o final" >&2; exit 2 ;;
esac

fallos=0
for par in $pares; do
    obtenido="resultados/$etapa/${par%%:*}.csv"
    esperado="resultados_esperados/${par##*:}.csv"
    if diff -u "$esperado" "$obtenido"; then
        echo "OK     $obtenido = $esperado"
    else
        echo "DIFERENTE  $obtenido vs $esperado"
        fallos=$((fallos + 1))
    fi
done
exit "$fallos"
