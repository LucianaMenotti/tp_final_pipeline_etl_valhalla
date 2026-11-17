CREATE OR REPLACE TABLE tabla_final AS
WITH validos_tipados AS (
    SELECT
        id_pedido,
        CAST(fecha_pedido AS DATE) AS fecha_pedido,
        id_cliente,
        email_cliente,
        pais,
        ciudad,
        categoria,
        producto,
        CAST(cantidad AS INTEGER) AS cantidad,
        CAST(precio_unitario AS DOUBLE) AS precio_unitario,
        CAST(descuento_pct AS DOUBLE) AS descuento_pct,
        CAST(total AS DOUBLE) AS total,
        estado,
        medio_pago
    FROM validos
),
todos AS (
    SELECT * FROM validos_tipados
    UNION ALL BY NAME
    SELECT * FROM rechazados_limpios
    WHERE id_pedido NOT IN (SELECT id_pedido FROM validos)
)
SELECT *
FROM todos
QUALIFY ROW_NUMBER() OVER (PARTITION BY id_pedido ORDER BY id_pedido) = 1;