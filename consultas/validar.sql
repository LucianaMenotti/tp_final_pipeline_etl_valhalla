CREATE OR REPLACE TABLE validacion AS
WITH base AS (
    SELECT
        *,
        TRY_CAST(cantidad AS DOUBLE) AS cantidad_num,
        TRY_CAST(precio_unitario AS DOUBLE) AS precio_num,
        TRY_CAST(descuento_pct AS DOUBLE) AS descuento_num,
        TRY_CAST(total AS DOUBLE) AS total_num,
        ROW_NUMBER() OVER (PARTITION BY id_pedido ORDER BY rowid) AS orden_en_id
    FROM raw_pedidos
)
SELECT
    id_pedido, fecha_pedido, id_cliente, email_cliente, pais, ciudad,
    categoria, producto, cantidad, precio_unitario, descuento_pct, total,
    estado, medio_pago,
    CASE WHEN id_pedido IS NULL OR TRIM(id_pedido) = '' THEN 1 ELSE 0 END AS id_nulo,
    CASE WHEN id_pedido IS NOT NULL AND orden_en_id > 1 THEN 1 ELSE 0 END AS id_duplicado,
    CASE WHEN fecha_pedido IS NULL
              OR NOT regexp_matches(fecha_pedido, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
              OR TRY_CAST(fecha_pedido AS DATE) IS NULL
         THEN 1 ELSE 0 END AS fecha_invalida,
    CASE WHEN email_cliente IS NULL
              OR NOT regexp_matches(email_cliente, '^[^@ ]+@[^@ ]+[.][^@ ]+$')
         THEN 1 ELSE 0 END AS email_invalido,
    CASE WHEN pais IS NULL OR TRIM(pais) = '' THEN 1 ELSE 0 END AS pais_nulo,
    CASE WHEN categoria IS NULL OR TRIM(categoria) = '' THEN 1 ELSE 0 END AS categoria_nula,
    CASE WHEN cantidad_num IS NULL OR cantidad_num <= 0 THEN 1 ELSE 0 END AS cantidad_no_positiva,
    CASE WHEN precio_num IS NULL OR precio_num <= 0 THEN 1 ELSE 0 END AS precio_invalido,
    CASE WHEN descuento_num IS NULL OR descuento_num < 0 OR descuento_num > 100 THEN 1 ELSE 0 END AS descuento_fuera_de_rango,
    CASE WHEN total_num IS NULL THEN 1 ELSE 0 END AS total_nulo,
    CASE WHEN total_num IS NOT NULL AND cantidad_num > 0 AND precio_num > 0
              AND descuento_num >= 0 AND descuento_num <= 100
              AND ABS(total_num - cantidad_num * precio_num * (1 - descuento_num / 100)) > 0.01
         THEN 1 ELSE 0 END AS total_inconsistente,
    CASE WHEN estado IS NULL OR estado NOT IN ('entregado', 'enviado', 'pendiente', 'cancelado')
         THEN 1 ELSE 0 END AS estado_no_permitido,
    CASE WHEN medio_pago IS NULL OR medio_pago NOT IN ('tarjeta', 'transferencia', 'efectivo', 'billetera_virtual')
         THEN 1 ELSE 0 END AS medio_pago_no_permitido
FROM base;

CREATE OR REPLACE TABLE validos AS
SELECT
    id_pedido, fecha_pedido, id_cliente, email_cliente, pais, ciudad,
    categoria, producto, cantidad, precio_unitario, descuento_pct, total,
    estado, medio_pago
FROM validacion
WHERE id_nulo + id_duplicado + fecha_invalida + email_invalido + pais_nulo
    + categoria_nula + cantidad_no_positiva + precio_invalido
    + descuento_fuera_de_rango + total_nulo + total_inconsistente
    + estado_no_permitido + medio_pago_no_permitido = 0;

CREATE OR REPLACE TABLE rechazados AS
SELECT
    id_pedido, fecha_pedido, id_cliente, email_cliente, pais, ciudad,
    categoria, producto, cantidad, precio_unitario, descuento_pct, total,
    estado, medio_pago,
    concat_ws(' | ',
        CASE WHEN id_nulo = 1 THEN 'id_nulo' END,
        CASE WHEN id_duplicado = 1 THEN 'id_duplicado' END,
        CASE WHEN fecha_invalida = 1 THEN 'fecha_invalida' END,
        CASE WHEN email_invalido = 1 THEN 'email_invalido' END,
        CASE WHEN pais_nulo = 1 THEN 'pais_nulo' END,
        CASE WHEN categoria_nula = 1 THEN 'categoria_nula' END,
        CASE WHEN cantidad_no_positiva = 1 THEN 'cantidad_no_positiva' END,
        CASE WHEN precio_invalido = 1 THEN 'precio_invalido' END,
        CASE WHEN descuento_fuera_de_rango = 1 THEN 'descuento_fuera_de_rango' END,
        CASE WHEN total_nulo = 1 THEN 'total_nulo' END,
        CASE WHEN total_inconsistente = 1 THEN 'total_inconsistente' END,
        CASE WHEN estado_no_permitido = 1 THEN 'estado_no_permitido' END,
        CASE WHEN medio_pago_no_permitido = 1 THEN 'medio_pago_no_permitido' END
    ) AS motivo_rechazo
FROM validacion
WHERE id_nulo + id_duplicado + fecha_invalida + email_invalido + pais_nulo
    + categoria_nula + cantidad_no_positiva + precio_invalido
    + descuento_fuera_de_rango + total_nulo + total_inconsistente
    + estado_no_permitido + medio_pago_no_permitido > 0;

CREATE OR REPLACE TABLE resumen_rechazos AS
SELECT regla, COUNT(*) AS cantidad
FROM (
    SELECT UNNEST(string_split(motivo_rechazo, ' | ')) AS regla
    FROM rechazados
)
GROUP BY regla
ORDER BY cantidad DESC, regla;