# Hướng dẫn chạy tầng DWH

Tầng DWH được xây dựng từ dữ liệu đã nạp và kiểm tra trong schema `staging`. Thiết kế hiện tại dùng Star Schema để phục vụ các nhóm phân tích chính:

- Phân tích bán hàng
- Phân tích vận chuyển
- Phân tích mức độ hài lòng của khách hàng
- Phân tích người bán và sản phẩm
- Phân tích địa lý

## 1. Điều kiện trước khi chạy

Cần chạy xong tầng staging trước:

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/create_staging_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/load_csv_to_staging.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/validate_staging_data.sql
```

Trong kết quả kiểm tra staging, phần `Validation summary` nên có tất cả `status = PASS`.

## 2. Khởi động PostgreSQL bằng Docker

```bat
docker compose up -d
```

## 3. Chạy DWH bằng CMD

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/01_create_dwh_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/02_create_dimensions.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/03_create_facts.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/04_create_indexes.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/05_validate_dwh.sql
```

## 4. Chạy DWH bằng PowerShell

```powershell
Get-Content sql/02_dwh/01_create_dwh_schema.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/02_create_dimensions.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/03_create_facts.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/04_create_indexes.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/05_validate_dwh.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

## 5. Ý nghĩa từng file

### 5.1. `01_create_dwh_schema.sql`

Tạo schema `dwh` và reset các bảng DWH cũ.

File drop bảng fact trước, dimension sau vì fact có foreign key trỏ tới dimension.

Các bảng được drop gồm:

- Facts: `fact_reviews`, `fact_payments`, `fact_order_delivery`, `fact_order_item_sales`
- Dimensions: `dim_payment_type`, `dim_order_status`, `dim_geolocation`, `dim_product`, `dim_seller`, `dim_customer`, `dim_date`

### 5.2. `02_create_dimensions.sql`

Tạo và nạp các bảng dimension từ staging:

- `dim_date`: bảng ngày dùng cho nhiều vai trò ngày khác nhau.
- `dim_customer`: thông tin khách hàng.
- `dim_seller`: thông tin người bán.
- `dim_product`: thông tin sản phẩm; `product_category_name` được chuẩn hóa sang tên tiếng Anh từ `product_category_name_translation`. Tên category tiếng Bồ Đào Nha chỉ nằm ở staging/raw, không lưu trong DWH.
- `dim_geolocation`: thông tin địa lý theo `zip_code_prefix`, gồm city/state và tọa độ trung bình.
- `dim_order_status`: danh mục trạng thái đơn hàng.
- `dim_payment_type`: danh mục loại thanh toán.

`dim_date` là role-playing dimension, được dùng cho:

- Ngày mua hàng.
- Ngày duyệt đơn.
- Ngày giao cho đơn vị vận chuyển.
- Ngày giao cho khách.
- Ngày giao dự kiến.
- Ngày tạo review.
- Ngày phản hồi review.

### 5.3. `03_create_facts.sql`

Tạo và nạp các bảng fact từ staging, kết hợp với surrogate key từ dimension:

- `fact_order_item_sales`: grain là 1 dòng = 1 sản phẩm trong 1 đơn hàng.
- `fact_order_delivery`: grain là 1 dòng = 1 đơn hàng.
- `fact_payments`: grain là 1 dòng = 1 payment record của 1 đơn hàng.
- `fact_reviews`: grain là 1 dòng = 1 review của 1 đơn hàng.

Các chỉ số quan trọng được tính thêm:

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

Các fact có thêm khóa địa lý để phân tích theo vị trí:

- `customer_geolocation_key`: có trong `fact_order_item_sales`, `fact_order_delivery`, `fact_payments`, `fact_reviews`.
- `seller_geolocation_key`: có trong `fact_order_item_sales`.

`fact_reviews` không lưu text dài như `review_comment_message`; bảng này chỉ lưu biến boolean để biết review có title/comment hay không.

### 5.4. `04_create_indexes.sql`

Tạo index cho các cột thường dùng để join và lọc dữ liệu:

- Surrogate key trong fact: `customer_key`, `seller_key`, `product_key`, `order_status_key`, `payment_type_key`.
- Geolocation key trong fact: `customer_geolocation_key`, `seller_geolocation_key`.
- Business key: `order_id`, `customer_id`, `seller_id`, `product_id`.
- Cột ngày: `purchase_date_key`, `shipping_limit_date_key`, `delivered_customer_date_key`, `estimated_delivery_date_key`, `review_creation_date_key`.
- Cột lọc phân tích: `review_score`, `is_late`.

### 5.5. `05_validate_dwh.sql`

Kiểm tra chất lượng tầng DWH sau khi build:

- Số dòng của từng bảng DWH.
- Bảng nào bị rỗng.
- Số dòng staging và DWH có khớp không.
- Fact có thiếu dimension key quan trọng không.
- Số dòng fact thiếu geolocation key để theo dõi coverage địa lý.
- `price`, `freight_value`, `total_item_value`, `payment_value` có âm không.
- `review_score` có nằm ngoài khoảng 1-5 không.
- Tỷ lệ đơn giao trễ.
- Tổng doanh thu từ `fact_order_item_sales`.

### 5.6. Mô hình DWH

Dimensions:

```text
dwh.dim_date
dwh.dim_customer
dwh.dim_seller
dwh.dim_product
dwh.dim_geolocation
dwh.dim_order_status
dwh.dim_payment_type
```

Facts:

```text
dwh.fact_order_item_sales
dwh.fact_order_delivery
dwh.fact_payments
dwh.fact_reviews
```

### 5.7. Vì sao dùng Star Schema

Project dùng Star Schema vì:

- Dễ query và dễ làm dashboard.
- Mỗi fact join trực tiếp tới dimension.
- Phù hợp với các câu hỏi phân tích doanh thu, giao hàng, thanh toán, review và địa lý.
- Dễ giải thích trong đồ án DWH hơn Snowflake Schema.

Snowflake Schema có thể giảm trùng lặp dữ liệu, nhưng query sẽ phức tạp hơn và chưa cần thiết cho phiên bản DWH hiện tại.

## 6. Kiểm tra thủ công

Liệt kê bảng trong schema `dwh`:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "\dt dwh.*"
```

Xem cấu trúc bảng:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "\d+ dwh.fact_order_item_sales"
```

Xem 10 dòng mẫu:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "SELECT * FROM dwh.fact_order_item_sales LIMIT 10;"
```

Đếm số dòng và validate DWH:

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/05_validate_dwh.sql
```

## 7. Kết quả validate cần đạt

Sau khi chạy `05_validate_dwh.sql`, cần kiểm tra:

- Phần `DWH row count by table`: mỗi bảng DWH cần có số dòng lớn hơn 0.
- Phần `Empty DWH tables`: không nên trả về dòng nào.
- Phần `Staging to DWH row count reconciliation`: `staging_count` và `dwh_count` nên khớp.
- Phần `Missing dimension keys in facts`: các dòng nên có `issue_count = 0`.
- Phần `Geolocation key coverage in facts`: dùng để theo dõi độ phủ địa lý; nếu có missing count thì cần xem lại zip code không khớp với bảng geolocation.
- Phần `DWH validation summary`: các dòng nên có `status = PASS`.

Lần validate trước khi bổ sung `dim_geolocation` cho thấy DWH đã pass các check cơ bản. Sau khi bổ sung `dim_geolocation`, cần chạy lại toàn bộ script DWH và `05_validate_dwh.sql` để cập nhật kết quả validate mới.
