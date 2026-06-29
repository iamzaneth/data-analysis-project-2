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

# 🗄️ BƯỚC 3: KẾT NỐI VÀ KIỂM TRA DỮ LIỆU BẰNG PGADMIN

Sau khi DAG `olist_elt_pipeline` chạy thành công, bạn có thể sử dụng pgAdmin để kiểm tra dữ liệu trong PostgreSQL trước khi kết nối Power BI.

## Truy cập pgAdmin

Mở trình duyệt:

```text
http://localhost:5050
```

### Tài khoản đăng nhập

```text
Email: admin@admin.com
Password: admin
```

---

## Tạo kết nối đến Database Olist

### Bước 1

Tại menu bên trái:

```text
Servers
```

Chuột phải:

```text
Register
→ Server...
```

---

### Bước 2

Trong tab **General**:

```text
Name: Olist DWH
```

(Có thể đặt bất kỳ tên nào bạn muốn)

---

### Bước 3

Chuyển sang tab **Connection** và nhập:

| Trường               | Giá trị        |
| -------------------- | -------------- |
| Host name/address    | postgres_olist |
| Port                 | 5432           |
| Maintenance database | olist_db       |
| Username             | olist_user     |
| Password             | olist_pass     |

> **Lưu ý quan trọng:** Không sử dụng `localhost`.
>
> pgAdmin đang chạy trong container Docker riêng nên `localhost` sẽ trỏ đến chính container pgAdmin chứ không phải PostgreSQL.
>
> Phải sử dụng:
>
> ```text
> postgres_olist
> ```
>
> vì đây là hostname của container PostgreSQL trong Docker Network.

Sau đó nhấn:

```text
Save
```

---

## Khám phá dữ liệu

Sau khi kết nối thành công, mở rộng cây thư mục:

```text
Servers
└── Olist DWH
    └── Databases
        └── olist_db
            └── Schemas
```

Bạn sẽ thấy các schema:

```text
staging
dwh
mart
```

---

## Kiểm tra dữ liệu Staging

Mở:

```text
Schemas
└── staging
    └── Tables
```

Bạn sẽ thấy các bảng dữ liệu nguồn của Olist, ví dụ:

```text
olist_customers
olist_orders
olist_order_items
olist_products
olist_sellers
olist_geolocation
olist_order_payments
olist_order_reviews
```

Để xem dữ liệu:

1. Chuột phải vào một bảng bất kỳ (ví dụ: `olist_customers`)
2. Chọn:

```text
View/Edit Data
→ All Rows
```

pgAdmin sẽ hiển thị toàn bộ dữ liệu đã được nạp từ nguồn CSV.

---

## Kiểm tra Data Warehouse

Mở:

```text
Schemas
└── dwh
    └── Tables
```

Bạn sẽ thấy các bảng Dimension và Fact:

### Dimension Tables

```text
dim_customer
dim_seller
dim_product
dim_date
dim_geolocation
dim_order_status
dim_payment_type
```

### Fact Tables

```text
fact_order_item_sales
fact_order_delivery
fact_payments
fact_reviews
```

---

## Kiểm tra Data Mart

Mở:

```text
Schemas
└── mart
    └── Tables
```

Đây là các bảng dữ liệu cuối cùng được thiết kế dành riêng cho Power BI.

Các bảng mart đã được:

* Tổng hợp dữ liệu
* Chuẩn hóa KPI
* Tối ưu hiệu năng truy vấn
* Thiết kế theo mô hình One-Big-Table

Do đó người dùng cuối chỉ cần kết nối trực tiếp các bảng này vào Power BI mà không cần tạo Relationship hoặc viết SQL bổ sung.

---

## Thực thi SQL Trực Tiếp

Để chạy truy vấn kiểm tra dữ liệu:

1. Chọn database:

```text
olist_db
```

2. Chọn:

```text
Tools
→ Query Tool
```

3. Ví dụ:

```sql
SELECT *
FROM mart.mart_sales
LIMIT 10;
```

4. Nhấn nút Execute (▶) để chạy truy vấn.

Đây là công cụ chính để kiểm tra dữ liệu trước khi xây dựng Dashboard hoặc thực hiện phân tích chuyên sâu.


# 📊 BƯỚC 4: KẾT NỐI POWER BI

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

# 📈 BƯỚC 5: HƯỚNG DẪN XÂY DỰNG DASHBOARD

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
