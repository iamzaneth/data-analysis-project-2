# Dashboard Olist Mart tren Power BI

Thu muc nay chua template Power BI cho 7 bang data mart trong schema `mart`.

## File can dung

- `Olist_Mart_Dashboard_FIXED.pbit`: file template moi nhat de mo bang Power BI Desktop.
- `Olist_Mart_Dashboard.pbix`: file ban tao sau khi mo template, refresh data va Save As.
- `Olist_Mart_Dashboard_PbixProj/`: source project dung de build lai template.
- `Olist_Mart_Dashboard.Report_Blueprint.md`: huong dan bo cuc dashboard theo 7 domain.
- `10_create_powerbi_insight_views.sql`: tuy chon, tao them view phan tich lien domain.

## Ket noi du lieu

Thong tin PostgreSQL theo `docker-compose.yml`:

- Server: `localhost:5433`
- Database: `olist_db`
- Schema: `mart`
- User: `olist_user`
- Password: `olist_pass`

7 bang mart can co trong Power BI:

- `mart_sales`
- `mart_logistics`
- `mart_customer_satisfaction`
- `mart_seller_performance`
- `mart_product_category`
- `mart_payment`
- `mart_geolocation`

## Tao file PBIX

1. Chay database:

```powershell
cd C:\Users\ACER\Documents\DA_2\data-analysis-project-2
docker compose up -d
```

2. Mo file:

```text
powerbi/Olist_Mart_Dashboard_FIXED.pbit
```

3. Khi Power BI hoi credential, nhap:

```text
User name: olist_user
Password: olist_pass
```

4. Refresh data.

5. Save As thanh:

```text
powerbi/Olist_Mart_Dashboard.pbix
```

## Dung dashboard nhu the nao

Dashboard nen gom 7 page, moi page ung voi 1 data mart va 1 domain:

1. Sales Performance - `mart_sales`
2. Logistics Operations - `mart_logistics`
3. Customer Satisfaction - `mart_customer_satisfaction`
4. Seller Performance - `mart_seller_performance`
5. Product & Category - `mart_product_category`
6. Payment Behavior - `mart_payment`
7. Geolocation Market - `mart_geolocation`

Lam theo file:

```text
powerbi/Olist_Mart_Dashboard.Report_Blueprint.md
```

## Luu y quan trong

- Uu tien keo measure tu bang `_Measures`.
- Khong keo truc tiep cac cot `avg_*` hoac `*_rate_pct` neu da co measure tuong ung.
- Khong noi truc tiep mart-to-mart bang relationship, vi moi mart co grain khac nhau.
- Moi page chi nen co 3-4 KPI va toi da 3 visual chinh.

## Build lai template

Khi sua source trong `Olist_Mart_Dashboard_PbixProj/`, build lai bang:

```powershell
C:\Tools\pbi-tools-core\pbi-tools.core.exe compile powerbi\Olist_Mart_Dashboard_PbixProj powerbi\Olist_Mart_Dashboard_FIXED.pbit PBIT True
```

## View phan tich lien domain tuy chon

Neu muon tao them cac view aggregate san cho phan tich lien domain:

```powershell
Get-Content powerbi/10_create_powerbi_insight_views.sql | docker exec -i data-analysis-project-2-postgres_olist-1 psql -U olist_user -d olist_db
```

Cac view duoc tao:

- `mart.pbi_category_risk`
- `mart.pbi_seller_risk`
- `mart.pbi_region_market_risk`
- `mart.pbi_payment_behavior`
