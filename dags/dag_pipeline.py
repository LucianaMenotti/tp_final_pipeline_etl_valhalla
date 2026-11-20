import os
import sys
from pathlib import Path

import pendulum
from airflow.providers.standard.operators.python import PythonOperator
from airflow.sdk import DAG

# Carpeta del proyecto, donde estan pipeline.py, consultas/ y datos/.
# Si el DAG esta dentro del proyecto, se calcula sola a partir de este archivo.
# Si el DAG se copio a otra carpeta de Airflow, se indica con la variable PROYECTO_VALHALLA.
CARPETA_PROYECTO = os.environ.get("PROYECTO_VALHALLA")
if CARPETA_PROYECTO is None:
    CARPETA_PROYECTO = Path(__file__).resolve().parent.parent

# Se agrega la carpeta del proyecto a las rutas de Python para poder importar pipeline.py
sys.path.insert(0, str(CARPETA_PROYECTO))

import pipeline

with DAG(
    dag_id="pipeline_pedidos_valhalla",
    description="Pipeline ETL diario de pedidos de Valhalla S.A.",
    # Todos los dias a las 2:00 AM
    schedule="0 2 * * *",
    start_date=pendulum.datetime(2026, 11, 1, tz="America/Argentina/Buenos_Aires"),
    catchup=False,
    is_paused_upon_creation=False,
    tags=["valhalla", "etl"],
) as dag:

    # Una tarea por cada etapa del pipeline
    tarea_extraer_y_cargar = PythonOperator(
        task_id="extraer_y_cargar",
        python_callable=pipeline.extraer_y_cargar,
    )

    tarea_validar = PythonOperator(
        task_id="validar",
        python_callable=pipeline.validar,
    )

    tarea_limpiar = PythonOperator(
        task_id="limpiar",
        python_callable=pipeline.limpiar,
    )

    tarea_unir = PythonOperator(
        task_id="unir",
        python_callable=pipeline.unir,
    )

    tarea_responder_preguntas = PythonOperator(
        task_id="responder_preguntas",
        python_callable=pipeline.responder_preguntas,
    )

    # Orden de ejecucion: cada tarea espera a que termine la anterior
    tarea_extraer_y_cargar >> tarea_validar >> tarea_limpiar >> tarea_unir >> tarea_responder_preguntas
