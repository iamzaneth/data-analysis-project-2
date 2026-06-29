# Thiết kế Data Mart - Chi tiết các bảng phân tích

## Tổng quan

Tầng Data Mart được xây dựng trên schema `mart`, lấy dữ liệu đã chuẩn hóa từ tầng `dwh` để phục vụ các nhóm phân tích nghiệp vụ cụ thể. Khác với tầng DWH lưu dữ liệu ở mức chi tiết, Data Mart tổng hợp sẵn theo các lát cắt thường dùng như tháng, danh mục sản phẩm, bang/thành phố khách hàng, người bán, phương thức thanh toán và trạng thái giao hàng.

Mục tiêu chính của tầng Data Mart:

- **Giảm độ phức tạp truy vấn**: Người phân tích không cần join trực tiếp nhiều fact/dim ở tầng DWH.
- **Đảm bảo đúng hạt dữ liệu**: Các chỉ số được tổng hợp trước để tránh nhân bản dòng khi kết hợp sales, payment, delivery và review.
- **Phục vụ dashboard nhanh hơn**: Các bảng mart đã có sẵn KPI theo domain.
- **Tách rõ nghiệp vụ phân tích**: Mỗi mart tương ứng với một nhóm câu hỏi kinh doanh.

Danh sách Data Mart hiện tại:

| Data Mart | Nhóm nghiệp vụ | Hạt dữ liệu |
|---|---|---|
| `mart_sales` | Bán hàng / hiệu quả kinh doanh | 1 tháng mua hàng + 1 danh mục sản phẩm + 1 bang khách hàng |
| `mart_logistics` | Vận hành / giao hàng | 1 tháng mua hàng + 1 bang khách hàng + 1 trạng thái đơn hàng |
| `mart_customer_satisfaction` | Trải nghiệm khách hàng | 1 tháng tạo review + 1 bang khách hàng + 1 cờ giao trễ |
| `mart_seller_performance` | Marketplace / quản lý người bán | 1 tháng mua hàng + 1 người bán + 1 danh mục sản phẩm |
| `mart_product_category` | Sản phẩm / danh mục | 1 tháng mua hàng + 1 danh mục sản phẩm |
| `mart_payment` | Tài chính / hành vi thanh toán | 1 tháng mua hàng + 1 phương thức thanh toán + 1 bang khách hàng |
| `mart_geolocation` | Thị trường vùng miền / địa lý | 1 tháng + 1 bang khách hàng + 1 thành phố khách hàng |

Kiến trúc tổng quan:

```text
staging
   |
   v
dwh.dim_* + dwh.fact_*
   |
   v
mart_sales
mart_logistics
mart_customer_satisfaction
mart_seller_performance
mart_product_category
mart_payment
mart_geolocation
```

---

## 1. `mart_sales` - Phân tích bán hàng

**Nhóm nghiệp vụ**: Sales / Business Performance

**Ý nghĩa bảng**: Bảng tổng hợp hiệu quả bán hàng theo thời gian, danh mục sản phẩm và khu vực khách hàng. Đây là mart chính để theo dõi doanh thu, số đơn, số item bán ra, GMV, phí vận chuyển và giá trị đơn trung bình.

**Hạt dữ liệu**: 1 dòng = 1 tháng mua hàng + 1 danh mục sản phẩm + 1 bang khách hàng.

**Nguồn chính**:

- `dwh.fact_order_item_sales`
- `dwh.dim_date`
- `dwh.dim_product`
- `dwh.dim_customer`
- `dwh.dim_geolocation`

### 1.1 Ý nghĩa và cách tính các trường

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `year` | Năm mua hàng | `dim_date.year`, join qua `fact_order_item_sales.purchase_date_key` |
| `month` | Tháng mua hàng | `dim_date.month` |
| `month_name` | Tên tháng | `dim_date.month_name` |
| `product_category_name` | Danh mục sản phẩm | `COALESCE(dim_product.product_category_name, 'Unknown')` |
| `customer_state` | Bang/tỉnh của khách hàng | `COALESCE(dim_customer.customer_state, dim_geolocation.geolocation_state, 'Unknown')` |
| `total_orders` | Số đơn hàng duy nhất | `COUNT(DISTINCT order_id)` |
| `total_order_items` | Số dòng item đã bán | `COUNT(*)` |
| `total_sellers` | Số người bán có phát sinh bán hàng | `COUNT(DISTINCT seller_key)` |
| `gross_merchandise_value` | Tổng giá trị hàng hóa, chưa gồm phí vận chuyển | `ROUND(SUM(price), 2)` |
| `total_freight_value` | Tổng phí vận chuyển | `ROUND(SUM(freight_value), 2)` |
| `total_item_revenue` | Tổng doanh thu gồm giá hàng và phí vận chuyển | `ROUND(SUM(total_item_value), 2)` |
| `avg_item_price` | Giá bán trung bình của item | `ROUND(AVG(price), 2)` |
| `avg_freight_value` | Phí vận chuyển trung bình của item | `ROUND(AVG(freight_value), 2)` |
| `avg_item_revenue` | Doanh thu trung bình trên item | `ROUND(AVG(total_item_value), 2)` |
| `freight_to_gmv_pct` | Tỷ lệ phí vận chuyển so với GMV | `ROUND(100.0 * SUM(freight_value) / NULLIF(SUM(price), 0), 2)` |
| `avg_order_value` | Giá trị đơn hàng trung bình | `ROUND(SUM(total_item_value) / NULLIF(COUNT(DISTINCT order_id), 0), 2)` |

### 1.2 Câu hỏi phù hợp

- Doanh thu theo tháng tăng hay giảm?
- Danh mục sản phẩm nào đóng góp doanh thu cao nhất?
- Bang nào có giá trị đơn hàng trung bình cao?
- Phí vận chuyển đang chiếm bao nhiêu phần trăm so với GMV?

---

## 2. `mart_logistics` - Phân tích vận chuyển

**Nhóm nghiệp vụ**: Operations / Logistics

**Ý nghĩa bảng**: Bảng tổng hợp hiệu suất vận chuyển theo thời gian, khu vực khách hàng và trạng thái đơn hàng. Mart này dùng để theo dõi số đơn đã giao, số đơn giao trễ, tỷ lệ giao trễ, thời gian duyệt đơn, thời gian giao hàng và mức độ trễ.

**Hạt dữ liệu**: 1 dòng = 1 tháng mua hàng + 1 bang khách hàng + 1 trạng thái đơn hàng.

**Nguồn chính**:

- `dwh.fact_order_delivery`
- `dwh.dim_date`
- `dwh.dim_customer`
- `dwh.dim_order_status`
- `dwh.dim_geolocation`

### 2.1 Ý nghĩa và cách tính các trường

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `year` | Năm mua hàng | `dim_date.year`, join qua `fact_order_delivery.purchase_date_key` |
| `month` | Tháng mua hàng | `dim_date.month` |
| `month_name` | Tên tháng | `dim_date.month_name` |
| `customer_state` | Bang/tỉnh của khách hàng | `COALESCE(dim_customer.customer_state, dim_geolocation.geolocation_state, 'Unknown')` |
| `order_status` | Trạng thái đơn hàng | `COALESCE(dim_order_status.order_status, fact_order_delivery.order_status, 'Unknown')` |
| `total_orders` | Tổng số đơn hàng | `COUNT(DISTINCT order_id)` |
| `delivered_orders` | Số đơn đã có ngày giao đến khách | `COUNT(DISTINCT order_id) FILTER (WHERE order_delivered_customer_date IS NOT NULL)` |
| `late_orders` | Số đơn giao trễ | `COUNT(DISTINCT order_id) FILTER (WHERE is_late IS TRUE)` |
| `late_rate_pct` | Tỷ lệ giao trễ trên các đơn đã giao | `100.0 * late_orders / delivered_orders`, làm tròn 2 chữ số |
| `avg_approval_days` | Thời gian duyệt đơn trung bình, đơn vị ngày | `ROUND(AVG(approval_hours) / 24.0, 2)` |
| `avg_delivery_days` | Thời gian giao hàng thực tế trung bình | `ROUND(AVG(delivery_days), 2)` |
| `avg_estimated_delivery_days` | Thời gian giao hàng dự kiến trung bình | `ROUND(AVG(estimated_delivery_days), 2)` |
| `avg_delay_days` | Số ngày trễ trung bình; âm nghĩa là giao sớm | `ROUND(AVG(delay_days), 2)` |
| `avg_delay_days_for_late_orders` | Số ngày trễ trung bình chỉ tính đơn bị trễ | `ROUND(AVG(delay_days) FILTER (WHERE delay_days > 0), 2)` |
| `max_delay_days` | Số ngày trễ lớn nhất | `ROUND(MAX(delay_days), 2)` |

### 2.2 Câu hỏi phù hợp

- Bang nào có tỷ lệ giao trễ cao?
- Thời gian duyệt đơn trung bình là bao lâu?
- Trạng thái nào đang chiếm nhiều đơn chưa hoàn tất?
- Chênh lệch giữa thời gian giao dự kiến và thực tế ra sao?

---

## 3. `mart_customer_satisfaction` - Phân tích hài lòng khách hàng

**Nhóm nghiệp vụ**: Customer Experience

**Ý nghĩa bảng**: Bảng tổng hợp chất lượng review theo tháng tạo review, bang khách hàng và tình trạng giao trễ. Mart này giúp phân tích mối quan hệ giữa logistics và mức độ hài lòng của khách.

**Hạt dữ liệu**: 1 dòng = 1 tháng tạo review + 1 bang khách hàng + 1 giá trị `is_late`.

**Nguồn chính**:

- `dwh.fact_reviews`
- `dwh.fact_order_delivery`
- `dwh.dim_date`
- `dwh.dim_customer`
- `dwh.dim_geolocation`

`fact_order_delivery` là duy nhất theo `order_id`, nên join từ review sang delivery không làm nhân bản dòng review.

### 3.1 Ý nghĩa và cách tính các trường

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `year` | Năm tạo review | `dim_date.year`, join qua `fact_reviews.review_creation_date_key` |
| `month` | Tháng tạo review | `dim_date.month` |
| `month_name` | Tên tháng | `dim_date.month_name` |
| `customer_state` | Bang/tỉnh của khách hàng | `COALESCE(dim_customer.customer_state, dim_geolocation.geolocation_state, 'Unknown')` |
| `is_late` | Nhóm review theo đơn giao trễ hay không | `COALESCE(fact_order_delivery.is_late, FALSE)` |
| `total_reviews` | Tổng số review | `COUNT(*)` |
| `avg_review_score` | Điểm review trung bình | `ROUND(AVG(review_score), 2)` |
| `low_review_count` | Số review thấp | `COUNT(*) FILTER (WHERE review_score <= 2)` |
| `neutral_review_count` | Số review trung lập | `COUNT(*) FILTER (WHERE review_score = 3)` |
| `high_review_count` | Số review cao | `COUNT(*) FILTER (WHERE review_score >= 4)` |
| `low_review_rate_pct` | Tỷ lệ review thấp | `100.0 * low_review_count / total_reviews`, làm tròn 2 chữ số |
| `high_review_rate_pct` | Tỷ lệ review cao | `100.0 * high_review_count / total_reviews`, làm tròn 2 chữ số |
| `comment_title_count` | Số review có tiêu đề | `COUNT(*) FILTER (WHERE has_comment_title IS TRUE)` |
| `comment_message_count` | Số review có nội dung bình luận | `COUNT(*) FILTER (WHERE has_comment_message IS TRUE)` |
| `comment_message_rate_pct` | Tỷ lệ review có nội dung bình luận | `100.0 * comment_message_count / total_reviews`, làm tròn 2 chữ số |
| `avg_review_response_days` | Số ngày phản hồi review trung bình | `ROUND(AVG(review_response_days), 2)` |
| `avg_delivery_days` | Thời gian giao hàng thực tế trung bình của các đơn có review | `ROUND(AVG(fact_order_delivery.delivery_days), 2)` |
| `avg_delay_days` | Số ngày trễ trung bình của các đơn có review | `ROUND(AVG(fact_order_delivery.delay_days), 2)` |

### 3.2 Câu hỏi phù hợp

- Đơn giao trễ có điểm review thấp hơn không?
- Bang nào có tỷ lệ review thấp cao?
- Review có nội dung bình luận xuất hiện nhiều ở nhóm điểm nào?
- Thời gian phản hồi review trung bình là bao lâu?

---

## 4. `mart_seller_performance` - Phân tích hiệu suất người bán

**Nhóm nghiệp vụ**: Marketplace / Seller Management

**Ý nghĩa bảng**: Bảng tổng hợp hiệu suất từng người bán theo tháng và danh mục sản phẩm. Mart này kết hợp doanh thu, số lượng bán, phí vận chuyển, review và giao trễ để đánh giá seller.

**Hạt dữ liệu**: 1 dòng = 1 tháng mua hàng + 1 seller + 1 danh mục sản phẩm.

**Nguồn chính**:

- `dwh.fact_order_item_sales`
- `dwh.fact_order_delivery`
- `dwh.fact_reviews`
- `dwh.dim_seller`
- `dwh.dim_product`
- `dwh.dim_date`
- `dwh.dim_geolocation`

Lưu ý: Sales được tổng hợp trước ở cấp seller/category/month. Delivery và review được tính qua bridge `order_id` duy nhất theo seller-category-month để hạn chế nhân bản dữ liệu. Nếu một đơn có nhiều seller hoặc nhiều category, chỉ số review/delivery cấp đơn được phân bổ cho từng seller/category có mặt trong đơn đó.

### 4.1 Ý nghĩa và cách tính các trường

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `year` | Năm mua hàng | `dim_date.year`, join qua `fact_order_item_sales.purchase_date_key` |
| `month` | Tháng mua hàng | `dim_date.month` |
| `month_name` | Tên tháng | `dim_date.month_name` |
| `seller_id` | Mã người bán | `COALESCE(dim_seller.seller_id, fact_order_item_sales.seller_id, 'Unknown')` |
| `seller_state` | Bang/tỉnh của người bán | `COALESCE(dim_seller.seller_state, seller_geo.geolocation_state, 'Unknown')` |
| `seller_city` | Thành phố của người bán | `COALESCE(dim_seller.seller_city, seller_geo.geolocation_city, 'Unknown')` |
| `product_category_name` | Danh mục sản phẩm | `COALESCE(dim_product.product_category_name, 'Unknown')` |
| `total_orders` | Số đơn duy nhất seller có bán trong category | `COUNT(DISTINCT order_id)` |
| `total_items` | Số item seller đã bán | `COUNT(*)` |
| `total_revenue` | Tổng doanh thu gồm giá hàng và phí vận chuyển | `ROUND(SUM(total_item_value), 2)` |
| `gross_merchandise_value` | Tổng giá trị hàng hóa, chưa gồm phí vận chuyển | `ROUND(SUM(price), 2)` |
| `total_freight_value` | Tổng phí vận chuyển | `ROUND(SUM(freight_value), 2)` |
| `avg_item_price` | Giá item trung bình | `ROUND(AVG(price), 2)` |
| `avg_freight_value` | Phí vận chuyển trung bình | `ROUND(AVG(freight_value), 2)` |
| `avg_review_score` | Điểm review trung bình của các đơn liên quan | `ROUND(AVG(review_score), 2)` qua bridge `order_id` |
| `low_review_count` | Số review thấp | `COUNT(review_key) FILTER (WHERE review_score <= 2)`; nếu không có thì `0` |
| `low_review_rate_pct` | Tỷ lệ review thấp | `100.0 * low_review_count / total_reviews`, làm tròn 2 chữ số |
| `late_orders` | Số đơn giao trễ liên quan đến seller/category | `COUNT(DISTINCT order_id) FILTER (WHERE is_late IS TRUE)`; nếu không có thì `0` |
| `late_rate_pct` | Tỷ lệ giao trễ trên đơn đã giao | `100.0 * late_orders / delivered_orders`, làm tròn 2 chữ số |

### 4.2 Câu hỏi phù hợp

- Seller nào tạo doanh thu cao nhất theo từng danh mục?
- Seller nào có tỷ lệ review thấp hoặc giao trễ cao?
- Thành phố/bang seller nào hoạt động mạnh?
- Danh mục nào là đóng góp chính của từng seller?

---

## 5. `mart_product_category` - Phân tích danh mục sản phẩm

**Nhóm nghiệp vụ**: Product / Category Management

**Ý nghĩa bảng**: Bảng tổng hợp hiệu quả theo danh mục sản phẩm qua từng tháng. Mart này phục vụ phân tích doanh thu, số item bán ra, số seller tham gia, phí vận chuyển, đặc tính vật lý sản phẩm và chất lượng review theo category.

**Hạt dữ liệu**: 1 dòng = 1 tháng mua hàng + 1 danh mục sản phẩm.

**Nguồn chính**:

- `dwh.fact_order_item_sales`
- `dwh.fact_reviews`
- `dwh.dim_product`
- `dwh.dim_date`
- `dwh.dim_seller`

Lưu ý: Sales được tổng hợp trước ở cấp month/category. Review được join qua bridge `order_id` duy nhất theo month/category để tránh item-level rows làm nhân bản review. Nếu một đơn có nhiều category, review của đơn được phân bổ cho từng category có mặt trong đơn.

### 5.1 Ý nghĩa và cách tính các trường

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `year` | Năm mua hàng | `dim_date.year`, join qua `fact_order_item_sales.purchase_date_key` |
| `month` | Tháng mua hàng | `dim_date.month` |
| `month_name` | Tên tháng | `dim_date.month_name` |
| `product_category_name` | Danh mục sản phẩm | `COALESCE(dim_product.product_category_name, 'Unknown')` |
| `total_orders` | Số đơn duy nhất có category này | `COUNT(DISTINCT order_id)` |
| `total_items` | Số item đã bán trong category | `COUNT(*)` |
| `total_sellers` | Số seller bán category này | `COUNT(DISTINCT seller_key)` |
| `gross_merchandise_value` | Tổng giá trị hàng hóa, chưa gồm phí vận chuyển | `ROUND(SUM(price), 2)` |
| `total_freight_value` | Tổng phí vận chuyển | `ROUND(SUM(freight_value), 2)` |
| `total_revenue` | Tổng doanh thu gồm giá hàng và phí vận chuyển | `ROUND(SUM(total_item_value), 2)` |
| `avg_price` | Giá item trung bình | `ROUND(AVG(price), 2)` |
| `avg_freight_value` | Phí vận chuyển trung bình | `ROUND(AVG(freight_value), 2)` |
| `avg_product_weight_g` | Trọng lượng sản phẩm trung bình | `ROUND(AVG(product_weight_g), 2)` |
| `avg_product_volume_cm3` | Thể tích sản phẩm trung bình | `ROUND(AVG(product_volume_cm3), 2)` |
| `avg_review_score` | Điểm review trung bình của đơn có category này | `ROUND(AVG(review_score), 2)` qua bridge `order_id` |
| `low_review_count` | Số review thấp | `COUNT(review_key) FILTER (WHERE review_score <= 2)`; nếu không có thì `0` |
| `low_review_rate_pct` | Tỷ lệ review thấp | `100.0 * low_review_count / total_reviews`, làm tròn 2 chữ số |

### 5.2 Câu hỏi phù hợp

- Category nào có doanh thu và số lượng bán cao nhất?
- Category nào có phí vận chuyển trung bình cao?
- Sản phẩm nặng/cồng kềnh có ảnh hưởng đến freight không?
- Category nào có tỷ lệ review thấp cao?

---

## 6. `mart_payment` - Phân tích thanh toán

**Nhóm nghiệp vụ**: Finance / Payment Behavior

**Ý nghĩa bảng**: Bảng tổng hợp hành vi thanh toán theo thời gian, phương thức thanh toán và khu vực khách hàng. Mart này dùng để phân tích tổng giá trị thanh toán, số đơn, số khách, xu hướng trả góp và phân bổ phương thức thanh toán.

**Hạt dữ liệu**: 1 dòng = 1 tháng mua hàng + 1 phương thức thanh toán + 1 bang khách hàng.

**Nguồn chính**:

- `dwh.fact_payments`
- `dwh.dim_payment_type`
- `dwh.dim_date`
- `dwh.dim_customer`
- `dwh.dim_geolocation`

### 6.1 Ý nghĩa và cách tính các trường

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `year` | Năm mua hàng | `dim_date.year`, join qua `fact_payments.purchase_date_key` |
| `month` | Tháng mua hàng | `dim_date.month` |
| `month_name` | Tên tháng | `dim_date.month_name` |
| `payment_type` | Phương thức thanh toán | `COALESCE(dim_payment_type.payment_type, fact_payments.payment_type, 'Unknown')` |
| `customer_state` | Bang/tỉnh của khách hàng | `COALESCE(dim_customer.customer_state, dim_geolocation.geolocation_state, 'Unknown')` |
| `total_payment_records` | Tổng số bản ghi thanh toán | `COUNT(*)` |
| `total_orders` | Số đơn duy nhất có thanh toán | `COUNT(DISTINCT order_id)` |
| `total_customers` | Số khách hàng duy nhất | `COUNT(DISTINCT customer_key)` |
| `total_payment_value` | Tổng giá trị thanh toán | `ROUND(SUM(payment_value), 2)` |
| `avg_payment_value` | Giá trị thanh toán trung bình | `ROUND(AVG(payment_value), 2)` |
| `avg_installments` | Số kỳ trả góp trung bình | `ROUND(AVG(payment_installments), 2)` |
| `max_installments` | Số kỳ trả góp lớn nhất | `MAX(payment_installments)` |
| `single_payment_orders` | Số đơn thanh toán một lần | `COUNT(DISTINCT order_id) FILTER (WHERE COALESCE(payment_installments, 0) <= 1)` |
| `installment_orders` | Số đơn trả góp | `COUNT(DISTINCT order_id) FILTER (WHERE payment_installments > 1)` |
| `installment_order_rate_pct` | Tỷ lệ đơn trả góp | `100.0 * installment_orders / total_orders`, làm tròn 2 chữ số |

### 6.2 Câu hỏi phù hợp

- Phương thức thanh toán nào tạo giá trị thanh toán cao nhất?
- Tỷ lệ trả góp theo từng bang là bao nhiêu?
- Khách hàng ở khu vực nào có xu hướng trả góp nhiều hơn?
- Giá trị thanh toán trung bình khác nhau thế nào giữa các payment type?

---

## 7. `mart_geolocation` - Phân tích địa lý

**Nhóm nghiệp vụ**: Regional Market / Geo Analytics

**Ý nghĩa bảng**: Bảng tổng hợp đa domain theo vùng địa lý khách hàng. Mart này kết hợp sales, logistics, review và payment ở cấp tháng, bang và thành phố để phân tích thị trường vùng miền.

**Hạt dữ liệu**: 1 dòng = 1 tháng + 1 bang khách hàng + 1 thành phố khách hàng.

**Nguồn chính**:

- `dwh.fact_order_item_sales`
- `dwh.fact_order_delivery`
- `dwh.fact_reviews`
- `dwh.fact_payments`
- `dwh.dim_date`
- `dwh.dim_customer`
- `dwh.dim_geolocation`

Lưu ý: Mỗi nhóm chỉ số được tổng hợp độc lập ở cùng cấp month/state/city trước khi join lại. Thiết kế này tránh join trực tiếp raw sales với raw payment/review/delivery và làm sai số liệu do khác hạt dữ liệu.

### 7.1 Ý nghĩa và cách tính các trường

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `year` | Năm phân tích | Lấy từ khóa ngày tương ứng của từng fact; các aggregate được hợp nhất bằng bộ khóa year/month/state/city |
| `month` | Tháng phân tích | Lấy từ `dim_date.month` |
| `month_name` | Tên tháng | Lấy từ `dim_date.month_name` |
| `customer_state` | Bang/tỉnh của khách hàng | `COALESCE(dim_customer.customer_state, dim_geolocation.geolocation_state, 'Unknown')` |
| `customer_city` | Thành phố của khách hàng | `COALESCE(dim_customer.customer_city, dim_geolocation.geolocation_city, 'Unknown')` |
| `total_orders` | Số đơn duy nhất từ sales | `COUNT(DISTINCT order_id)` từ `fact_order_item_sales`; nếu không có thì `0` |
| `total_customers` | Số khách hàng duy nhất từ sales | `COUNT(DISTINCT customer_key)` từ `fact_order_item_sales`; nếu không có thì `0` |
| `total_revenue` | Tổng doanh thu từ sales | `ROUND(SUM(total_item_value), 2)`; nếu không có thì `0` |
| `gross_merchandise_value` | Tổng giá trị hàng hóa, chưa gồm phí vận chuyển | `ROUND(SUM(price), 2)`; nếu không có thì `0` |
| `total_freight_value` | Tổng phí vận chuyển | `ROUND(SUM(freight_value), 2)`; nếu không có thì `0` |
| `avg_order_value` | Giá trị đơn hàng trung bình | `ROUND(SUM(total_item_value) / NULLIF(COUNT(DISTINCT order_id), 0), 2)` |
| `delivered_orders` | Số đơn đã giao từ delivery | `COUNT(DISTINCT order_id) FILTER (WHERE order_delivered_customer_date IS NOT NULL)`; nếu không có thì `0` |
| `late_orders` | Số đơn giao trễ từ delivery | `COUNT(DISTINCT order_id) FILTER (WHERE is_late IS TRUE)`; nếu không có thì `0` |
| `late_rate_pct` | Tỷ lệ giao trễ | `100.0 * late_orders / delivered_orders`, làm tròn 2 chữ số |
| `avg_delivery_days` | Thời gian giao hàng trung bình | `ROUND(AVG(delivery_days), 2)` |
| `avg_delay_days` | Số ngày trễ trung bình | `ROUND(AVG(delay_days), 2)` |
| `avg_review_score` | Điểm review trung bình | `ROUND(AVG(review_score), 2)` từ `fact_reviews` |
| `low_review_rate_pct` | Tỷ lệ review thấp | `100.0 * COUNT(review_score <= 2) / COUNT(review)`, làm tròn 2 chữ số |
| `total_payment_value` | Tổng giá trị thanh toán | `ROUND(SUM(payment_value), 2)` từ `fact_payments`; nếu không có thì `0` |
| `avg_payment_value` | Giá trị thanh toán trung bình | `ROUND(AVG(payment_value), 2)` |

### 7.2 Câu hỏi phù hợp

- Bang/thành phố nào tạo doanh thu cao nhất?
- Khu vực nào có tỷ lệ giao trễ hoặc review thấp cao?
- Doanh thu, thanh toán và chất lượng giao hàng khác nhau thế nào theo vùng?
- Thành phố nào có giá trị đơn hàng trung bình tốt nhưng trải nghiệm khách hàng kém?

---

## 8. Quy ước và lưu ý khi dùng Data Mart

### 8.1 Quy ước thời gian

- Các mart sales, logistics, seller, product, payment dùng tháng mua hàng từ `purchase_date_key`.
- `mart_customer_satisfaction` dùng tháng tạo review từ `review_creation_date_key`.
- `mart_geolocation` hợp nhất nhiều nguồn; sales, delivery và payment dùng tháng mua hàng, review dùng tháng tạo review.

### 8.2 Quy ước xử lý giá trị thiếu

- Các trường phân loại như category, state, city, payment type, order status được gán `'Unknown'` khi không tìm được giá trị rõ ràng.
- Các chỉ số tổng như doanh thu, số đơn, số khách có thể được `COALESCE` về `0` ở các mart tổng hợp đa nguồn.
- Các tỷ lệ và giá trị trung bình giữ `NULL` khi mẫu số bằng `0` hoặc không có dữ liệu hợp lệ. Điều này giúp phân biệt giữa "không có dữ liệu" và "giá trị bằng 0".

### 8.3 Lưu ý về hạt dữ liệu

- Không nên cộng trực tiếp các chỉ số đã là tỷ lệ trung bình như `late_rate_pct`, `low_review_rate_pct`, `avg_review_score`. Khi cần tổng hợp lên cấp cao hơn, nên tính lại từ numerator/denominator gốc nếu có.
- `mart_seller_performance` và `mart_product_category` có cơ chế phân bổ review/delivery cấp đơn cho seller/category xuất hiện trong đơn. Khi một đơn có nhiều seller hoặc nhiều category, cùng một review có thể đóng góp vào nhiều nhóm phân tích.
- `mart_geolocation` được thiết kế để so sánh vùng miền trên nhiều domain, không phải để thay thế hoàn toàn từng mart chuyên biệt.

### 8.4 Gợi ý chọn mart theo nhu cầu

| Nhu cầu phân tích | Mart nên dùng |
|---|---|
| Doanh thu, GMV, AOV theo category và bang | `mart_sales` |
| Tỷ lệ giao trễ, thời gian giao hàng | `mart_logistics` |
| Review score, review thấp, ảnh hưởng của giao trễ | `mart_customer_satisfaction` |
| Hiệu suất từng seller | `mart_seller_performance` |
| So sánh danh mục sản phẩm | `mart_product_category` |
| Phương thức thanh toán và trả góp | `mart_payment` |
| So sánh vùng miền trên nhiều chỉ số | `mart_geolocation` |

