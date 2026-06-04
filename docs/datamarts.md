# Hướng dẫn chạy tầng Data Mart

Tầng Data Mart được xây dựng từ các fact và dimension trong schema `dwh`. Các mart được tổng hợp theo từng domain để phục vụ dashboard, phân tích giả thuyết và khai thác insight kinh doanh.

Các domain phân tích chính:

- Phân tích bán hàng
- Phân tích vận chuyển
- Phân tích mức độ hài lòng của khách hàng
- Phân tích hiệu quả người bán
- Phân tích sản phẩm và danh mục
- Phân tích thanh toán
- Phân tích địa lý

## 1. Điều kiện trước khi chạy

Cần chạy xong tầng staging và tầng DWH trước:

```bat
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/create_staging_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/load_csv_to_staging.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/01_staging/validate_staging_data.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/01_create_dwh_schema.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/02_create_dimensions.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/03_create_facts.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/04_create_indexes.sql
docker exec -i dwh_postgres psql -U user -d dwh < sql/02_dwh/05_validate_dwh.sql
```

Trong kết quả kiểm tra DWH, phần `DWH validation summary` nên có tất cả `status = PASS`.

## 2. Khởi động PostgreSQL bằng Docker

```bat
docker compose up -d
```

## 3. Chạy Data Mart bằng CMD

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

## 4. Chạy Data Mart bằng PowerShell

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

## 5. Ý nghĩa từng file

### 5.1. `01_create_mart_schema.sql`

Tạo schema `mart` và reset các bảng Data Mart cũ.

Các bảng được drop gồm:

- `mart_sales`
- `mart_logistics`
- `mart_customer_satisfaction`
- `mart_seller_performance`
- `mart_product_category`
- `mart_payment`
- `mart_geolocation`

### 5.2. `02_mart_sales.sql`

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

### 5.3. `03_mart_logistics.sql`

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

### 5.4. `04_mart_customer_satisfaction.sql`

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

### 5.5. `05_mart_seller_performance.sql`

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

### 5.6. `06_mart_product_category.sql`

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

### 5.7. `07_mart_payment.sql`

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

### 5.8. `08_mart_geolocation.sql`

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

### 5.9. `09_create_mart_indexes.sql`

Tạo index cho các mart để hỗ trợ dashboard query nhanh hơn.

Các nhóm index chính:

- `(year, month)` cho các mart có thời gian.
- `customer_state` cho các mart phân tích theo khu vực.
- `product_category_name_english` cho các mart có category.
- `seller_id`, `seller_state` cho seller mart.
- `payment_type` cho payment mart.
- `(customer_state, customer_city)` cho geolocation mart.

### 5.10. `10_validate_marts.sql`

Kiểm tra chất lượng toàn bộ tầng Data Mart sau khi build:

- Số dòng của từng mart.
- Mart nào bị rỗng.
- Null ở các field grain chính.
- Giá trị tiền âm.
- Tỷ lệ phần trăm nằm ngoài khoảng hợp lệ.
- Reconcile doanh thu với `dwh.fact_order_item_sales`.
- Reconcile payment với `dwh.fact_payments`.
- Validation summary cuối cùng.

## 6. Kiểm tra thủ công

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

## 7. Kết quả validate cần đạt

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
