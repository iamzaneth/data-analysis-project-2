# 🚀 Olist E-Commerce Analytics: ELT Pipeline & Hướng Dẫn Bàn Giao

Tài liệu này mô tả chi tiết kiến trúc hệ thống ELT (Extract - Load - Transform) được xây dựng cho dự án **Olist E-Commerce Analytics**, đồng thời cung cấp hướng dẫn triển khai và kết nối báo cáo dành cho Data Analyst, BI Developer và các thành viên tiếp nhận dự án.

---

# 🏗️ PHẦN 1: TỔNG QUAN KIẾN TRÚC ELT

Hệ thống được thiết kế theo mô hình **Modern Data Stack**, tự động hóa toàn bộ quá trình từ dữ liệu thô (Raw Data) đến Data Warehouse và Data Mart phục vụ phân tích kinh doanh.

## 1. Extract & Load (dlt)

### Công cụ

* `dlt` (Data Load Tool)
* Python

### Nhiệm vụ

Tự động đọc dữ liệu từ các file CSV nguồn của Olist, chuẩn hóa kiểu dữ liệu và nạp trực tiếp vào PostgreSQL tại schema:

```sql
staging
```

### Kết quả

Dữ liệu thô được lưu giữ nguyên trạng để:

* Phục vụ kiểm tra dữ liệu nguồn
* Hỗ trợ tái xử lý (reprocessing)
* Đảm bảo khả năng truy vết (data lineage)

---

## 2. Transform & Test (dbt)

### Công cụ

* dbt (Data Build Tool)
* PostgreSQL

### Tầng Data Warehouse (DWH)

Schema:

```sql
dwh
```

Dữ liệu từ staging được chuyển đổi thành mô hình đa chiều (Star Schema) gồm:

#### Dimension Tables

* dim_customer
* dim_seller
* dim_product
* dim_date
* dim_geolocation
* dim_order_status
* dim_payment_type

#### Fact Tables

* fact_order_item_sales
* fact_order_delivery
* fact_payments
* fact_reviews

### Tầng Data Mart

Schema:

```sql
mart
```

Dữ liệu được tổng hợp thành các bảng One-Big-Table phục vụ trực tiếp cho dashboard và báo cáo.

Ví dụ:

* Sales Performance
* Logistics Performance
* Customer Satisfaction
* Seller Performance
* Geographic Analysis
* Payment Analysis
* Executive Dashboard

### Data Quality Testing

Hệ thống triển khai hơn 100 bài kiểm thử dữ liệu:

#### Generic Tests

* not_null
* unique
* accepted_values
* relationships

#### Custom Tests

* Doanh thu không âm
* Số lượng đơn hàng hợp lệ
* Tỷ lệ phần trăm nằm trong khoảng 0–100%
* KPI không vượt ngưỡng nghiệp vụ

Mục tiêu:

* Phát hiện lỗi dữ liệu sớm
* Đảm bảo độ tin cậy của báo cáo
* Hạn chế sai lệch trong phân tích

---

## 3. Orchestration (Apache Airflow)

### Công cụ

Apache Airflow (chạy trên Docker)

### DAG chính

```text
olist_elt_pipeline
```

### Luồng xử lý

```text
Extract_Load (dlt)
        ↓
Transform DWH
        ↓
Test DWH
        ↓
Transform Marts
        ↓
Test Marts
```

### Vai trò

* Tự động hóa toàn bộ pipeline
* Theo dõi trạng thái thực thi
* Quản lý lỗi và retry
* Đảm bảo dữ liệu được cập nhật theo quy trình chuẩn

---

# 🤝 PHẦN 2: HƯỚNG DẪN KHỞI CHẠY HỆ THỐNG

Dành cho Data Analyst hoặc BI Developer cần dựng lại hệ thống trên máy tính cá nhân.

---

## Bước 1: Khởi động Docker

### Yêu cầu

Cài đặt:

* Docker Desktop

### Khởi động hệ thống

Mở Terminal tại thư mục gốc của dự án:

```bash
docker compose up -d
```

### Chức năng

Lệnh trên sẽ khởi chạy:

* PostgreSQL (Data Warehouse)
* Apache Airflow
* pgAdmin
* Các container phụ trợ

### Kiểm tra trạng thái

```bash
docker ps
```

Đảm bảo tất cả container đều ở trạng thái:

```text
Up (healthy)
```

---

## Bước 2: Chạy Pipeline bằng Airflow

### Truy cập Airflow

```text
http://localhost:8081
```

### Tài khoản đăng nhập

```text
Username: admin
Password: admin
```

### Thực hiện

1. Tìm DAG:

```text
olist_elt_pipeline
```

2. Chuyển trạng thái DAG sang:

```text
Unpause
```

3. Chọn:

```text
Trigger DAG
```

4. Mở tab:

```text
Graph
```

### Thành công

Khi toàn bộ task chuyển sang màu xanh lá:

```text
Success
```

thì:

* Staging đã được nạp dữ liệu
* DWH đã được tạo
* Data Mart đã được tạo
* Toàn bộ bài test đã pass

---

# 📊 BƯỚC 3: KẾT NỐI POWER BI

Để tránh xung đột với PostgreSQL cài trên Windows, hệ thống sử dụng cổng:

```text
5433
```

### Tạo kết nối PostgreSQL

Power BI Desktop:

```text
Get Data
→ PostgreSQL Database
```

### Thông tin kết nối

```text
Server: localhost:5433
Database: olist_db
```

### Chế độ tải dữ liệu

```text
Import
```

### Xác thực

```text
Username: olist_user
Password: olist_pass
```

### Chọn dữ liệu

Trong Navigator:

```text
olist_db
 └── mart
```

Chọn toàn bộ các bảng:

```text
mart_*
```

Sau đó nhấn:

```text
Load
```

### Lưu ý

Các bảng Mart đã được thiết kế theo mô hình:

```text
One Big Table
```

Do đó:

* Không cần tạo Relationship
* Không cần thiết kế Star Schema trong Power BI
* Có thể xây dựng Dashboard ngay

---

# 📈 BƯỚC 4: HƯỚNG DẪN XÂY DỰNG DASHBOARD

Các yêu cầu nghiệp vụ và KPI đã được Data Engineer chuẩn bị sẵn dưới dạng SQL.

### Thư mục tham khảo

```text
dbt_project/
└── target/
    └── compiled/
        └── olist_elt/
            └── analyses/
```

### Danh sách file

```text
01_executive_overview.sql
02_sales_analysis.sql
03_customer_analysis.sql
04_seller_analysis.sql
05_product_analysis.sql
06_logistics_analysis.sql
07_geographic_analysis.sql
08_payment_analysis.sql
09_customer_satisfaction.sql
10_hypothesis_queries.sql
```

---

## Cách sử dụng

### KPI và Visual

Các câu lệnh SQL trong thư mục analyses chính là bản thiết kế nghiệp vụ cho dashboard.

Ví dụ:

```sql
SELECT
    SUM(total_revenue) / SUM(total_orders) AS avg_order_value
FROM mart_sales;
```

Có thể chuyển thành Measure trong Power BI:

```DAX
Average Order Value =
DIVIDE(
    SUM(mart_sales[total_revenue]),
    SUM(mart_sales[total_orders])
)
```

---

## File đặc biệt

### 10_hypothesis_queries.sql

Mục đích:

* Phân tích chuyên sâu
* Kiểm định giả thuyết kinh doanh
* Hỗ trợ Data Science

Có thể:

1. Copy SQL
2. Chạy trên pgAdmin
3. Xuất dữ liệu ra CSV
4. Sử dụng Python/R để phân tích thống kê

---

# ✅ KẾT QUẢ CUỐI CÙNG

Sau khi hoàn tất các bước trên:

```text
CSV Raw Data
      ↓
dlt
      ↓
PostgreSQL (staging)
      ↓
dbt DWH
      ↓
dbt Mart
      ↓
Data Quality Tests
      ↓
Apache Airflow
      ↓
Power BI Dashboard
```

Hệ thống đã sẵn sàng phục vụ:

* Executive Dashboard
* Sales Analytics
* Customer Analytics
* Seller Analytics
* Logistics Analytics
* Customer Satisfaction Analytics
* Data Science & Hypothesis Testing
