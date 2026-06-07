# Hướng dẫn setup và chạy Data Warehouse

Tài liệu này tổng hợp toàn bộ hướng dẫn setup, chạy pipeline và kiểm tra kết quả cho project Data Warehouse trên PostgreSQL. Quy trình gồm 4 tầng chính:

- Tầng `staging`: tạo bảng thô, load dữ liệu CSV và kiểm tra chất lượng dữ liệu đầu vào.
- Tầng `dwh`: xây dựng Star Schema từ dữ liệu staging.
- Tầng `mart`: tổng hợp dữ liệu theo từng domain phân tích.
- Tầng `analysis_queries`: chạy các câu truy vấn phục vụ dashboard, báo cáo và kiểm định giả thuyết.

Thứ tự chạy khuyến nghị:

```text
Staging -> DWH -> Data Mart -> Analysis Queries
```

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

Chạy PostgreSQL container:

```bat
docker compose up -d
```

Kiểm tra hoặc truy cập trực tiếp PostgreSQL nếu cần:

```bat
docker exec -it dwh_postgres psql -U user -d dwh
```

Thoát khỏi PostgreSQL:

```sql
\q
```

## 3. Chạy toàn bộ pipeline

### 3.1. Chạy bằng CMD

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/create_staging_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/load_csv_to_staging.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/validate_staging_data.sql

docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/01_create_dwh_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/02_create_dimensions.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/03_create_facts.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/04_create_indexes.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/05_validate_dwh.sql

docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/01_create_mart_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/02_mart_sales.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/03_mart_logistics.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/04_mart_customer_satisfaction.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/05_mart_seller_performance.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/06_mart_product_category.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/07_mart_payment.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/08_mart_geolocation.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/09_create_mart_indexes.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/10_validate_marts.sql

docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/01_executive_overview.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/02_sales_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/03_logistics_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/04_customer_satisfaction_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/05_seller_performance_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/06_product_category_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/07_payment_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/08_geolocation_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/09_cross_domain_insights.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/10_hypothesis_queries.sql
```

### 3.2. Chạy bằng PowerShell

```powershell
Get-Content sql/01_staging/create_staging_schema.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/01_staging/load_csv_to_staging.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/01_staging/validate_staging_data.sql | docker exec -i dwh_postgres psql -U user -d dwh

Get-Content sql/02_dwh/01_create_dwh_schema.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/02_create_dimensions.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/03_create_facts.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/04_create_indexes.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/05_validate_dwh.sql | docker exec -i dwh_postgres psql -U user -d dwh

Get-Content sql/03_datamarts/01_create_mart_schema.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/02_mart_sales.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/03_mart_logistics.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/04_mart_customer_satisfaction.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/05_mart_seller_performance.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/06_mart_product_category.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/07_mart_payment.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/08_mart_geolocation.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/09_create_mart_indexes.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/10_validate_marts.sql | docker exec -i dwh_postgres psql -U user -d dwh

Get-Content sql/04_analysis_queries/01_executive_overview.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/02_sales_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/03_logistics_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/04_customer_satisfaction_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/05_seller_performance_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/06_product_category_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/07_payment_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/08_geolocation_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/09_cross_domain_insights.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/10_hypothesis_queries.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

## 4. Tầng Staging

Tầng staging dùng để tạo các bảng thô, load dữ liệu CSV vào PostgreSQL và kiểm tra chất lượng dữ liệu đầu vào trước khi build tầng DWH.

### 4.1. Chạy riêng tầng Staging bằng CMD

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/create_staging_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/load_csv_to_staging.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/validate_staging_data.sql
```

### 4.2. Chạy riêng tầng Staging bằng PowerShell

```powershell
Get-Content sql/01_staging/create_staging_schema.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/01_staging/load_csv_to_staging.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/01_staging/validate_staging_data.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

### 4.3. Ý nghĩa từng file

#### 4.3.1. `create_staging_schema.sql`

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

#### 4.3.2. `load_csv_to_staging.sql`

Load dữ liệu từ thư mục `data/raw/` vào các bảng trong schema `staging`.

#### 4.3.3. `validate_staging_data.sql`

Kiểm tra chất lượng dữ liệu sau khi load:

- Số dòng của từng bảng staging.
- Bảng nào bị rỗng.
- Đơn hàng nào thiếu customer.
- Order item nào thiếu product hoặc seller.
- Giá trị tiền âm ở `price`, `freight_value`, `payment_value`.
- Review score nằm ngoài khoảng 1-5.

### 4.4. Kiểm tra thủ công

Liệt kê các bảng staging:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "\dt staging.*"
```

Xem 10 dòng mẫu:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "SELECT * FROM staging.olist_orders LIMIT 10;"
```

### 4.5. Kết quả validate cần đạt

Sau khi chạy `validate_staging_data.sql`, cần kiểm tra:

- Phần `Row count by staging table`: mỗi bảng cần có số dòng lớn hơn 0.
- Phần `Empty staging tables`: không nên trả về dòng nào.
- Phần `Validation summary`: các dòng nên có `status = PASS` và `issue_count = 0`.

Nếu staging chưa pass validation, nên xử lý lỗi ở tầng staging trước khi chạy tầng DWH.

## 5. Tầng DWH

Tầng DWH được xây dựng từ dữ liệu đã nạp và kiểm tra trong schema `staging`. Thiết kế hiện tại dùng Star Schema để phục vụ các nhóm phân tích chính:

- Phân tích bán hàng.
- Phân tích vận chuyển.
- Phân tích mức độ hài lòng của khách hàng.
- Phân tích người bán và sản phẩm.
- Phân tích địa lý.

### 5.1. Điều kiện trước khi chạy

Cần chạy xong tầng staging trước. Trong kết quả kiểm tra staging, phần `Validation summary` nên có tất cả `status = PASS`.

### 5.2. Chạy riêng tầng DWH bằng CMD

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/01_create_dwh_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/02_create_dimensions.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/03_create_facts.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/04_create_indexes.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/05_validate_dwh.sql
```

### 5.3. Chạy riêng tầng DWH bằng PowerShell

```powershell
Get-Content sql/02_dwh/01_create_dwh_schema.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/02_create_dimensions.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/03_create_facts.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/04_create_indexes.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/02_dwh/05_validate_dwh.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

### 5.4. Ý nghĩa từng file

#### 5.4.1. `01_create_dwh_schema.sql`

Tạo schema `dwh` và reset các bảng DWH cũ.

File drop bảng fact trước, dimension sau vì fact có foreign key trỏ tới dimension.

Các bảng được drop gồm:

- Facts: `fact_reviews`, `fact_payments`, `fact_order_delivery`, `fact_order_item_sales`
- Dimensions: `dim_payment_type`, `dim_order_status`, `dim_geolocation`, `dim_product`, `dim_seller`, `dim_customer`, `dim_date`

#### 5.4.2. `02_create_dimensions.sql`

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

#### 5.4.3. `03_create_facts.sql`

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

#### 5.4.4. `04_create_indexes.sql`

Tạo index cho các cột thường dùng để join và lọc dữ liệu:

- Surrogate key trong fact: `customer_key`, `seller_key`, `product_key`, `order_status_key`, `payment_type_key`.
- Geolocation key trong fact: `customer_geolocation_key`, `seller_geolocation_key`.
- Business key: `order_id`, `customer_id`, `seller_id`, `product_id`.
- Cột ngày: `purchase_date_key`, `shipping_limit_date_key`, `delivered_customer_date_key`, `estimated_delivery_date_key`, `review_creation_date_key`.
- Cột lọc phân tích: `review_score`, `is_late`.

#### 5.4.5. `05_validate_dwh.sql`

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

### 5.5. Mô hình DWH

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

### 5.6. Vì sao dùng Star Schema

Project dùng Star Schema vì:

- Dễ query và dễ làm dashboard.
- Mỗi fact join trực tiếp tới dimension.
- Phù hợp với các câu hỏi phân tích doanh thu, giao hàng, thanh toán, review và địa lý.
- Dễ giải thích trong đồ án DWH hơn Snowflake Schema.

Snowflake Schema có thể giảm trùng lặp dữ liệu, nhưng query sẽ phức tạp hơn và chưa cần thiết cho phiên bản DWH hiện tại.

### 5.7. Kiểm tra thủ công

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

### 5.8. Kết quả validate cần đạt

Sau khi chạy `05_validate_dwh.sql`, cần kiểm tra:

- Phần `DWH row count by table`: mỗi bảng DWH cần có số dòng lớn hơn 0.
- Phần `Empty DWH tables`: không nên trả về dòng nào.
- Phần `Staging to DWH row count reconciliation`: `staging_count` và `dwh_count` nên khớp.
- Phần `Missing dimension keys in facts`: các dòng nên có `issue_count = 0`.
- Phần `Geolocation key coverage in facts`: dùng để theo dõi độ phủ địa lý; nếu có missing count thì cần xem lại zip code không khớp với bảng geolocation.
- Phần `DWH validation summary`: các dòng nên có `status = PASS`.

Lần validate trước khi bổ sung `dim_geolocation` cho thấy DWH đã pass các check cơ bản. Sau khi bổ sung `dim_geolocation`, cần chạy lại toàn bộ script DWH và `05_validate_dwh.sql` để cập nhật kết quả validate mới.

## 6. Tầng Data Mart

Tầng Data Mart được xây dựng từ các fact và dimension trong schema `dwh`. Các mart được tổng hợp theo từng domain để phục vụ dashboard, phân tích giả thuyết và khai thác insight kinh doanh.

Các domain phân tích chính:

- Phân tích bán hàng.
- Phân tích vận chuyển.
- Phân tích mức độ hài lòng của khách hàng.
- Phân tích hiệu quả người bán.
- Phân tích sản phẩm và danh mục.
- Phân tích thanh toán.
- Phân tích địa lý.

### 6.1. Điều kiện trước khi chạy

Cần chạy xong tầng staging và tầng DWH trước. Trong kết quả kiểm tra DWH, phần `DWH validation summary` nên có tất cả `status = PASS`.

### 6.2. Chạy riêng tầng Data Mart bằng CMD

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/01_create_mart_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/02_mart_sales.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/03_mart_logistics.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/04_mart_customer_satisfaction.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/05_mart_seller_performance.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/06_mart_product_category.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/07_mart_payment.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/08_mart_geolocation.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/09_create_mart_indexes.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/10_validate_marts.sql
```

### 6.3. Chạy riêng tầng Data Mart bằng PowerShell

```powershell
Get-Content sql/03_datamarts/01_create_mart_schema.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/02_mart_sales.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/03_mart_logistics.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/04_mart_customer_satisfaction.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/05_mart_seller_performance.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/06_mart_product_category.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/07_mart_payment.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/08_mart_geolocation.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/09_create_mart_indexes.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/03_datamarts/10_validate_marts.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

### 6.4. Ý nghĩa từng file

#### 6.4.1. `01_create_mart_schema.sql`

Tạo schema `mart` và reset các bảng Data Mart cũ.

Các bảng được drop gồm:

- `mart_sales`
- `mart_logistics`
- `mart_customer_satisfaction`
- `mart_seller_performance`
- `mart_product_category`
- `mart_payment`
- `mart_geolocation`

#### 6.4.2. `02_mart_sales.sql`

Tạo mart phục vụ phân tích bán hàng.

Grain: 1 dòng = 1 tháng + 1 product category + 1 customer state.

Các chỉ số chính:

- Tổng số đơn hàng.
- Tổng số item bán ra.
- Tổng số seller.
- Gross Merchandise Value.
- Tổng phí vận chuyển.
- Tổng doanh thu item.
- Giá item trung bình.
- Tỷ lệ freight trên GMV.
- Giá trị đơn hàng trung bình.

Mart này chỉ dùng `fact_order_item_sales` làm fact chính, không join với payment/review để tránh nhân bản doanh thu.

#### 6.4.3. `03_mart_logistics.sql`

Tạo mart phục vụ phân tích vận chuyển.

Grain: 1 dòng = 1 tháng + 1 customer state + 1 order status.

Các chỉ số chính:

- Tổng số đơn hàng.
- Số đơn đã giao.
- Số đơn giao trễ.
- Tỷ lệ giao trễ.
- Thời gian duyệt đơn trung bình.
- Thời gian giao hàng trung bình.
- Thời gian giao dự kiến trung bình.
- Số ngày delay trung bình.

Mart này chỉ dùng `fact_order_delivery` làm fact chính.

#### 6.4.4. `04_mart_customer_satisfaction.sql`

Tạo mart phục vụ phân tích trải nghiệm khách hàng.

Grain: 1 dòng = 1 tháng tạo review + 1 customer state + 1 trạng thái giao trễ.

Các chỉ số chính:

- Tổng số review.
- Review score trung bình.
- Số review thấp, trung lập, cao.
- Tỷ lệ review thấp.
- Tỷ lệ review cao.
- Tỷ lệ review có comment.
- Thời gian phản hồi review trung bình.
- Thời gian giao hàng và delay trung bình.

Mart này join `fact_reviews` với `fact_order_delivery` qua `order_id`. Vì `fact_order_delivery` có grain 1 dòng = 1 order, join này không nhân bản review.

#### 6.4.5. `05_mart_seller_performance.sql`

Tạo mart phục vụ phân tích hiệu quả người bán.

Grain: 1 dòng = 1 tháng + 1 seller + 1 product category.

Các chỉ số chính:

- Tổng số đơn hàng.
- Tổng số item bán ra.
- Tổng doanh thu.
- GMV.
- Tổng phí vận chuyển.
- Review score trung bình.
- Số review thấp.
- Tỷ lệ review thấp.
- Số đơn giao trễ.
- Tỷ lệ giao trễ.

Mart này không join trực tiếp nhiều fact ở cấp chi tiết. Script aggregate sales trước, tạo bridge distinct theo `order_id + seller + category + month`, rồi mới aggregate delivery/review theo cùng grain.

#### 6.4.6. `06_mart_product_category.sql`

Tạo mart phục vụ phân tích sản phẩm và danh mục.

Grain: 1 dòng = 1 tháng + 1 product category.

Các chỉ số chính:

- Tổng số đơn hàng.
- Tổng số item bán ra.
- Tổng số seller.
- GMV.
- Tổng phí vận chuyển.
- Tổng doanh thu.
- Giá bán trung bình.
- Phí vận chuyển trung bình.
- Khối lượng sản phẩm trung bình.
- Thể tích sản phẩm trung bình.
- Review score trung bình.
- Tỷ lệ review thấp.

Mart này aggregate sales theo tháng và category trước. Review được aggregate thông qua bridge distinct `order_id + category + month` để tránh nhân bản review trên item-level.

#### 6.4.7. `07_mart_payment.sql`

Tạo mart phục vụ phân tích thanh toán.

Grain: 1 dòng = 1 tháng + 1 payment type + 1 customer state.

Các chỉ số chính:

- Tổng số payment record.
- Tổng số đơn hàng.
- Tổng số khách hàng.
- Tổng giá trị thanh toán.
- Giá trị thanh toán trung bình.
- Số kỳ trả góp trung bình.
- Số kỳ trả góp lớn nhất.
- Số đơn thanh toán một lần.
- Số đơn trả góp.
- Tỷ lệ đơn trả góp.

Mart này chỉ dùng `fact_payments` làm fact chính, không join với sales để tránh nhân bản payment.

#### 6.4.8. `08_mart_geolocation.sql`

Tạo mart phục vụ phân tích địa lý.

Grain: 1 dòng = 1 tháng + 1 customer state + 1 customer city.

Các chỉ số chính:

- Tổng số đơn hàng.
- Tổng số khách hàng.
- Tổng doanh thu.
- GMV.
- Tổng phí vận chuyển.
- Giá trị đơn hàng trung bình.
- Số đơn đã giao.
- Số đơn giao trễ.
- Tỷ lệ giao trễ.
- Review score trung bình.
- Tỷ lệ review thấp.
- Tổng giá trị thanh toán.
- Giá trị thanh toán trung bình.

Mart này aggregate từng fact riêng theo cùng grain `month + customer_state + customer_city`, sau đó mới join các bảng aggregate lại để tránh fan-out.

#### 6.4.9. `09_create_mart_indexes.sql`

Tạo index cho các mart để hỗ trợ dashboard query nhanh hơn.

Các nhóm index chính:

- `(year, month)` cho các mart có thời gian.
- `customer_state` cho các mart phân tích theo khu vực.
- `product_category_name` cho các mart có category. Cột này đã là tên category tiếng Anh.
- `seller_id`, `seller_state` cho seller mart.
- `payment_type` cho payment mart.
- `(customer_state, customer_city)` cho geolocation mart.

#### 6.4.10. `10_validate_marts.sql`

Kiểm tra chất lượng toàn bộ tầng Data Mart sau khi build:

- Số dòng của từng mart.
- Mart nào bị rỗng.
- Null ở các field grain chính.
- Giá trị tiền âm.
- Tỷ lệ phần trăm nằm ngoài khoảng hợp lệ.
- Reconcile doanh thu với `dwh.fact_order_item_sales`.
- Reconcile payment với `dwh.fact_payments`.
- Validation summary cuối cùng.

### 6.5. Kiểm tra thủ công

Liệt kê bảng trong schema `mart`:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "\dt mart.*"
```

Xem cấu trúc một mart:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "\d+ mart.mart_sales"
```

Xem 10 dòng mẫu:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "SELECT * FROM mart.mart_sales LIMIT 10;"
```

Đếm số dòng và validate mart:

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/03_datamarts/10_validate_marts.sql
```

### 6.6. Kết quả validate cần đạt

Sau khi chạy `10_validate_marts.sql`, cần kiểm tra:

- Phần `Mart row count by table`: mỗi mart cần có số dòng lớn hơn 0.
- Phần `Empty mart tables`: không nên trả về dòng nào.
- Phần `Null grain fields`: các dòng nên có `issue_count = 0`.
- Phần `Negative value checks`: các dòng nên có `issue_count = 0`.
- Phần `Revenue and payment reconciliation`: các dòng nên có `status = PASS`.
- Phần `Percentage rate bounds`: các dòng nên có `issue_count = 0`.
- Phần `Mart validation summary`: các dòng nên có `status = PASS`.

Kết quả validate gần nhất:

```text
mart_sales                  11823 dòng
mart_logistics               1390 dòng
mart_customer_satisfaction    944 dòng
mart_seller_performance     24902 dòng
mart_product_category        1283 dòng
mart_payment                 1670 dòng
mart_geolocation            27258 dòng
```

Các check tổng hợp gần nhất đều `PASS`: bảng không rỗng, không null grain chính, không có giá trị âm, rate nằm trong khoảng hợp lệ và doanh thu/payment reconcile đúng với DWH gốc.

## 7. Tầng Analysis Queries

Tầng Analysis Queries gồm các câu lệnh `SELECT` phục vụ trực quan hóa dữ liệu, dashboard, báo cáo và phân tích insight kinh doanh. Các query ưu tiên lấy dữ liệu từ schema `mart`; chỉ một số query kiểm định giả thuyết dùng schema `dwh` vì cần dữ liệu chi tiết cấp order/item.

Các nhóm phân tích chính:

- Tổng quan điều hành.
- Phân tích bán hàng.
- Phân tích vận chuyển.
- Phân tích mức độ hài lòng của khách hàng.
- Phân tích hiệu quả người bán.
- Phân tích sản phẩm và danh mục.
- Phân tích thanh toán.
- Phân tích địa lý.
- Phân tích insight liên domain.
- Chuẩn bị dữ liệu kiểm định giả thuyết.

### 7.1. Điều kiện trước khi chạy

Cần chạy xong tầng staging, DWH và Data Mart trước. Trong kết quả kiểm tra Data Mart, phần `Mart validation summary` nên có tất cả `status = PASS`.

### 7.2. Chạy riêng Analysis Queries bằng CMD

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/01_executive_overview.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/02_sales_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/03_logistics_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/04_customer_satisfaction_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/05_seller_performance_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/06_product_category_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/07_payment_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/08_geolocation_analysis.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/09_cross_domain_insights.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/10_hypothesis_queries.sql
```

### 7.3. Chạy riêng Analysis Queries bằng PowerShell

```powershell
Get-Content sql/04_analysis_queries/01_executive_overview.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/02_sales_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/03_logistics_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/04_customer_satisfaction_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/05_seller_performance_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/06_product_category_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/07_payment_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/08_geolocation_analysis.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/09_cross_domain_insights.sql | docker exec -i dwh_postgres psql -U user -d dwh
Get-Content sql/04_analysis_queries/10_hypothesis_queries.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

### 7.4. Ý nghĩa từng file

#### 7.4.1. `01_executive_overview.sql`

Tạo các query tổng quan cho dashboard trang đầu tiên.

Nội dung chính:

- KPI tổng doanh thu.
- Tổng số đơn hàng và item bán ra.
- Tổng phí vận chuyển.
- Average Order Value.
- Tổng giá trị thanh toán.
- Review score trung bình.
- Tỷ lệ review thấp.
- Tỷ lệ giao trễ.
- Doanh thu và số đơn theo tháng.
- Bảng KPI summary theo năm/tháng.

Gợi ý biểu đồ:

- KPI cards.
- Line chart doanh thu theo tháng.
- Combo chart revenue/payment.
- Bảng tổng hợp KPI theo tháng.

#### 7.4.2. `02_sales_analysis.sql`

Tạo các query phân tích bán hàng.

Nội dung chính:

- Doanh thu theo tháng.
- GMV và freight theo thời gian.
- Top category theo doanh thu.
- Top bang theo doanh thu.
- Freight-to-GMV ratio theo category.
- Category doanh thu cao nhưng freight cao.
- Cơ cấu doanh thu theo category và khu vực.

Gợi ý biểu đồ:

- Line chart.
- Bar chart.
- Treemap.
- Pie chart.
- Ranking table.

#### 7.4.3. `03_logistics_analysis.sql`

Tạo các query phân tích vận chuyển và vận hành.

Nội dung chính:

- Tỷ lệ giao trễ tổng thể.
- Tỷ lệ giao trễ theo tháng.
- Tỷ lệ giao trễ theo bang.
- Delivered orders vs late orders.
- Average delivery days.
- Average delay days.
- Order status distribution.
- Khu vực doanh thu cao nhưng vận chuyển kém.

Gợi ý biểu đồ:

- KPI cards.
- Line chart.
- Bar chart.
- Map chart.
- Combo chart.

#### 7.4.4. `04_customer_satisfaction_analysis.sql`

Tạo các query phân tích trải nghiệm khách hàng qua review.

Nội dung chính:

- Review score trung bình.
- Tỷ lệ low/neutral/high review.
- Review score theo tháng.
- Review theo trạng thái giao trễ.
- Low review rate theo bang.
- Comment rate theo tháng.
- Khu vực nhiều đơn nhưng review thấp.
- So sánh đơn giao trễ và không giao trễ.

Gợi ý biểu đồ:

- KPI cards.
- Stacked bar.
- Line chart.
- State ranking.
- Late vs on-time comparison.

#### 7.4.5. `05_seller_performance_analysis.sql`

Tạo các query đánh giá hiệu quả seller.

Nội dung chính:

- Top seller theo doanh thu.
- Top seller theo số đơn.
- Seller doanh thu cao nhưng review thấp.
- Seller doanh thu cao nhưng late rate cao.
- Seller performance theo bang.
- Seller performance theo category.
- Seller có low review rate cao.
- Quality priority score.
- Best balanced sellers.

Gợi ý biểu đồ:

- Seller ranking table.
- Bar chart theo bang/category.
- Risk scatter plot.
- Priority list.

#### 7.4.6. `06_product_category_analysis.sql`

Tạo các query phân tích sản phẩm và danh mục.

Nội dung chính:

- Top category theo doanh thu.
- Top category theo số item.
- Category có review thấp.
- Category có freight cao.
- Category có sản phẩm nặng/cồng kềnh.
- Category doanh thu cao nhưng review thấp.
- Freight-to-revenue ratio.
- Category performance theo tháng.

Gợi ý biểu đồ:

- Category ranking bar chart.
- Treemap.
- Scatter plot freight vs review.
- Monthly category trend.
- Risk table.

#### 7.4.7. `07_payment_analysis.sql`

Tạo các query phân tích hành vi thanh toán.

Nội dung chính:

- Payment value theo payment type.
- Payment type share.
- Payment value theo tháng.
- Payment type trend theo tháng.
- Installment behavior.
- Installment rate theo bang.
- Bang có tổng thanh toán cao.
- So sánh credit card và payment type khác.

Gợi ý biểu đồ:

- KPI cards.
- Pie chart.
- Stacked bar.
- State ranking.
- Installment behavior table.

#### 7.4.8. `08_geolocation_analysis.sql`

Tạo các query phân tích thị trường theo khu vực.

Nội dung chính:

- Doanh thu theo bang.
- Doanh thu theo thành phố.
- Số đơn theo bang/thành phố.
- Average Order Value theo khu vực.
- Late rate theo khu vực.
- Review score theo khu vực.
- Khu vực doanh thu cao nhưng giao trễ cao.
- Khu vực doanh thu cao nhưng review thấp.
- Regional market score.

Gợi ý biểu đồ:

- Map chart.
- Regional ranking.
- City bar chart.
- Risk scatter plot.

#### 7.4.9. `09_cross_domain_insights.sql`

Tạo các query kết hợp nhiều domain để tìm insight sâu hơn.

Nội dung chính:

- Category doanh thu cao nhưng review thấp.
- Seller doanh thu cao nhưng late rate cao.
- Khu vực doanh thu cao nhưng delivery performance kém.
- Khu vực review thấp và late rate cao.
- Payment type có average payment value cao.
- Category vừa freight cao vừa low review cao.
- Seller/category cần ưu tiên cải thiện.
- Category risk score.

Gợi ý biểu đồ:

- Risk table.
- Quadrant chart.
- Scatter plot.
- Priority ranking.

#### 7.4.10. `10_hypothesis_queries.sql`

Tạo các dataset nền để kiểm định giả thuyết trong Python/Jupyter.

Nội dung chính:

- H1: Đơn giao trễ có review score thấp hơn đơn không giao trễ.
- H2: Delay càng lâu thì review score càng thấp.
- H3: Freight cao có làm tăng khả năng review thấp hay không.
- H4: Đơn trả góp nhiều kỳ có payment value cao hơn hay không.
- H5: Một số category có tỷ lệ review thấp cao hơn category khác.
- H6: Khu vực có delivery days dài hơn có low review rate cao hơn hay không.

Gợi ý sử dụng:

- Export kết quả query sang CSV.
- Kiểm định bằng Python/Jupyter.
- Dùng t-test, Mann-Whitney U, Spearman correlation, chi-square, logistic regression hoặc ANOVA tùy giả thuyết.

### 7.5. Kiểm tra thủ công

Chạy thử một file analysis query:

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/04_analysis_queries/01_executive_overview.sql
```

Chạy thử bằng PowerShell:

```powershell
Get-Content sql/04_analysis_queries/01_executive_overview.sql | docker exec -i dwh_postgres psql -U user -d dwh
```

Kiểm tra nhanh các mart nguồn:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "\dt mart.*"
```

Xem 10 dòng mẫu từ một mart:

```bat
docker exec -it dwh_postgres psql -U user -d dwh -c "SELECT * FROM mart.mart_sales LIMIT 10;"
```

### 7.6. Kết quả cần đạt

Tầng Analysis Queries không tạo bảng mới, nên không có validation summary riêng như staging/DWH/Data Mart. Kết quả cần đạt là:

- Mỗi file SQL chạy được bằng `psql` không lỗi cú pháp.
- Các query ưu tiên đọc từ schema `mart`.
- Các query hypothesis có thể đọc từ schema `dwh` khi cần dữ liệu chi tiết.
- Các chỉ số trung bình từ mart aggregate dùng weighted average phù hợp.
- Không có query join raw fact khác grain gây nhân bản dữ liệu.
- Các query có thể copy trực tiếp sang Metabase, Superset hoặc Power BI.

Kết quả kiểm tra gần nhất: toàn bộ 10 file trong `sql/04_analysis_queries/` đã chạy qua PostgreSQL với `ON_ERROR_STOP=1` và không phát sinh lỗi.

## 8. Thứ tự dựng dashboard gợi ý

1. Executive Overview
2. Sales Performance
3. Logistics Operations
4. Customer Satisfaction
5. Seller Performance
6. Product & Category
7. Payment Behavior
8. Geolocation / Regional Market
9. Cross-domain Insight
10. Hypothesis Testing / Deep-dive Export

## 9. Checklist hoàn tất

Sau khi setup và chạy pipeline, cần kiểm tra các điểm sau:

- PostgreSQL container `dwh_postgres` đang chạy.
- Dữ liệu CSV đã nằm đúng trong `data/raw/`.
- Tầng staging đã load đủ bảng và pass validation.
- Tầng DWH đã tạo đủ dimension, fact và pass validation.
- Tầng Data Mart đã tạo đủ mart, reconcile đúng doanh thu/payment và pass validation.
- Tầng Analysis Queries chạy không lỗi cú pháp.
- Dashboard hoặc notebook phân tích ưu tiên dùng schema `mart`; chỉ dùng schema `dwh` khi cần dữ liệu chi tiết.
