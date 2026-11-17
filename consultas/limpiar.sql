CREATE OR REPLACE TABLE ref_ciudad_pais AS
SELECT ciudad, MIN(pais) AS pais
FROM validos
GROUP BY ciudad
HAVING COUNT(DISTINCT pais) = 1;

CREATE OR REPLACE TABLE ref_producto_categoria AS
SELECT producto, MIN(categoria) AS categoria
FROM validos
GROUP BY producto
HAVING COUNT(DISTINCT categoria) = 1;

CREATE OR REPLACE TABLE rechazados_limpios AS
WITH paso1 AS (
    SELECT
        TRIM(id_pedido) AS id_pedido,
        CASE
            WHEN regexp_matches(TRIM(fecha_pedido), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
                THEN TRY_CAST(TRIM(fecha_pedido) AS DATE)
            ELSE CAST(try_strptime(TRIM(fecha_pedido), '%d/%m/%Y') AS DATE)
        END AS fecha_pedido,
        TRIM(id_cliente) AS id_cliente,
        LOWER(TRIM(email_cliente)) AS email_cliente,
        NULLIF(TRIM(pais), '') AS pais,
        TRIM(ciudad) AS ciudad,
        NULLIF(TRIM(categoria), '') AS categoria,
        TRIM(producto) AS producto,
        CAST(ABS(TRY_CAST(cantidad AS DOUBLE)) AS INTEGER) AS cantidad,
        TRY_CAST(
            CASE
                WHEN precio_unitario LIKE '%,%'
                    THEN REPLACE(REPLACE(precio_unitario, '.', ''), ',', '.')
                ELSE precio_unitario
            END AS DOUBLE
        ) AS precio_unitario,
        TRY_CAST(descuento_pct AS DOUBLE) AS descuento_pct,
        TRY_CAST(total AS DOUBLE) AS total,
        LOWER(TRIM(estado)) AS estado,
        LOWER(TRIM(medio_pago)) AS medio_pago
    FROM rechazados
),
paso2 AS (
    SELECT
        p.id_pedido,
        p.fecha_pedido,
        p.id_cliente,
        p.email_cliente,
        COALESCE(p.pais, rc.pais) AS pais,
        p.ciudad,
        COALESCE(p.categoria, rp.categoria) AS categoria,
        p.producto,
        p.cantidad,
        p.precio_unitario,
        p.descuento_pct,
        COALESCE(p.total, ROUND(p.cantidad * p.precio_unitario * (1 - p.descuento_pct / 100), 2)) AS total,
        p.estado,
        p.medio_pago
    FROM paso1 p
    LEFT JOIN ref_ciudad_pais rc ON p.ciudad = rc.ciudad
    LEFT JOIN ref_producto_categoria rp ON p.producto = rp.producto
)
SELECT *
FROM paso2
QUALIFY ROW_NUMBER() OVER (PARTITION BY id_pedido ORDER BY fecha_pedido) = 1;