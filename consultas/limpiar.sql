-- Etapa 4: limpiar rechazados usando validos como referencia para completar vacios.

CREATE OR REPLACE TABLE rechazados_limpios AS
WITH ref_ciudad_pais AS (
    SELECT ciudad, MIN(pais) AS pais
    FROM validos
    GROUP BY ciudad
    HAVING COUNT(DISTINCT pais) = 1
),
ref_producto_categoria AS (
    SELECT producto, MIN(categoria) AS categoria
    FROM validos
    GROUP BY producto
    HAVING COUNT(DISTINCT categoria) = 1
),
limpios AS (
    SELECT
        linea_csv,
        TRIM(id_pedido) AS id_pedido,
        CASE
            WHEN fecha_pedido LIKE '%/%' THEN CAST(TRY_STRPTIME(TRIM(fecha_pedido), '%d/%m/%Y') AS DATE)
            ELSE CAST(TRY_STRPTIME(TRIM(fecha_pedido), '%Y-%m-%d') AS DATE)
        END AS fecha_pedido,
        TRIM(id_cliente) AS id_cliente,
        LOWER(TRIM(email_cliente)) AS email_cliente,
        NULLIF(TRIM(pais), '') AS pais,
        TRIM(ciudad) AS ciudad,
        NULLIF(TRIM(categoria), '') AS categoria,
        TRIM(producto) AS producto,
        ABS(TRY_CAST(cantidad AS INTEGER)) AS cantidad,
        TRY_CAST(
            CASE
                WHEN precio_unitario LIKE '%,%' THEN REPLACE(REPLACE(precio_unitario, '.', ''), ',', '.')
                ELSE precio_unitario
            END AS DOUBLE
        ) AS precio_unitario,
        TRY_CAST(descuento_pct AS DOUBLE) AS descuento_pct,
        TRY_CAST(total AS DOUBLE) AS total,
        LOWER(TRIM(estado)) AS estado,
        LOWER(TRIM(medio_pago)) AS medio_pago
    FROM rechazados
)
SELECT
    d.id_pedido,
    d.fecha_pedido,
    d.id_cliente,
    d.email_cliente,
    COALESCE(d.pais, rp.pais) AS pais,
    d.ciudad,
    COALESCE(d.categoria, rc.categoria) AS categoria,
    d.producto,
    d.cantidad,
    d.precio_unitario,
    d.descuento_pct,
    COALESCE(d.total, ROUND(d.cantidad * d.precio_unitario * (1 - d.descuento_pct / 100), 2)) AS total,
    d.estado,
    d.medio_pago
FROM limpios AS d
LEFT JOIN ref_ciudad_pais AS rp ON d.ciudad = rp.ciudad
LEFT JOIN ref_producto_categoria AS rc ON d.producto = rc.producto
QUALIFY ROW_NUMBER() OVER (PARTITION BY d.id_pedido ORDER BY d.linea_csv) = 1;