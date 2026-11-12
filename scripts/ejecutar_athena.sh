#!/usr/bin/env bash
# Ejecuta una sentencia SQL en el workgroup del ejercicio, descarga el resultado
# y registra la ejecucion en evidencias/ejecuciones_athena.csv
#
# Uso: bash scripts/ejecutar_athena.sh <etapa> <archivo_sql> <archivo_resultado> [numero_sentencia]
#   etapa             inicial | final
#   archivo_sql       ruta relativa a la raiz del repositorio
#   archivo_resultado ruta relativa a la raiz del repositorio
#   numero_sentencia  opcional, para archivos con varias sentencias separadas por punto y coma
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$#" -lt 3 ]; then
    echo "Uso: bash scripts/ejecutar_athena.sh <etapa> <archivo_sql> <archivo_resultado> [numero_sentencia]" >&2
    exit 2
fi

etapa=$1
archivo_sql=$2
archivo_resultado=$3
numero=${4:-1}

case "$etapa" in
    inicial|final) ;;
    *) echo "La etapa debe ser inicial o final" >&2; exit 2 ;;
esac

region=$(terraform -chdir=infraestructura output -raw region)
workgroup=$(terraform -chdir=infraestructura output -raw workgroup)
base_datos=$(terraform -chdir=infraestructura output -raw base_datos)

# Extrae la sentencia pedida: separa por punto y coma y quita lineas de comentario
sentencia=$(awk -v n="$numero" 'BEGIN { RS = ";" } NR == n { print }' "$archivo_sql" | grep -v '^[[:space:]]*--' || true)
if [ -z "$(printf '%s' "$sentencia" | tr -d '[:space:]')" ]; then
    echo "No existe la sentencia $numero en $archivo_sql" >&2
    exit 1
fi

id_ejecucion=$(aws athena start-query-execution \
    --region "$region" \
    --work-group "$workgroup" \
    --query-execution-context Database="$base_datos" \
    --query-string "$sentencia" \
    --query QueryExecutionId --output text)
echo "Ejecucion $id_ejecucion ($archivo_sql, sentencia $numero)"

while :; do
    estado=$(aws athena get-query-execution --region "$region" --query-execution-id "$id_ejecucion" \
        --query QueryExecution.Status.State --output text)
    case "$estado" in
        SUCCEEDED) break ;;
        FAILED|CANCELLED)
            aws athena get-query-execution --region "$region" --query-execution-id "$id_ejecucion" \
                --query QueryExecution.Status.StateChangeReason --output text >&2
            exit 1 ;;
    esac
    sleep 1
done

ubicacion=$(aws athena get-query-execution --region "$region" --query-execution-id "$id_ejecucion" \
    --query QueryExecution.ResultConfiguration.OutputLocation --output text)

mkdir -p "$(dirname "$archivo_resultado")" evidencias
# Athena entrega cada valor entre comillas. Los datos no contienen comas ni comillas,
# asi que se retiran para dejar el mismo formato de resultados_esperados/
aws s3 cp --region "$region" --only-show-errors "$ubicacion" - | sed 's/"//g' > "$archivo_resultado"

registro=evidencias/ejecuciones_athena.csv
if [ ! -s "$registro" ]; then
    echo "etapa,archivo_sql,id_ejecucion,archivo_resultado" > "$registro"
fi
echo "$etapa,$archivo_sql,$id_ejecucion,$archivo_resultado" >> "$registro"

echo "Resultado guardado en $archivo_resultado"
cat "$archivo_resultado"
