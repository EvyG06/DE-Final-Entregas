-- Sentencia 1. Registros de 2026-10-03 (se esperan 6)
SELECT
    fecha,
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio ASC;

-- Sentencia 2. Conteo por estado de 2026-10-03
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado ASC;

-- Sentencia 3. Registros por fecha y total de la tabla (se esperan 6, 6, 6 y 18)
SELECT fecha, registros
FROM (
    SELECT fecha, COUNT(*) AS registros
    FROM entregas_db.entregas
    GROUP BY fecha
    UNION ALL
    SELECT 'total' AS fecha, COUNT(*) AS registros
    FROM entregas_db.entregas
)
ORDER BY fecha ASC;
