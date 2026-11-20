# Informe del TP final: pipeline de pedidos de Valhalla S.A.

Alumnos: Menotti Luciana, Perlo Marcos.

## Resumen

El archivo pedidos.csv tiene 2575 filas. Las cargamos tal cual en la tabla raw_pedidos. Después las revisamos con 13 reglas de validación. 1475 filas cumplieron todas las reglas y 1100 fueron rechazadas. Corregimos las filas rechazadas y armamos la tabla tabla_final con 2500 pedidos, uno por cada id_pedido.

## 1. Problemas encontrados en los datos

- 75 filas tenían un id_pedido repetido. Eran copias exactas de otra fila.
- 257 fechas estaban escritas como DD/MM/AAAA y no como AAAA-MM-DD.
- 130 precios venían como texto con punto de miles y coma decimal, por ejemplo 210.000,00.
- 102 cantidades eran negativas.
- 205 estados estaban en mayúscula o tenían espacios, por ejemplo " ENTREGADO".
- 126 países, 101 categorías y 129 totales estaban vacíos.

## 2. Registros rechazados por cada regla

Una fila puede fallar más de una regla. Por eso la suma total de rechazos es 1125 y no 1100, ya que hay 25 filas con dos motivos distintos:

- fecha_invalida: 257 rechazos (la fecha no tiene el formato AAAA-MM-DD o no existe).
- estado_no_permitido: 205 rechazos (el estado no es entregado, enviado, pendiente o cancelado en minúscula).
- precio_invalido: 130 rechazos (el precio no es un número mayor que cero).
- total_nulo: 129 rechazos (el total está vacío).
- pais_nulo: 126 rechazos (el país está vacío).
- cantidad_no_positiva: 102 rechazos (la cantidad es negativa, cero o no es un número).
- categoria_nula: 101 rechazos (la categoría está vacía).
- id_duplicado: 75 rechazos (el id_pedido ya había aparecido antes).
- id_nulo, email_invalido, descuento_fuera_de_rango, total_inconsistente y medio_pago_no_permitido: 0 rechazos cada una (revisan id vacío, email mal escrito, descuento fuera de 0 a 100, total distinto de cantidad por precio con descuento y medio de pago no permitido).

## 3. Cómo se corrigieron los rechazados

- Las fechas con barras se pasaron a fecha.
- Los precios con coma se pasaron a número.
- Las cantidades negativas se pasaron a positivas, porque el total de esas filas ya estaba calculado con la cantidad positiva.
- Los estados se dejaron en minúscula y sin espacios.
- Los países y las categorías vacíos se completaron con la ciudad y el producto, usando los pedidos válidos.
- Los totales vacíos se calcularon como cantidad por precio por uno menos el descuento.
- De cada pedido repetido quedó una sola copia.

Al final, tabla_final tiene 2500 filas. 1475 vienen de los pedidos válidos y 1025 de los rechazados recuperados. No hay ids repetidos. La fecha es DATE, la cantidad es INTEGER y el precio, el descuento y el total son DOUBLE. Todos los montos están en pesos argentinos.

## 4. Respuestas a las preguntas de negocio

1. Las tres categorías que más facturan, sin contar los pedidos cancelados, son Electrónica (958.481.000), Hogar (156.808.170) e Indumentaria (144.170.950).
2. La facturación por mes se detalla a continuación (incluimos el total con todos los pedidos y el total sin los cancelados, porque el enunciado no aclara cuál usar):
   - Enero: en 2024 fue de 68.122.630 (58.077.209 sin cancelados) y en 2025 fue de 74.530.123 (63.870.693 sin cancelados).
   - Febrero: en 2024 fue de 52.515.553 (42.277.751 sin cancelados) y en 2025 fue de 52.762.155 (51.812.723 sin cancelados).
   - Marzo: en 2024 fue de 43.417.068 (33.894.131 sin cancelados) y en 2025 fue de 61.048.456 (55.442.106 sin cancelados).
   - Abril: en 2024 fue de 49.108.391 (43.168.104 sin cancelados) y en 2025 fue de 62.812.310 (53.749.221 sin cancelados).
   - Mayo: en 2024 fue de 64.922.321 (61.579.862 sin cancelados) y en 2025 fue de 65.440.859 (52.685.443 sin cancelados).
   - Junio: en 2024 fue de 54.582.671 (44.971.914 sin cancelados) y en 2025 fue de 55.460.143 (47.002.138 sin cancelados).
   - Julio: en 2024 fue de 43.218.154 (32.626.382 sin cancelados) y en 2025 fue de 78.262.777 (71.185.574 sin cancelados).
   - Agosto: en 2024 fue de 79.059.124 (76.077.788 sin cancelados) y en 2025 fue de 68.487.113 (62.642.510 sin cancelados).
   - Septiembre: en 2024 fue de 43.409.084 (41.954.300 sin cancelados) y en 2025 fue de 66.158.198 (56.948.709 sin cancelados).
   - Octubre: en 2024 fue de 71.863.384 (57.351.319 sin cancelados) y en 2025 fue de 88.809.942 (74.817.873 sin cancelados).
   - Noviembre: en 2024 fue de 73.526.497 (55.446.984 sin cancelados) y en 2025 fue de 75.654.423 (70.656.642 sin cancelados).
   - Diciembre: en 2024 fue de 59.229.506 (48.632.170 sin cancelados) y en 2025 fue de 52.705.010 (43.788.432 sin cancelados).
3. El ticket promedio por país es: Colombia 702.368, Chile 679.572, Argentina 601.528, Uruguay 587.782, Perú 568.194 y Paraguay 480.435.
4. Se canceló el 15,2 por ciento de los pedidos: 380 de 2500.
5. El medio de pago más usado es la transferencia, con 661 pedidos. Después van billetera virtual (636), tarjeta (619) y efectivo (584).

## 5. Airflow

El DAG se llama pipeline_pedidos_valhalla. Tiene cinco tareas que corren en orden: extraer y cargar, validar, limpiar, unir y responder las preguntas. Se ejecuta todos los días a las 2:00 AM, hora de Argentina. Lo probamos varias veces seguidas y no duplica datos.
