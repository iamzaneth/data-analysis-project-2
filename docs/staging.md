# Huong dan chay tang staging

## 1. Chuan bi du lieu

Dat cac file CSV vao thu muc `data/raw/`:

```text
data/raw/olist_customers_dataset.csv
data/raw/olist_geolocation_dataset.csv
data/raw/olist_orders_dataset.csv
data/raw/olist_order_items_dataset.csv
data/raw/olist_order_payments_dataset.csv
data/raw/olist_order_reviews_dataset.csv
data/raw/olist_products_dataset.csv
data/raw/olist_sellers_dataset.csv
data/raw/product_category_name_translation.csv
```

## 2. Khoi dong Postgres bang Docker

```bat
docker compose up -d
```


## 3. Vao Postgres neu can kiem tra thu cong

```bat
docker exec -it dwh_postgres psql -U user -d dwh
```

Thoat khoi Postgres:

```sql
\q
```

## 4. Tao schema va table staging

Neu chay bang CMD:

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/create_staging_schema.sql
```

Neu chay bang PowerShell:

```powershell
Get-Content sql/01_staging/create_staging_schema.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

Kiem tra cac bang staging da duoc tao:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "\dt staging.*"
```

## 5. Load CSV vao staging

Neu chay bang CMD:

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/load_csv_to_staging.sql
```

Neu chay bang PowerShell:

```powershell
Get-Content sql/01_staging/load_csv_to_staging.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

## 6. Validate du lieu staging

Neu chay bang CMD:

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/validate_staging_data.sql
```

Neu chay bang PowerShell:

```powershell
Get-Content sql/01_staging/validate_staging_data.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

Ket qua can xem:

- Phan `Row count by staging table`: moi bang can co so dong lon hon 0.
- Phan `Empty staging tables`: neu khong hien dong nao thi khong co bang rong.
- Phan `Validation summary`: cac dong nen co `status = PASS` va `issue_count = 0`.

## 7. Luong chay day du bang CMD

```bat
docker compose up -d
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/create_staging_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/load_csv_to_staging.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/validate_staging_data.sql
```
