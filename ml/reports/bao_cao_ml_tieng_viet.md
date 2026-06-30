# Báo cáo ứng dụng Machine Learning cho phân tích Olist

## 1. Mục tiêu chung

Phần Machine Learning được dùng để mở rộng phân tích BSC sau khi đã có dashboard, KPI và kiểm định thống kê. Hai bài toán được chọn là:

- Random Forest để dự đoán nguy cơ khách hàng để lại review tiêu cực.
- K-Means để phân nhóm seller theo hiệu quả kinh doanh và chất lượng vận hành.

Hai mô hình này trả lời trực tiếp hai vấn đề quản trị quan trọng: vì sao khách hàng không hài lòng, và nhóm seller nào đang giúp hoặc gây rủi ro cho nền tảng.

## 2. Mô hình 1: Random Forest dự đoán negative review

### Câu hỏi cần trả lời

Khách hàng có khả năng để lại review tiêu cực hay không, và những yếu tố nào làm tăng nguy cơ nhận review 1-2 sao?

Câu hỏi này gắn với Customer Perspective trong BSC:

- Khách hàng có đang không hài lòng với dịch vụ không?
- Việc giao hàng trễ có ảnh hưởng đến đánh giá của khách hàng không?
- Yếu tố vận hành, thanh toán, sản phẩm hoặc khu vực nào làm tăng rủi ro review xấu?

### Dữ liệu đưa vào mô hình

Mô hình sử dụng dữ liệu chi tiết ở cấp review/order, được query trực tiếp từ DWH.

Target:

```text
is_negative_review = 1 nếu review_score <= 2
is_negative_review = 0 nếu review_score >= 3
```

Nguồn dữ liệu:

- `dwh.fact_reviews`: review score, review id, order id.
- `dwh.fact_order_delivery`: trạng thái giao hàng, thời gian duyệt đơn, thời gian giao hàng, số ngày trễ.
- `dwh.fact_order_item_sales`: giá sản phẩm, phí vận chuyển, số lượng item, số lượng seller/product trong đơn.
- `dwh.fact_payments`: giá trị thanh toán, số kỳ trả góp, loại thanh toán.
- `dwh.dim_product`: danh mục sản phẩm, khối lượng, thể tích, số ảnh, độ dài mô tả.
- `dwh.dim_seller`: bang/thành phố của seller.
- `dwh.dim_customer`: bang/thành phố của khách hàng.
- `dwh.dim_date`: năm, tháng.

Các nhóm biến chính:

- Logistics: `is_late`, `delay_days`, `delivery_days`, `approval_hours`, `carrier_handoff_days`, `order_status`.
- Giá trị đơn hàng: `total_price`, `total_freight_value`, `avg_item_price`, `freight_to_price_pct`.
- Cấu trúc đơn hàng: `order_item_count`, `product_count`, `seller_count`.
- Thanh toán: `total_payment_value`, `max_payment_installments`, `payment_type`.
- Sản phẩm: `product_category_name`, `product_weight_g`, `product_volume_cm3`, `product_photos_qty`.
- Địa lý: `seller_state`, `customer_state`.

Nhóm đã loại `seller_city` và `customer_city` khỏi mô hình Random Forest vì hai biến này có quá nhiều giá trị khác nhau, dễ làm mô hình học nhiễu theo địa danh cụ thể. Một số biến trùng ý nghĩa như `total_item_value`, `avg_freight_value`, `avg_payment_value` cũng được loại khỏi Random Forest để mô hình gọn hơn và dễ giải thích hơn.

### Lý do chọn biến

| Nhóm biến | Biến đưa vào | Lý do |
|---|---|---|
| Logistics | `is_late`, `delay_days`, `delivery_days`, `estimated_delivery_days`, `approval_hours`, `carrier_handoff_days`, `order_status` | Trải nghiệm giao hàng ảnh hưởng trực tiếp đến review. Đơn giao trễ, giao lâu hoặc xử lý chậm có nguy cơ review thấp hơn. |
| Giá trị đơn hàng | `total_price`, `total_freight_value`, `avg_item_price`, `freight_to_price_pct` | Giá và phí vận chuyển ảnh hưởng kỳ vọng của khách hàng. Phí cao nhưng dịch vụ kém dễ tạo bất mãn. |
| Cấu trúc đơn hàng | `order_item_count`, `product_count`, `seller_count` | Đơn càng phức tạp thì rủi ro xử lý/giao hàng càng cao. |
| Thanh toán | `total_payment_value`, `max_payment_installments`, `payment_type` | Phản ánh giá trị đơn và hành vi thanh toán, có thể liên quan đến kỳ vọng dịch vụ. |
| Sản phẩm | `product_category_name`, `product_weight_g`, `product_volume_cm3`, `product_photos_qty`, `product_name_length`, `product_description_length` | Danh mục, kích thước và mức độ mô tả sản phẩm có thể ảnh hưởng trải nghiệm mua hàng. |
| Địa lý | `seller_state`, `customer_state` | Khu vực seller/customer ảnh hưởng đến vận hành và thời gian giao hàng. Chỉ dùng state để tránh nhiễu từ city. |
| Thời gian | `year`, `month` | Bắt yếu tố mùa vụ hoặc thay đổi vận hành theo thời gian. |

Lưu ý: các biến như `order_status_delivered`, `order_status_shipped`, `order_status_canceled` trong feature importance là biến dummy được sinh ra từ One-Hot Encoding của `order_status`. Ví dụ `order_status_delivered = 1` nghĩa là đơn ở trạng thái delivered. Biến này hợp lý vì trạng thái đơn hàng phản ánh tiến trình vận hành và có liên quan đến khả năng khách đánh giá thấp.

### Kết quả mô hình

Số dòng dữ liệu dùng để train/test:

```text
99,224 reviews/orders
```

Tỷ lệ review tiêu cực:

```text
14.69%
```

Kết quả đánh giá:

| Chỉ số | Giá trị |
|---|---:|
| Accuracy | 84.72% |
| Precision | 48.30% |
| Recall | 57.05% |
| F1-score | 52.32% |
| ROC-AUC | 78.80% |

Confusion matrix:

| | Dự đoán không tiêu cực | Dự đoán tiêu cực |
|---|---:|---:|
| Thực tế không tiêu cực | 18,937 | 2,225 |
| Thực tế tiêu cực | 1,565 | 2,079 |

Top yếu tố ảnh hưởng lớn nhất:

| Feature | Importance |
|---|---:|
| `delay_days` | 0.1469 |
| `delivery_days` | 0.1383 |
| `order_status_delivered` | 0.1235 |
| `is_late_False` | 0.0917 |
| `is_late_True` | 0.0911 |
| `order_item_count` | 0.0488 |
| `order_status_shipped` | 0.0313 |
| `carrier_handoff_days` | 0.0295 |
| `total_freight_value` | 0.0249 |
| `product_count` | 0.0211 |

### Insight rút ra

Yếu tố vận hành, đặc biệt là giao hàng trễ và thời gian giao hàng, là nhóm tín hiệu mạnh nhất liên quan đến review tiêu cực. Điều này củng cố nhận định trong BSC rằng trải nghiệm khách hàng không chỉ phụ thuộc vào sản phẩm, mà phụ thuộc rất lớn vào chất lượng logistics.

Mô hình có ROC-AUC 78.80%, cho thấy khả năng phân biệt giữa đơn có nguy cơ review xấu và đơn bình thường ở mức khá. Recall của class review tiêu cực là 57.05%, nghĩa là mô hình bắt được hơn một nửa các trường hợp review xấu thật. Precision đạt 48.30%, nghĩa là trong các cảnh báo rủi ro của mô hình, khoảng một nửa là đúng.

Vì vậy, mô hình này phù hợp nhất để dùng như hệ thống cảnh báo rủi ro hoặc xếp hạng ưu tiên xử lý, không nên dùng như quyết định tự động tuyệt đối.

### Đề xuất

- Theo dõi các đơn có `delay_days` cao hoặc `is_late = True` để chủ động chăm sóc khách hàng.
- Ưu tiên xử lý những đơn vừa có rủi ro vận hành, vừa có phí vận chuyển cao hoặc nhiều item.
- Dùng xác suất dự đoán `negative_review_probability` làm risk score cho từng đơn.
- Tập trung cải thiện quy trình logistics vì đây là nhóm yếu tố ảnh hưởng mạnh nhất đến review xấu.
- Theo dõi seller/category thường xuyên xuất hiện trong nhóm đơn có risk cao.

## 3. Mô hình 2: K-Means phân nhóm seller

### Câu hỏi cần trả lời

Seller nào đang đóng góp tốt cho nền tảng, seller nào có rủi ro về vận hành hoặc trải nghiệm khách hàng?

Câu hỏi này gắn với Ecosystem Health Perspective trong BSC:

- Seller nào mang lại GMV cao?
- Seller nào có tỷ lệ giao trễ hoặc review xấu cao?
- Có thể chia seller thành các nhóm để đưa ra chính sách quản trị khác nhau không?

### Dữ liệu đưa vào mô hình

Mô hình sử dụng dữ liệu từ `mart.mart_seller_performance`.

Grain ban đầu của mart:

```text
1 dòng = 1 tháng + 1 seller + 1 product category
```

Trước khi train, dữ liệu được aggregate về:

```text
1 dòng = 1 seller
```

Các biến đưa vào K-Means:

- Quy mô kinh doanh: `total_orders`, `total_items`, `total_revenue`, `gross_merchandise_value`.
- Chi phí/logistics: `total_freight_value`, `avg_freight_value`, `freight_to_gmv_pct`.
- Giá bán: `avg_item_price`.
- Chất lượng review: `avg_review_score`, `low_review_count`, `low_review_rate_pct`.
- Hiệu quả giao hàng: `late_orders`, `late_rate_pct`.
- Độ đa dạng danh mục: `category_count`.
- Mức độ hoạt động: `active_month_count`.

Lý do chọn các biến này:

| Nhóm biến | Ý nghĩa |
|---|---|
| Quy mô kinh doanh | Cho biết seller lớn hay nhỏ, đóng góp nhiều hay ít cho sàn. |
| Chi phí/logistics | Cho biết chi phí vận hành và mức độ tốn kém của giao hàng. |
| Review | Phản ánh trải nghiệm khách hàng sau mua. |
| Giao hàng | Phản ánh rủi ro vận hành, đặc biệt là trễ đơn. |
| Đa dạng danh mục | Seller bán nhiều category có thể có năng lực vận hành khác seller chỉ bán ít nhóm hàng. |
| Mức độ hoạt động | Seller hoạt động nhiều tháng ổn định hơn seller chỉ xuất hiện ngắn hạn. |

Các seller có quá ít đơn được lọc bỏ bằng điều kiện:

```text
total_orders >= 5
```

### Kết quả mô hình

Số seller được sử dụng:

```text
1,796 sellers
```

K-Means thử các giá trị `k` từ 2 đến 8. Theo silhouette score, mô hình chọn:

```text
k = 2
```

Kết quả thử các giá trị `k`:

| k | Silhouette score | Nhận xét |
|---:|---:|---|
| 2 | 0.3035 | Tách cụm sạch nhất, chọn làm model chính. |
| 3 | 0.2115 | Cụm chi tiết hơn nhưng kém tách biệt. |
| 4 | 0.2122 | Dễ kể chuyện business hơn nhưng chỉ nên xem là exploratory. |
| 5 | 0.2233 | Nhỉnh hơn k=3/k=4 nhưng vẫn thấp hơn k=2, khó giải thích hơn. |

Kết quả phân nhóm:

| Segment | Số seller | Tổng GMV | Avg review | Avg late rate |
|---|---:|---:|---:|---:|
| High-Value Watchlist Sellers | 607 | 10,577,202.61 | 4.08 | 8.16% |
| Emerging Sellers | 1,189 | 2,446,683.73 | 4.13 | 8.09% |

### Insight rút ra

Kết quả K-Means tách seller thành hai nhóm chính dựa trên quy mô GMV và tín hiệu vận hành.

Nhóm High-Value Watchlist Sellers có số lượng seller ít hơn nhưng đóng góp GMV lớn hơn rất nhiều. Đây là nhóm seller quan trọng về mặt doanh thu, nhưng có review trung bình thấp hơn một chút và late rate cao hơn một chút so với nhóm còn lại. Vì vậy, không nên hiểu đây là nhóm seller xấu, mà là nhóm seller giá trị cao cần được theo dõi sát hơn.

Nhóm Emerging Sellers có GMV thấp hơn nhưng review trung bình tốt hơn một chút. Đây là nhóm có thể được hỗ trợ để phát triển thêm, vì hiện tại chất lượng tương đối ổn nhưng quy mô còn nhỏ.

Kết quả `k = 2` là lựa chọn tốt nhất theo silhouette score. Các giá trị `k = 3`, `k = 4` và `k = 5` tạo nhiều nhóm hơn nhưng silhouette thấp hơn, nghĩa là cụm không tách biệt rõ bằng `k = 2`. Vì vậy, `k = 2` nên là kết quả chính trong báo cáo.

Tuy nhiên, để khai thác insight business sâu hơn, có thể dùng thêm `k = 4` như một góc nhìn exploratory:

| Nhóm exploratory | Số seller | Tổng GMV | Avg review | Avg late rate | Ý nghĩa |
|---|---:|---:|---:|---:|---|
| High-Value Core Sellers | 367 | 8,554,901.20 | 4.05 | 8.36% | Nhóm lõi tạo doanh thu lớn, cần ưu tiên quản trị SLA. |
| Growth Sellers | 568 | 3,434,362.66 | 4.19 | 7.04% | Nhóm quy mô vừa, chất lượng tương đối ổn, có thể phát triển thêm. |
| Problem Sellers | 253 | 468,258.61 | 3.28 | 18.21% | Nhóm chất lượng thấp rõ rệt, cần cảnh báo hoặc can thiệp. |
| Healthy Emerging Sellers | 608 | 566,363.87 | 4.42 | 4.79% | Nhóm nhỏ nhưng chất lượng tốt, có thể hỗ trợ tăng trưởng. |

Khi trình bày, nhóm nên nói rõ: `k = 4` giúp kể câu chuyện seller persona tốt hơn, nhưng chỉ là phân tích mở rộng vì metric thấp hơn `k = 2`.

### Đề xuất

- Với High-Value Watchlist Sellers:
  - Không nên loại bỏ ngay vì đây là nhóm đóng góp GMV lớn.
  - Cần theo dõi late rate, low review rate và các category gây rủi ro.
  - Có thể đặt SLA riêng hoặc cảnh báo seller khi tỷ lệ trễ vượt ngưỡng.

- Với Emerging Sellers:
  - Có thể hỗ trợ tăng visibility hoặc ưu tiên phát triển.
  - Khuyến khích mở rộng danh mục nếu review và vận hành vẫn ổn định.
  - Theo dõi tăng trưởng GMV qua thời gian để phát hiện seller có tiềm năng scale.

- Với toàn bộ hệ sinh thái seller:
  - Kết hợp GMV với review và late rate, không đánh giá seller chỉ bằng doanh thu.
  - Thiết kế seller score gồm 3 nhóm: doanh thu, vận hành, trải nghiệm khách hàng.
  - Dùng segmentation làm cơ sở cho chính sách thưởng, cảnh báo hoặc hỗ trợ seller.

## 4. Kết luận chung

Hai mô hình ML giúp bổ sung góc nhìn dự đoán và phân nhóm cho hệ thống phân tích BSC.

Random Forest cho thấy review tiêu cực có liên hệ mạnh với logistics, đặc biệt là số ngày trễ và thời gian giao hàng. Điều này giúp chuyển phân tích từ mô tả sang hành động: xác định đơn hàng có nguy cơ review xấu để can thiệp sớm.

K-Means cho thấy seller không nên được đánh giá chỉ bằng GMV. Một nhóm seller có thể mang lại doanh thu lớn nhưng vẫn tạo rủi ro về vận hành và trải nghiệm khách hàng. Vì vậy, nền tảng cần quản trị seller theo nhiều chiều: doanh thu, giao hàng và review.

Tổng hợp lại, hướng hành động chính là:

- Cải thiện logistics để giảm negative review.
- Dùng risk score để ưu tiên chăm sóc đơn hàng.
- Giám sát seller có GMV cao nhưng late/review xấu.
- Phát triển nhóm seller có chất lượng tốt nhưng quy mô còn nhỏ.
- Đưa kết quả ML vào dashboard/report để hỗ trợ quyết định quản trị.
