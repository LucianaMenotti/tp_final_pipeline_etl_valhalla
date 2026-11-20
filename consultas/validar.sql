-- Etapa 3: validar los datos de raw_pedidos con 13 reglas.
-- Cada regla vale 1 si el registro falla y 0 si el registro cumple.


-- Paso 1: tabla con los datos originales mas las columnas numericas.
-- linea_csv es el numero de linea del registro dentro del CSV (la linea 1 es el encabezado).
-- TRY_CAST devuelve NULL si el texto no se puede pasar a numero.
CREATE OR REPLACE TABLE validacion_paso1_numeros AS
SELECT
    rowid + 2 AS linea_csv,
    id_pedido,
    fecha_pedido,
    id_cliente,
    email_cliente,
    pais,
    ciudad,
    categoria,
    producto,
    cantidad,
    precio_unitario,
    descuento_pct,
    total,
    estado,
    medio_pago,
    TRY_CAST(cantidad AS DOUBLE) AS cantidad_numero,
    TRY_CAST(precio_unitario AS DOUBLE) AS precio_numero,
    TRY_CAST(descuento_pct AS DOUBLE) AS descuento_numero,
    TRY_CAST(total AS DOUBLE) AS total_numero
FROM raw_pedidos;


-- Paso 2: para cada id_pedido, buscar la primera linea del CSV donde aparece.
-- Sirve para detectar los ids repetidos.
CREATE OR REPLACE TABLE validacion_paso2_primera_linea AS
SELECT
    id_pedido,
    MIN(linea_csv) AS primera_linea
FROM validacion_paso1_numeros
GROUP BY id_pedido;


-- Paso 3: aplicar las 13 reglas, una columna por regla.
CREATE OR REPLACE TABLE validacion AS
SELECT
    datos.linea_csv,
    datos.id_pedido,
    datos.fecha_pedido,
    datos.id_cliente,
    datos.email_cliente,
    datos.pais,
    datos.ciudad,
    datos.categoria,
    datos.producto,
    datos.cantidad,
    datos.precio_unitario,
    datos.descuento_pct,
    datos.total,
    datos.estado,
    datos.medio_pago,

    -- Regla 1: el id_pedido no puede estar vacio
    CASE
        WHEN datos.id_pedido IS NULL THEN 1
        WHEN TRIM(datos.id_pedido) = '' THEN 1
        ELSE 0
    END AS id_nulo,

    -- Regla 2: el id_pedido no puede estar repetido (se acepta solo la primera aparicion)
    CASE
        WHEN primeras.primera_linea IS NOT NULL AND datos.linea_csv > primeras.primera_linea THEN 1
        ELSE 0
    END AS id_duplicado,

    -- Regla 3: la fecha debe tener formato AAAA-MM-DD y ser una fecha que existe
    CASE
        WHEN datos.fecha_pedido IS NULL THEN 1
        WHEN LENGTH(datos.fecha_pedido) <> 10 THEN 1
        WHEN TRY_STRPTIME(datos.fecha_pedido, '%Y-%m-%d') IS NULL THEN 1
        ELSE 0
    END AS fecha_invalida,

    -- Regla 4: el email debe tener algo antes del @, algo despues y un punto, y no tener espacios
    CASE
        WHEN datos.email_cliente IS NULL THEN 1
        WHEN datos.email_cliente LIKE '% %' THEN 1
        WHEN datos.email_cliente NOT LIKE '%_@_%._%' THEN 1
        ELSE 0
    END AS email_invalido,

    -- Regla 5: el pais no puede estar vacio
    CASE
        WHEN datos.pais IS NULL THEN 1
        WHEN TRIM(datos.pais) = '' THEN 1
        ELSE 0
    END AS pais_nulo,

    -- Regla 6: la categoria no puede estar vacia
    CASE
        WHEN datos.categoria IS NULL THEN 1
        WHEN TRIM(datos.categoria) = '' THEN 1
        ELSE 0
    END AS categoria_nula,

    -- Regla 7: la cantidad debe ser un numero mayor que 0
    CASE
        WHEN datos.cantidad_numero IS NULL THEN 1
        WHEN datos.cantidad_numero <= 0 THEN 1
        ELSE 0
    END AS cantidad_no_positiva,

    -- Regla 8: el precio unitario debe ser un numero mayor que 0
    CASE
        WHEN datos.precio_numero IS NULL THEN 1
        WHEN datos.precio_numero <= 0 THEN 1
        ELSE 0
    END AS precio_invalido,

    -- Regla 9: el descuento debe ser un numero entre 0 y 100
    CASE
        WHEN datos.descuento_numero IS NULL THEN 1
        WHEN datos.descuento_numero < 0 THEN 1
        WHEN datos.descuento_numero > 100 THEN 1
        ELSE 0
    END AS descuento_fuera_de_rango,

    -- Regla 10: el total no puede estar vacio (ni ser un texto que no es numero)
    CASE
        WHEN datos.total_numero IS NULL THEN 1
        ELSE 0
    END AS total_nulo,

    -- Regla 11: el total debe ser igual a cantidad por precio por (1 - descuento / 100).
    -- Solo se controla cuando cantidad, precio y descuento son correctos,
    -- para no contar dos veces el mismo error.
    CASE
        WHEN datos.total_numero IS NULL THEN 0
        WHEN datos.cantidad_numero IS NULL THEN 0
        WHEN datos.cantidad_numero <= 0 THEN 0
        WHEN datos.precio_numero IS NULL THEN 0
        WHEN datos.precio_numero <= 0 THEN 0
        WHEN datos.descuento_numero IS NULL THEN 0
        WHEN datos.descuento_numero < 0 THEN 0
        WHEN datos.descuento_numero > 100 THEN 0
        WHEN ABS(datos.total_numero - datos.cantidad_numero * datos.precio_numero * (1 - datos.descuento_numero / 100)) > 0.01 THEN 1
        ELSE 0
    END AS total_inconsistente,

    -- Regla 12: el estado debe ser entregado, enviado, pendiente o cancelado (en minuscula)
    CASE
        WHEN datos.estado IS NULL THEN 1
        WHEN datos.estado IN ('entregado', 'enviado', 'pendiente', 'cancelado') THEN 0
        ELSE 1
    END AS estado_no_permitido,

    -- Regla 13: el medio de pago debe ser uno de los cuatro permitidos
    CASE
        WHEN datos.medio_pago IS NULL THEN 1
        WHEN datos.medio_pago IN ('tarjeta', 'transferencia', 'efectivo', 'billetera_virtual') THEN 0
        ELSE 1
    END AS medio_pago_no_permitido

FROM validacion_paso1_numeros AS datos
LEFT JOIN validacion_paso2_primera_linea AS primeras
    ON datos.id_pedido = primeras.id_pedido;


-- Paso 4: sumar cuantas reglas falla cada registro.
CREATE OR REPLACE TABLE validacion_paso4_total_de_fallas AS
SELECT
    linea_csv,
    id_nulo
    + id_duplicado
    + fecha_invalida
    + email_invalido
    + pais_nulo
    + categoria_nula
    + cantidad_no_positiva
    + precio_invalido
    + descuento_fuera_de_rango
    + total_nulo
    + total_inconsistente
    + estado_no_permitido
    + medio_pago_no_permitido AS reglas_falladas
FROM validacion;


-- Paso 5: validos son los registros que cumplen TODAS las reglas.
CREATE OR REPLACE TABLE validos AS
SELECT
    validacion.id_pedido,
    validacion.fecha_pedido,
    validacion.id_cliente,
    validacion.email_cliente,
    validacion.pais,
    validacion.ciudad,
    validacion.categoria,
    validacion.producto,
    validacion.cantidad,
    validacion.precio_unitario,
    validacion.descuento_pct,
    validacion.total,
    validacion.estado,
    validacion.medio_pago
FROM validacion
JOIN validacion_paso4_total_de_fallas AS fallas
    ON validacion.linea_csv = fallas.linea_csv
WHERE fallas.reglas_falladas = 0;


-- Paso 6: rechazados son los registros que fallan al menos una regla.
-- motivo_rechazo junta los nombres de las reglas falladas separados por " | ".
-- Cada CASE sin ELSE devuelve NULL cuando la regla no falla, y concat_ws ignora los NULL.
CREATE OR REPLACE TABLE rechazados AS
SELECT
    validacion.linea_csv,
    validacion.id_pedido,
    validacion.fecha_pedido,
    validacion.id_cliente,
    validacion.email_cliente,
    validacion.pais,
    validacion.ciudad,
    validacion.categoria,
    validacion.producto,
    validacion.cantidad,
    validacion.precio_unitario,
    validacion.descuento_pct,
    validacion.total,
    validacion.estado,
    validacion.medio_pago,
    concat_ws(' | ',
        CASE WHEN validacion.id_nulo = 1 THEN 'id_nulo' END,
        CASE WHEN validacion.id_duplicado = 1 THEN 'id_duplicado' END,
        CASE WHEN validacion.fecha_invalida = 1 THEN 'fecha_invalida' END,
        CASE WHEN validacion.email_invalido = 1 THEN 'email_invalido' END,
        CASE WHEN validacion.pais_nulo = 1 THEN 'pais_nulo' END,
        CASE WHEN validacion.categoria_nula = 1 THEN 'categoria_nula' END,
        CASE WHEN validacion.cantidad_no_positiva = 1 THEN 'cantidad_no_positiva' END,
        CASE WHEN validacion.precio_invalido = 1 THEN 'precio_invalido' END,
        CASE WHEN validacion.descuento_fuera_de_rango = 1 THEN 'descuento_fuera_de_rango' END,
        CASE WHEN validacion.total_nulo = 1 THEN 'total_nulo' END,
        CASE WHEN validacion.total_inconsistente = 1 THEN 'total_inconsistente' END,
        CASE WHEN validacion.estado_no_permitido = 1 THEN 'estado_no_permitido' END,
        CASE WHEN validacion.medio_pago_no_permitido = 1 THEN 'medio_pago_no_permitido' END
    ) AS motivo_rechazo
FROM validacion
JOIN validacion_paso4_total_de_fallas AS fallas
    ON validacion.linea_csv = fallas.linea_csv
WHERE fallas.reglas_falladas > 0;


-- Paso 7: cuantos registros fallaron cada regla (un registro puede fallar varias).
CREATE OR REPLACE TABLE resumen_rechazos AS
SELECT 'id_nulo' AS regla, CAST(SUM(id_nulo) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'id_duplicado' AS regla, CAST(SUM(id_duplicado) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'fecha_invalida' AS regla, CAST(SUM(fecha_invalida) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'email_invalido' AS regla, CAST(SUM(email_invalido) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'pais_nulo' AS regla, CAST(SUM(pais_nulo) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'categoria_nula' AS regla, CAST(SUM(categoria_nula) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'cantidad_no_positiva' AS regla, CAST(SUM(cantidad_no_positiva) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'precio_invalido' AS regla, CAST(SUM(precio_invalido) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'descuento_fuera_de_rango' AS regla, CAST(SUM(descuento_fuera_de_rango) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'total_nulo' AS regla, CAST(SUM(total_nulo) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'total_inconsistente' AS regla, CAST(SUM(total_inconsistente) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'estado_no_permitido' AS regla, CAST(SUM(estado_no_permitido) AS INTEGER) AS cantidad FROM validacion
UNION ALL
SELECT 'medio_pago_no_permitido' AS regla, CAST(SUM(medio_pago_no_permitido) AS INTEGER) AS cantidad FROM validacion
ORDER BY cantidad DESC, regla;
