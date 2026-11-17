SELECT categoria, ROUND(SUM(total), 2) AS facturacion_total
FROM tabla_final
WHERE estado <> 'cancelado'
GROUP BY categoria
ORDER BY facturacion_total DESC
LIMIT 3;

SELECT
    strftime(fecha_pedido, '%Y-%m') AS mes,
    ROUND(SUM(total), 2) AS facturacion_total,
    ROUND(SUM(CASE WHEN estado <> 'cancelado' THEN total ELSE 0 END), 2) AS facturacion_sin_cancelados
FROM tabla_final
GROUP BY mes
ORDER BY mes;

SELECT pais, ROUND(AVG(total), 2) AS ticket_promedio
FROM tabla_final
GROUP BY pais
ORDER BY ticket_promedio DESC;

SELECT
    COUNT(*) AS total_pedidos,
    SUM(CASE WHEN estado = 'cancelado' THEN 1 ELSE 0 END) AS cancelados,
    ROUND(100.0 * SUM(CASE WHEN estado = 'cancelado' THEN 1 ELSE 0 END) / COUNT(*), 2) AS porcentaje_cancelados
FROM tabla_final;

SELECT medio_pago, COUNT(*) AS pedidos
FROM tabla_final
GROUP BY medio_pago
ORDER BY pedidos DESC;