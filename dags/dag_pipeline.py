import os
import sys
from pathlib import Path

import pendulum
from airflow.providers.standard.operators.python import PythonOperator
from airflow.sdk import DAG

PROYECTO = Path(os.environ.get("PROYECTO_VALHALLA", Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(PROYECTO))

import pipeline

with DAG(
    dag_id="pipeline_pedidos_valhalla",
    description="Pipeline ETL diario de pedidos de Valhalla S.A.",
    schedule="0 2 * * *",
    start_date=pendulum.datetime(2026, 11, 1, tz="America/Argentina/Buenos_Aires"),
    catchup=False,
    is_paused_upon_creation=False,
    tags=["valhalla", "etl"],
) as dag:
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

    tarea_extraer_y_cargar >> tarea_validar >> tarea_limpiar >> tarea_unir >> tarea_responder_preguntas