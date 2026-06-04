# Huong dan chay tang DWH

Tang DWH duoc build tu du lieu da load va validate trong schema `staging`.
Thiet ke hien tai dung Star Schema de phuc vu cac mart phan tich:

- Sales Mart
- Logistics Mart
- Customer Satisfaction Mart
- Seller/Product Mart

## 1. Dieu kien truoc khi chay

Can chay xong tang staging truoc:

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/create_staging_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/load_csv_to_staging.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/validate_staging_data.sql
```

Trong file validate staging, phan `Validation summary` nen co tat ca `status = PASS`.

## 2. Thu tu chay DWH bang CMD

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/01_create_dwh_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/02_create_dimensions.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/03_create_facts.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/04_create_indexes.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/05_validate_dwh.sql
```

## 3. Thu tu chay DWH bang PowerShell

```powershell
Get-Content sql/02_dwh/01_create_dwh_schema.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/02_create_dimensions.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/03_create_facts.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/04_create_indexes.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/05_validate_dwh.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

## 4. Y nghia tung file

### 01_create_dwh_schema.sql

Tao schema `dwh` va reset cac bang DWH cu.

File drop bang fact truoc, dimension sau, vi fact co foreign key tro toi dimension.
Cac bang duoc drop gom:

- Facts: `fact_reviews`, `fact_payments`, `fact_order_delivery`, `fact_order_item_sales`
- Dimensions: `dim_payment_type`, `dim_order_status`, `dim_product`, `dim_seller`, `dim_customer`, `dim_date`

### 02_create_dimensions.sql

Tao va load cac dimension table tu staging:

- `dim_date`: bang ngay dung cho nhieu vai tro ngay khac nhau.
- `dim_customer`: thong tin khach hang.
- `dim_seller`: thong tin nguoi ban.
- `dim_product`: thong tin san pham, co them category tieng Anh tu `product_category_name_translation`.
- `dim_order_status`: danh muc trang thai don hang.
- `dim_payment_type`: danh muc loai thanh toan.

`dim_date` la role-playing dimension, duoc dung cho:

- ngay mua hang
- ngay duyet don
- ngay giao cho don vi van chuyen
- ngay giao cho khach
- ngay giao du kien
- ngay tao review
- ngay phan hoi review

### 03_create_facts.sql

Tao va load cac fact table tu staging ket hop voi dimension key:

- `fact_order_item_sales`: grain la 1 dong = 1 san pham trong 1 don hang.
- `fact_order_delivery`: grain la 1 dong = 1 don hang.
- `fact_payments`: grain la 1 dong = 1 payment record cua 1 don hang.
- `fact_reviews`: grain la 1 dong = 1 review cua 1 don hang.

File nay tinh them cac measure quan trong:

- `total_item_value = price + freight_value`
- `approval_hours`
- `carrier_handoff_days`
- `delivery_days`
- `estimated_delivery_days`
- `delay_days`
- `is_late`
- `review_response_days`
- `has_comment_title`
- `has_comment_message`

Fact review khong luu text dai nhu `review_comment_message`; chi luu bien boolean de biet review co comment hay khong.

### 04_create_indexes.sql

Tao index cho cac cot hay dung de join va filter:

- surrogate key trong fact: `customer_key`, `seller_key`, `product_key`, `order_status_key`, `payment_type_key`
- business key: `order_id`, `customer_id`, `seller_id`, `product_id`
- cac cot ngay: `purchase_date_key`, `shipping_limit_date_key`, `delivered_customer_date_key`, `estimated_delivery_date_key`, `review_creation_date_key`
- cot filter phan tich: `review_score`, `is_late`

### 05_validate_dwh.sql

Kiem tra chat luong tang DWH sau khi build:

- so dong tung bang DWH
- bang nao bi rong
- so dong staging va DWH co khop khong
- fact co thieu dimension key khong
- `price`, `freight_value`, `total_item_value`, `payment_value` co am khong
- `review_score` co nam ngoai khoang 1-5 khong
- ty le don giao tre
- tong doanh thu tu `fact_order_item_sales`

Neu phan `DWH validation summary` deu la `PASS`, tang DWH co ban da on.

## 5. Mo hinh DWH

### Dimensions

```text
dwh.dim_date
dwh.dim_customer
dwh.dim_seller
dwh.dim_product
dwh.dim_order_status
dwh.dim_payment_type
```

### Facts

```text
dwh.fact_order_item_sales
dwh.fact_order_delivery
dwh.fact_payments
dwh.fact_reviews
```

## 6. Vi sao dung Star Schema

Project dung Star Schema vi:

- de query va de lam dashboard
- moi fact join truc tiep toi dimension
- phu hop voi cac cau hoi phan tich doanh thu, giao hang, thanh toan, review
- de giai thich trong do an DWH hon Snowflake Schema

Snowflake Schema co the giam trung lap du lieu nhung query se phuc tap hon, khong can thiet cho ban DWH dau tien cua project nay.

## 7. Lenh kiem tra bang

Liet ke bang trong schema `dwh`:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "\dt dwh.*"
```

Xem cau truc bang:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "\d+ dwh.fact_order_item_sales"
```

Xem 10 dong mau:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "SELECT * FROM dwh.fact_order_item_sales LIMIT 10;"
```

Dem so dong cac bang DWH:

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/05_validate_dwh.sql
```

## 8. Ket qua validate hien tai

Lan validate gan nhat cho thay DWH da pass cac check co ban:

- khong co bang DWH rong
- row count staging va DWH khop
- khong thieu dimension key trong fact
- khong co gia tri tien am
- review score nam trong khoang 1-5
- ty le don giao tre khoang 8.11%
- tong `total_item_revenue` khoang 15,843,553.24

Day la moc DWH co ban da san sang de phat trien data mart hoac dashboard.
