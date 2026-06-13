# scripts/dlt_csv_to_postgres.py
import dlt
import pandas as pd
import os

def load_all_csv_to_staging():
    # Tạo destination postgres với connection string đầy đủ
    pipeline = dlt.pipeline(
        pipeline_name='olist_staging',
        destination=dlt.destinations.postgres(
            credentials="postgresql://olist_user:olist_pass@postgres_olist:5432/olist_db"
        ),
        dataset_name='staging',   # schema staging
    )

    data_dir = "/opt/airflow/data/raw"
    csv_files = [f for f in os.listdir(data_dir) if f.endswith('.csv')]

    for csv_file in csv_files:
        # Tạo tên bảng: bỏ hậu tố _dataset nếu có
        table_name = os.path.splitext(csv_file)[0]
        if table_name.endswith('_dataset'):
            table_name = table_name.replace('_dataset', '')

        print(f"Loading {csv_file} into staging.{table_name}")
        df = pd.read_csv(os.path.join(data_dir, csv_file))
        # Thay NaN bằng None
        df = df.where(pd.notnull(df), None)

        # Chạy pipeline với write_disposition="replace" để ghi đè bảng
        pipeline.run(
            df.to_dict(orient='records'),
            table_name=table_name,
            write_disposition="replace"
        )
        print(f"     Loaded {table_name} with {len(df)} rows")

if __name__ == "__main__":
    load_all_csv_to_staging()