# Hướng dẫn chạy tầng Analysis Queries

Tầng Analysis Queries gồm các câu lệnh `SELECT` phục vụ trực quan hóa dữ liệu, dashboard, báo cáo và phân tích insight kinh doanh. Các query ưu tiên lấy dữ liệu từ schema `mart`; chỉ một số query kiểm định giả thuyết dùng schema `dwh` vì cần dữ liệu chi tiết cấp order/item.

Các nhóm phân tích chính:

- Tổng quan điều hành
- Phân tích bán hàng
- Phân tích vận chuyển
- Phân tích mức độ hài lòng của khách hàng
- Phân tích hiệu quả người bán
- Phân tích sản phẩm và danh mục
- Phân tích thanh toán
- Phân tích địa lý
- Phân tích insight liên domain
- Chuẩn bị dữ liệu kiểm định giả thuyết

## 1. Điều kiện trước khi chạy

Cần chạy xong tầng staging, DWH và Data Mart trước:

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
```

Trong kết quả kiểm tra Data Mart, phần `Mart validation summary` nên có tất cả `status = PASS`.

## 2. Khởi động PostgreSQL bằng Docker

```bat
docker compose up -d
```

## 3. Chạy Analysis Queries bằng CMD

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

## 4. Chạy Analysis Queries bằng PowerShell

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

## 5. Ý nghĩa từng file

### 5.1. `01_executive_overview.sql`

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

### 5.2. `02_sales_analysis.sql`

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

### 5.3. `03_logistics_analysis.sql`

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

### 5.4. `04_customer_satisfaction_analysis.sql`

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

### 5.5. `05_seller_performance_analysis.sql`

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

### 5.6. `06_product_category_analysis.sql`

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

### 5.7. `07_payment_analysis.sql`

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

### 5.8. `08_geolocation_analysis.sql`

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

### 5.9. `09_cross_domain_insights.sql`

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

### 5.10. `10_hypothesis_queries.sql`

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

## 6. Kiểm tra thủ công

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

## 7. Kết quả validate cần đạt

Tầng Analysis Queries không tạo bảng mới, nên không có validation summary riêng như staging/DWH/Data Mart. Kết quả cần đạt là:

- Mỗi file SQL chạy được bằng `psql` không lỗi cú pháp.
- Các query ưu tiên đọc từ schema `mart`.
- Các query hypothesis có thể đọc từ schema `dwh` khi cần dữ liệu chi tiết.
- Các chỉ số trung bình từ mart aggregate dùng weighted average phù hợp.
- Không có query join raw fact khác grain gây nhân bản dữ liệu.
- Các query có thể copy trực tiếp sang Metabase, Superset hoặc Power BI.

Kết quả kiểm tra gần nhất: toàn bộ 10 file trong `sql/04_analysis_queries/` đã chạy qua PostgreSQL với `ON_ERROR_STOP=1` và không phát sinh lỗi.

Thứ tự dựng dashboard gợi ý:

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
