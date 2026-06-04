# Hướng dẫn chạy tầng staging

Tầng staging dùng để tạo các bảng thô, load dữ liệu CSV vào PostgreSQL và kiểm tra chất lượng dữ liệu đầu vào trước khi build tầng DWH.

## 1. Chuẩn bị dữ liệu

Đặt các file CSV vào thư mục `data/raw/`:

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

## 2. Khởi động PostgreSQL bằng Docker

```bat
docker compose up -d
```

## 3. Chạy staging bằng CMD

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/create_staging_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/load_csv_to_staging.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/validate_staging_data.sql
```

## 4. Chạy staging bằng PowerShell

```powershell
Get-Content sql/01_staging/create_staging_schema.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/01_staging/load_csv_to_staging.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/01_staging/validate_staging_data.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

## 5. Ý nghĩa từng file

### 5.1. `create_staging_schema.sql`

Tạo schema `staging` và các bảng staging tương ứng với các file CSV nguồn:

- `olist_customers`
- `olist_geolocation`
- `olist_orders`
- `olist_order_items`
- `olist_order_payments`
- `olist_order_reviews`
- `olist_products`
- `olist_sellers`
- `product_category_name_translation`

### 5.2. `load_csv_to_staging.sql`

Load dữ liệu từ thư mục `data/raw/` vào các bảng trong schema `staging`.

### 5.3. `validate_staging_data.sql`

Kiểm tra chất lượng dữ liệu sau khi load:

- Số dòng của từng bảng staging.
- Bảng nào bị rỗng.
- Đơn hàng nào thiếu customer.
- Order item nào thiếu product hoặc seller.
- Giá trị tiền âm ở `price`, `freight_value`, `payment_value`.
- Review score nằm ngoài khoảng 1-5.

## 6. Kiểm tra thủ công

Vào PostgreSQL nếu cần kiểm tra trực tiếp:

```bat
docker exec -it dwh_postgres psql -U user -d dwh
```

Thoát khỏi PostgreSQL:

```sql
\q
```

Liệt kê các bảng staging:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "\dt staging.*"
```

Xem 10 dòng mẫu:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "SELECT * FROM staging.olist_orders LIMIT 10;"
```

## 7. Kết quả validate cần đạt

Sau khi chạy `validate_staging_data.sql`, cần kiểm tra:

- Phần `Row count by staging table`: mỗi bảng cần có số dòng lớn hơn 0.
- Phần `Empty staging tables`: không nên trả về dòng nào.
- Phần `Validation summary`: các dòng nên có `status = PASS` và `issue_count = 0`.

Nếu staging chưa pass validation, nên xử lý lỗi ở tầng staging trước khi chạy tầng DWH.
