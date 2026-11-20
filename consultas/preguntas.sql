-- Pregunta 1: las 3 categorias con mayor facturacion total, sin contar los pedidos cancelados
SELECT
    categoria,
    ROUND(SUM(total), 2) AS facturacion_total
FROM tabla_final
WHERE estado <> 'cancelado'
GROUP BY categoria
ORDER BY facturacion_total DESC
LIMIT 3;

-- Pregunta 2a: facturacion por mes, con todos los pedidos
SELECT
    YEAR(fecha_pedido) AS anio,
    MONTH(fecha_pedido) AS mes,
    ROUND(SUM(total), 2) AS facturacion_total
FROM tabla_final
GROUP BY anio, mes
ORDER BY anio, mes;

-- Pregunta 2b: facturacion por mes, sin contar los pedidos cancelados
SELECT
    YEAR(fecha_pedido) AS anio,
    MONTH(fecha_pedido) AS mes,
    ROUND(SUM(total), 2) AS facturacion_sin_cancelados
FROM tabla_final
WHERE estado <> 'cancelado'
GROUP BY anio, mes
ORDER BY anio, mes;

-- Pregunta 3: ticket promedio (total promedio por pedido) por pais
SELECT
    pais,
    ROUND(AVG(total), 2) AS ticket_promedio
FROM tabla_final
GROUP BY pais
ORDER BY ticket_promedio DESC;

-- Pregunta 4: porcentaje de pedidos cancelados
WITH todos_los_pedidos AS (
    SELECT COUNT(*) AS cantidad
    FROM tabla_final
),
pedidos_cancelados AS (
    SELECT COUNT(*) AS cantidad
    FROM tabla_final
    WHERE estado = 'cancelado'
)
SELECT
    todos_los_pedidos.cantidad AS total_pedidos,
    pedidos_cancelados.cantidad AS cancelados,
    ROUND(100.0 * pedidos_cancelados.cantidad / todos_los_pedidos.cantidad, 2) AS porcentaje_cancelados
FROM todos_los_pedidos
CROSS JOIN pedidos_cancelados;

-- Pregunta 5: medio de pago mas usado y cantidad de pedidos (el primero de la lista es el mas usado)
SELECT
    medio_pago,
    COUNT(*) AS cantidad_de_pedidos
FROM tabla_final
GROUP BY medio_pago
ORDER BY cantidad_de_pedidos DESC;
