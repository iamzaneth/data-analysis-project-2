# Ban thiet ke Dashboard Olist Mart

Dashboard nen di theo 7 domain, dung voi 7 bang data mart. Moi page tra loi mot cau hoi lon, dung it KPI va it visual de de doc, de thuyet trinh.

Ten bang, ten cot va ten measure giu nguyen tieng Anh vi do la field trong Power BI.

## Nguyen tac chung

1. Moi page chi dung mart cua domain do.
2. Uu tien keo measure tu bang `_Measures`.
3. Khong noi truc tiep mart-to-mart bang relationship vi grain khac nhau.
4. Moi page nen co 3-4 KPI va toi da 3 visual chinh.
5. Bar chart luon sort giam dan theo measure chinh.
6. Neu qua nhieu dong, dung filter Top 10 hoac Top 15.

Bo cuc chung:

```text
[Tieu de + 1 cau hoi phan tich]

[KPI 1] [KPI 2] [KPI 3] [KPI 4]

[Visual chinh rong]

[Visual phu]                 [Bang chi tiet hoac scatter]
```

## 1. Sales Performance - mart_sales

Story: How much is the marketplace selling, how is revenue growing, and which categories and states drive the business?

KPI:
- Total Revenue
- Total Orders
- Average Order Value
- Freight To GMV %

Visual 1 - Xu huong doanh thu:
- Loai visual: Line chart
- X-axis: `mart_sales[period_start]`
- Y-axis: `_Measures[Total Revenue]`
- Title: `Xu huong doanh thu`

Visual 2 - Category doanh thu cao:
- Loai visual: Clustered bar chart
- Y-axis: `mart_sales[product_category_name]`
- X-axis: `_Measures[Total Revenue]`
- Filter: Top 10 theo `_Measures[Total Revenue]`
- Title: `Top category theo doanh thu`

Visual 3 - Bang doanh thu cao:
- Loai visual: Clustered bar chart
- Y-axis: `mart_sales[customer_state]`
- X-axis: `_Measures[Total Revenue]`
- Filter: Top 10 theo `_Measures[Total Revenue]`
- Title: `Top bang theo doanh thu`

Cach doc insight:
- Neu doanh thu tang nhung Freight To GMV % cao, freight co the dang an mon tang truong.
- Category va bang co doanh thu cao la noi nen uu tien marketing, inventory va van hanh.

## 2. Logistics Operations - mart_logistics

Story: Is delivery performance stable, where are orders late, and when does late delivery become a risk?

KPI:
- Delivered Orders
- Late Orders
- Late Delivery Rate %
- Average Delivery Days

Visual 1 - Xu huong giao tre:
- Loai visual: Line chart
- X-axis: `mart_logistics[period_start]`
- Y-axis: `_Measures[Late Delivery Rate %]`
- Title: `Xu huong ty le giao tre`

Visual 2 - Bang co ty le giao tre cao:
- Loai visual: Clustered bar chart
- Y-axis: `mart_logistics[customer_state]`
- X-axis: `_Measures[Late Delivery Rate %]`
- Filter: Top 10 theo `_Measures[Late Delivery Rate %]`
- Title: `Bang co ty le giao tre cao`

Visual 3 - Trang thai don hang:
- Loai visual: Stacked column chart
- X-axis: `mart_logistics[order_status]`
- Y-axis: `mart_logistics[total_orders]`
- Title: `Phan bo trang thai don hang`

Cach doc insight:
- Bang co late rate cao la noi can xem lai carrier, route hoac lead time.
- Trang thai don hang giup phat hien backlog trong xu ly don.

## 3. Customer Satisfaction - mart_customer_satisfaction

Story: How do customers rate their experience, and does late delivery lead to worse reviews?

KPI:
- Total Reviews
- Average Review Score
- Low Review Rate %
- High Review Rate %

Visual 1 - Xu huong diem review:
- Loai visual: Line chart
- X-axis: `mart_customer_satisfaction[period_start]`
- Y-axis: `_Measures[Average Review Score]`
- Title: `Xu huong diem review trung binh`

Visual 2 - Review theo trang thai giao tre:
- Loai visual: Clustered column chart
- X-axis: `mart_customer_satisfaction[is_late]`
- Y-axis: `_Measures[Average Review Score]`
- Title: `Diem review: giao tre va khong giao tre`

Visual 3 - Bang co low review cao:
- Loai visual: Clustered bar chart
- Y-axis: `mart_customer_satisfaction[customer_state]`
- X-axis: `_Measures[Low Review Rate %]`
- Filter: Top 10 theo `_Measures[Low Review Rate %]`
- Title: `Bang co ty le review thap cao`

Cach doc insight:
- Neu `is_late = True` co score thap hon ro ret, delivery la driver quan trong cua satisfaction.
- Bang co low review cao can xem them logistics va seller quality.

## 4. Seller Performance - mart_seller_performance

Story: Which sellers drive revenue, and which sellers carry review or delivery risk?

KPI:
- Seller Revenue
- Seller Orders
- Seller Avg Review Score
- Seller Late Order Share %

Visual 1 - Bang xep hang seller:
- Loai visual: Table
- Columns:
  - `mart_seller_performance[seller_id]`
  - `mart_seller_performance[seller_state]`
  - `_Measures[Seller Revenue]`
  - `_Measures[Seller Orders]`
  - `_Measures[Seller Avg Review Score]`
  - `_Measures[Seller Late Order Share %]`
- Sort: Seller Revenue giam dan
- Filter: Top 20 seller theo Seller Revenue
- Title: `Top seller va tin hieu chat luong`

Visual 2 - Doanh thu theo bang seller:
- Loai visual: Clustered bar chart
- Y-axis: `mart_seller_performance[seller_state]`
- X-axis: `_Measures[Seller Revenue]`
- Title: `Doanh thu seller theo bang`

Visual 3 - Rui ro seller:
- Loai visual: Scatter chart
- X-axis: `_Measures[Seller Revenue]`
- Y-axis: `_Measures[Seller Low Review Rate %]`
- Size: `_Measures[Seller Orders]`
- Details: `mart_seller_performance[seller_id]`
- Title: `Doanh thu va rui ro review cua seller`

Cach doc insight:
- Seller doanh thu cao nhung low review cao la nhom can uu tien can thiep.
- Seller state cho biet cum nguon cung quan trong.

## 5. Product & Category - mart_product_category

Story: Which categories drive revenue, and which categories show freight or review quality problems?

KPI:
- Category Revenue
- Category Orders
- Category Avg Review Score
- Category Freight To Revenue %

Visual 1 - Xep hang category:
- Loai visual: Clustered bar chart
- Y-axis: `mart_product_category[product_category_name]`
- X-axis: `_Measures[Category Revenue]`
- Filter: Top 10 theo `_Measures[Category Revenue]`
- Title: `Top category theo doanh thu`

Visual 2 - Freight va review risk:
- Loai visual: Scatter chart
- X-axis: `_Measures[Category Freight To Revenue %]`
- Y-axis: `_Measures[Category Low Review Rate %]`
- Size: `_Measures[Category Revenue]`
- Details: `mart_product_category[product_category_name]`
- Title: `Freight burden va rui ro review`

Visual 3 - Chi tiet category:
- Loai visual: Table
- Columns:
  - `mart_product_category[product_category_name]`
  - `_Measures[Category Revenue]`
  - `_Measures[Category Orders]`
  - `_Measures[Category Avg Review Score]`
  - `_Measures[Category Freight To Revenue %]`
- Sort: Category Revenue giam dan

Cach doc insight:
- Category nam phia tren-phai cua scatter vua freight cao vua low review cao, can uu tien toi uu.

## 6. Payment Behavior - mart_payment

Story: How do customers pay, how does payment value change, and where is installment behavior important?

KPI:
- Total Payment Value
- Payment Orders
- Average Payment Per Order
- Installment Order Rate %

Visual 1 - Co cau thanh toan:
- Loai visual: Donut chart
- Legend: `mart_payment[payment_type]`
- Values: `_Measures[Total Payment Value]`
- Title: `Co cau gia tri thanh toan`

Visual 2 - Xu huong thanh toan:
- Loai visual: Line chart
- X-axis: `mart_payment[period_start]`
- Y-axis: `_Measures[Total Payment Value]`
- Title: `Xu huong gia tri thanh toan`

Visual 3 - Tra gop theo bang:
- Loai visual: Clustered bar chart
- Y-axis: `mart_payment[customer_state]`
- X-axis: `_Measures[Installment Order Rate %]`
- Filter: Top 10 theo `_Measures[Installment Order Rate %]`
- Title: `Ty le tra gop theo bang`

Cach doc insight:
- Payment type mix cho biet hanh vi thanh toan chinh.
- Bang co installment cao co the lien quan den order value va suc mua.

## 7. Geolocation Market - mart_geolocation

Story: Which regional markets are large, and which high-revenue markets still suffer from weak delivery?

KPI:
- Regional Revenue
- Regional Orders
- Regional AOV
- Regional Late Rate %

Visual 1 - Doanh thu theo bang:
- Loai visual: Filled map hoac Clustered bar chart
- Location/Y-axis: `mart_geolocation[customer_state]`
- Values/X-axis: `_Measures[Regional Revenue]`
- Title: `Doanh thu theo bang`

Visual 2 - Thanh pho doanh thu cao:
- Loai visual: Clustered bar chart
- Y-axis: `mart_geolocation[customer_city]`
- X-axis: `_Measures[Regional Revenue]`
- Filter: Top 15 theo `_Measures[Regional Revenue]`
- Title: `Top thanh pho theo doanh thu`

Visual 3 - Rui ro thi truong:
- Loai visual: Scatter chart
- X-axis: `_Measures[Regional Revenue]`
- Y-axis: `_Measures[Regional Late Rate %]`
- Size: `_Measures[Regional Orders]`
- Details: `mart_geolocation[customer_state]`
- Title: `Doanh thu va ty le giao tre theo bang`

Cach doc insight:
- Bang doanh thu cao nhung late rate cao la thi truong can uu tien logistics.
- Thanh pho top revenue la noi nen tap trung growth campaign.

## Thu tu page nen dung

1. Sales Performance
2. Logistics Operations
3. Customer Satisfaction
4. Seller Performance
5. Product & Category
6. Payment Behavior
7. Geolocation Market

Neu muon co page tong quan, tao them sau cung va chi dung 4 KPI tong. Khong bat buoc, vi 7 mart da dai dien 7 domain rieng.
