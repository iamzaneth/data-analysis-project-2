# olist_airflow/dags/olist_elt_dag.py
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
import os

default_args = {
    'owner': 'hoang',
    'depends_on_past': False,
    'start_date': datetime(2026, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=2),
}

# Lấy toàn bộ biến môi trường hiện tại của Airflow worker và thêm thông tin DB cho dbt
dbt_env = os.environ.copy()
dbt_env.update({
    'DBT_HOST': 'postgres_olist',
    'DBT_PORT': '5432',
    'DBT_USER': 'olist_user',
    'DBT_PASSWORD': 'olist_pass',
    'DBT_DBNAME': 'olist_db',
})

with DAG(
    'olist_elt_pipeline',
    default_args=default_args,
    description='Olist Modern Data Stack Pipeline: dlt -> dbt (DWH) -> dbt (Marts)',
    schedule_interval='@daily', 
    catchup=False,
    tags=['olist', 'elt', 'dbt'],
) as dag:

    # 1. Khâu Extract & Load (dlt)
    extract_load_staging = BashOperator(
        task_id='extract_load_dlt',
        bash_command='python /opt/airflow/scripts/dlt_csv_to_postgres.py',
    )

    # 2. Khâu Transform DWH (Tạo các bảng Dim/Fact)
    # Lệnh deps chỉ cần chạy ở bước dbt đầu tiên để tải thư viện dbt_utils
    dbt_transform_dwh = BashOperator(
        task_id='dbt_transform_dwh',
        bash_command='cd /opt/airflow/dbt_project && dbt deps && dbt run --models dwh --profiles-dir .',
        env=dbt_env
    )

    # 3. Khâu Test DWH (Kiểm tra khóa ngoại, giá trị âm, null...)
    dbt_test_dwh = BashOperator(
        task_id='dbt_test_dwh',
        bash_command='cd /opt/airflow/dbt_project && dbt test --models dwh --profiles-dir .',
        env=dbt_env
    )

    # 4. Khâu Transform Marts (Tổng hợp số liệu báo cáo)
    dbt_transform_marts = BashOperator(
        task_id='dbt_transform_marts',
        bash_command='cd /opt/airflow/dbt_project && dbt run --models marts --profiles-dir .',
        env=dbt_env
    )

    # 5. Khâu Test Marts (Kiểm tra tỷ lệ 0-100%, doanh thu âm...)
    dbt_test_marts = BashOperator(
        task_id='dbt_test_marts',
        bash_command='cd /opt/airflow/dbt_project && dbt test --models marts --profiles-dir .',
        env=dbt_env
    )

    # Thiết lập chuỗi chạy nối tiếp (Linear Pipeline)
    (
        extract_load_staging 
        >> dbt_transform_dwh 
        >> dbt_test_dwh 
        >> dbt_transform_marts 
        >> dbt_test_marts
    )