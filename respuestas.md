# Respuestas

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque la tabla `entregas_db.entregas` no depende de particiones registradas en Glue. Tiene `projection.enabled = true` y reglas para `fecha` de tipo `date`, con formato `yyyy-MM-dd`, rango `2026-10-01,2026-10-03`, intervalo de 1 día y la plantilla `s3://BUCKET/entregas/fecha=${fecha}/`. En cada consulta Athena genera los valores posibles de `fecha` dentro del rango y arma con la plantilla el prefijo S3 de cada uno. Desde el despliegue inicial el 3 de octubre ya era un valor proyectado y su prefijo ya estaba calculado.

Antes de subir el archivo ese prefijo estaba vacío. Athena no da error con una partición proyectada sin objetos, simplemente no devuelve filas. Por eso los resultados iniciales tienen solo dos fechas. Al subir `entregas/fecha=2026-10-03/entregas.csv` el prefijo pasó a tener datos y la misma consulta los incluyó.

La evidencia lo respalda. `evidencias/particiones_glue.json` muestra que la tabla no tiene particiones registradas. `evidencias/plan_sin_cambios.txt` muestra que la infraestructura no cambió entre etapas. `resultados/final/registros_por_fecha.csv` muestra 6 registros el día 3 y 18 en total, y las ejecuciones con etapa `final` en `evidencias/ejecuciones_athena.csv` usan los mismos archivos SQL que las iniciales.

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

El archivo quedaría en S3 pero Athena no lo leería. `2026-10-04` está fuera de `projection.fecha.range`, así que Athena no genera ese valor ni su ubicación. Las consultas agregadas seguirían devolviendo solo los tres primeros días (18 registros) y un filtro `WHERE fecha = '2026-10-04'` terminaría sin error pero con cero filas. La plantilla y el esquema no son el problema porque el archivo respeta la ruta. Lo que falta es que la fecha esté dentro del rango.

Para incluirlo hay que ampliar el rango de la tabla en Terraform, por ejemplo con `fecha_fin_proyeccion = "2026-10-04"`, y aplicar. Eso actualiza solo la propiedad `projection.fecha.range` y no registra particiones. Para no repetir este cambio cada día se puede usar un rango relativo como `2026-10-01,NOW`, que proyecta hasta la fecha actual en UTC en cada consulta.
