# Informe del TP final: pipeline de pedidos de Valhalla S.A.

Para este trabajo armamos un pipeline que toma el archivo pedidos.csv, revisa los datos, arregla lo que se puede arreglar y deja una tabla final para responder las preguntas del negocio.

## Qué pasó con los datos

El archivo tiene 2575 filas. Las cargamos tal cual en la tabla raw_pedidos, todas como texto para no cambiar nada. Después las pasamos por 13 reglas. 1475 filas cumplieron todas y 1100 fueron rechazadas. Algunas filas fallaban en más de una regla, por eso la tabla de abajo suma más de 1100.

| Regla | Qué revisa | Rechazos |
|---|---|---|
| fecha_invalida | La fecha no está en formato AAAA-MM-DD o no existe | 257 |
| estado_no_permitido | El estado no es entregado, enviado, pendiente o cancelado en minúscula | 205 |
| precio_invalido | El precio no es un número (por ejemplo 210.000,00) | 130 |
| total_nulo | El total está vacío | 129 |
| pais_nulo | El país está vacío | 126 |
| cantidad_no_positiva | La cantidad es negativa, cero o no es un número | 102 |
| categoria_nula | La categoría está vacía | 101 |
| id_duplicado | El id_pedido ya había aparecido antes | 75 |
| id_nulo | El id_pedido está vacío | 0 |
| email_invalido | El email no tiene un formato válido | 0 |
| descuento_fuera_de_rango | El descuento no está entre 0 y 100 | 0 |
| total_inconsistente | El total no es igual a cantidad por precio por descuento | 0 |
| medio_pago_no_permitido | El medio de pago no es uno de los cuatro permitidos | 0 |

## Cómo limpié los rechazados

Estas fueron las correcciones que realizamos:

- Había fechas escritas como DD/MM/AAAA. Las pasamos a fecha.
- Había precios con coma, como 210.000,00. Los pasamos a número.
- Había cantidades negativas. Las pasamos a positivas, porque el total de esas filas ya estaba calculado con la cantidad positiva.
- Había estados en mayúscula y con espacios. Los dejamos en minúscula y sin espacios.
- Completamos los países y las categorías vacíos usando la ciudad y el producto.
- Calculamoss los totales vacíos con cantidad por precio por uno menos el descuento.
- De cada pedido repetido dejamos una sola copia.

Al final, la tabla tabla_final tiene 2500 filas, una por cada id_pedido. 1475 vienen de los válidos y 1025 de los rechazados que pude recuperar. Descaramos 75 copias repetidas. La fecha quedó como DATE, la cantidad como INTEGER y el precio, el descuento y el total como DOUBLE. Todos los montos están en pesos argentinos.

## Respuestas a las preguntas

1. Las tres categorías que más facturan, sin contar los pedidos cancelados, son Electrónica (958.481.000), Hogar (156.808.170) e Indumentaria (144.170.950).
2. La facturación por mes está en la tabla de abajo. Puse el total con todos los pedidos y el total sin los cancelados, porque el enunciado no dice cuál hay que usar.
3. El ticket promedio por país es: Colombia 702.368, Chile 679.572, Argentina 601.528, Uruguay 587.782, Perú 568.194 y Paraguay 480.435.
4. Se canceló el 15,2 por ciento de los pedidos: 380 de 2500.
5. El medio de pago más usado es la transferencia, con 661 pedidos. Después van billetera virtual (636), tarjeta (619) y efectivo (584).

| Mes | 2024 total | 2024 sin cancelados | 2025 total | 2025 sin cancelados |
|---|---|---|---|---|
| Enero | 68.122.630 | 58.077.209 | 74.530.123 | 63.870.693 |
| Febrero | 52.515.553 | 42.277.751 | 52.762.155 | 51.812.723 |
| Marzo | 43.417.068 | 33.894.131 | 61.048.456 | 55.442.106 |
| Abril | 49.108.391 | 43.168.104 | 62.812.310 | 53.749.221 |
| Mayo | 64.922.321 | 61.579.862 | 65.440.859 | 52.685.443 |
| Junio | 54.582.671 | 44.971.914 | 55.460.143 | 47.002.138 |
| Julio | 43.218.154 | 32.626.382 | 78.262.777 | 71.185.574 |
| Agosto | 79.059.124 | 76.077.788 | 68.487.113 | 62.642.510 |
| Septiembre | 43.409.084 | 41.954.300 | 66.158.198 | 56.948.709 |
| Octubre | 71.863.384 | 57.351.319 | 88.809.942 | 74.817.873 |
| Noviembre | 73.526.497 | 55.446.984 | 75.654.423 | 70.656.642 |
| Diciembre | 59.229.506 | 48.632.170 | 52.705.010 | 43.788.432 |

## Airflow

Se armó un DAG de Airflow que se llama pipeline_pedidos_valhalla. Tiene cinco tareas que corren en orden: extraer y cargar, validar, limpiar, unir y responder las preguntas. Se ejecuta todos los días a las 2:00 AM, hora de Argentina. Se probó varias veces seguidas y no duplica datos.