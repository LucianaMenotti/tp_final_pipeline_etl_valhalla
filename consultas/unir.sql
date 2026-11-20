-- Etapa 5: unir validos y rechazados_limpios en tabla_final.
-- Se pasan los tipos de dato con CAST: fechas como DATE, cantidad como INTEGER y montos como DOUBLE.
-- De rechazados_limpios solo se toman los id_pedido que no estan en validos,
-- asi no queda ningun id repetido (los ids repetidos ya tienen su copia valida).
CREATE OR REPLACE TABLE tabla_final AS
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

UNION ALL

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
FROM rechazados_limpios
WHERE id_pedido NOT IN (SELECT id_pedido FROM validos);
