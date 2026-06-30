# Kịch bản thuyết trình: Phân tích dữ liệu bằng mô hình Machine Learning

## 1. Mở đầu

Kính chào thầy/cô và các bạn.

Trong phần này, nhóm em trình bày cách ứng dụng Machine Learning vào bài toán phân tích dữ liệu thương mại điện tử Olist. Sau khi đã xây dựng pipeline dữ liệu, data warehouse, data mart và dashboard Power BI, nhóm tiếp tục dùng mô hình học máy để trả lời hai câu hỏi phân tích nâng cao:

1. Có thể dự đoán đơn hàng nào có nguy cơ nhận review tiêu cực hay không?
2. Có thể phân nhóm seller để biết nhóm nào đang đóng góp tốt, nhóm nào cần được theo dõi hay hỗ trợ hay không?

Với hai câu hỏi này, nhóm sử dụng hai mô hình chính:

- Random Forest Classification để dự đoán review tiêu cực.
- K-Means Clustering để phân nhóm seller.

Hai mô hình này không thay thế dashboard, mà bổ sung thêm góc nhìn dự đoán và phân nhóm, giúp phần phân tích có tính hành động hơn.

## 2. Tổng quan dữ liệu đầu vào

Dữ liệu được lấy từ hệ thống DWH và mart đã xây dựng trong project. Các bảng chính gồm:

- `dwh.fact_reviews`: thông tin điểm review của khách hàng.
- `dwh.fact_order_delivery`: thông tin giao hàng, thời gian giao, trạng thái đơn, số ngày trễ.
- `dwh.fact_order_item_sales`: thông tin doanh thu, giá sản phẩm, phí vận chuyển, số lượng item.
- `dwh.fact_payments`: thông tin thanh toán.
- `dwh.dim_product`, `dwh.dim_seller`, `dwh.dim_customer`, `dwh.dim_date`: thông tin mô tả sản phẩm, seller, khách hàng và thời gian.
- `mart.mart_seller_performance`: bảng tổng hợp hiệu suất seller theo tháng, seller và danh mục sản phẩm.

Điểm quan trọng là mô hình không chạy trực tiếp trên dữ liệu raw, mà chạy trên dữ liệu đã được làm sạch, chuẩn hóa và tổng hợp từ DWH/Data Mart. Nhờ vậy, dữ liệu đầu vào có ý nghĩa nghiệp vụ rõ hơn.

## 2.1. Kiểm soát biến đầu vào trước khi đưa vào mô hình

Một điểm cần lưu ý là không nên hiểu Machine Learning theo hướng đưa càng nhiều biến vào mô hình càng tốt. Nếu biến quá nhiều nhưng nhiễu, bị thiếu dữ liệu nhiều, phân phối quá lệch hoặc không có ý nghĩa nghiệp vụ, mô hình có thể học kém ổn định và khó giải thích.

Vì vậy, khi chọn biến cho hai mô hình, nhóm dựa trên ba tiêu chí:

- Biến phải có ý nghĩa nghiệp vụ rõ ràng với bài toán.
- Biến phải có khả năng quan sát trước hoặc tại thời điểm cần phân tích.
- Biến không nên bị thiếu dữ liệu quá nặng hoặc quá lệch đến mức làm méo kết quả.

Với Random Forest, mô hình hiện tại đang dùng nhiều nhóm biến: logistics, giá trị đơn hàng, thanh toán, sản phẩm, địa lý và thời gian. Số lượng biến này không phải là quá nhiều đối với Random Forest, vì mô hình có khả năng chọn biến quan trọng thông qua nhiều cây quyết định. Tuy nhiên, vẫn cần kiểm soát để tránh đưa vào các biến gây nhiễu.

Cách xử lý hiện tại:

- Biến số bị thiếu được điền bằng median, giúp giảm ảnh hưởng của outlier so với dùng mean.
- Biến phân loại bị thiếu được gán là `Unknown`.
- Biến phân loại được One-Hot Encoding, đồng thời gom các nhóm quá hiếm bằng `min_frequency=20`.
- Mô hình có feature importance để kiểm tra lại biến nào thật sự đóng góp nhiều.
- Sau khi profile dữ liệu, nhóm loại `seller_city` và `customer_city` khỏi Random Forest vì hai biến này có quá nhiều giá trị khác nhau, dễ làm mô hình học nhiễu theo địa danh cụ thể thay vì học quy luật tổng quát.
- Nhóm cũng loại một số biến trùng ý nghĩa như `total_item_value`, `avg_freight_value`, `avg_payment_value` để feature set gọn hơn và dễ giải thích hơn.

Nếu làm kỹ hơn cho phiên bản sau, nhóm nên bổ sung bước profiling trước khi train:

- Loại hoặc xem xét lại biến có tỷ lệ null quá cao, ví dụ trên 40% hoặc 50%.
- Với biến số bị lệch mạnh như doanh thu, GMV, phí vận chuyển, có thể log-transform hoặc winsorize để giảm ảnh hưởng của giá trị cực đoan.
- Với biến phân loại có quá nhiều giá trị như city hoặc product category, nên gom nhóm hiếm thành `Other`.
- Loại các biến có nguy cơ data leakage, tức là biến chỉ biết sau khi khách hàng đã review hoặc sau khi kết quả đã xảy ra.
- So sánh mô hình trước và sau khi giảm biến để xem performance và khả năng giải thích có tốt hơn không.

Trong báo cáo, nhóm có thể nói rằng phiên bản hiện tại là baseline có kiểm soát cơ bản, còn hướng cải tiến là thêm feature profiling và feature selection chặt hơn.

## 3. Mô hình 1: Random Forest dự đoán review tiêu cực

### 3.1. Mục tiêu

Mô hình Random Forest được dùng để dự đoán một review có phải là review tiêu cực hay không.

Trong project này, nhóm định nghĩa:

```text
is_negative_review = 1 nếu review_score <= 2
is_negative_review = 0 nếu review_score >= 3
```

Nói đơn giản, mô hình học từ các đơn hàng trong quá khứ để nhận diện những đặc điểm thường đi kèm với review xấu, ví dụ như giao hàng trễ, thời gian giao dài, phí vận chuyển cao hoặc đơn hàng có nhiều item.

### 3.2. Random Forest hoạt động như thế nào?

Random Forest là mô hình phân loại gồm nhiều cây quyết định.

Một cây quyết định hoạt động giống như một chuỗi câu hỏi:

- Đơn hàng có bị giao trễ không?
- Số ngày trễ là bao nhiêu?
- Thời gian giao hàng có quá dài không?
- Đơn hàng có nhiều sản phẩm không?
- Phí vận chuyển có cao không?

Mỗi cây sẽ đưa ra một dự đoán riêng. Random Forest kết hợp kết quả của nhiều cây, sau đó lấy biểu quyết đa số để đưa ra kết quả cuối cùng.

Ưu điểm của Random Forest là:

- Xử lý được cả biến số và biến phân loại.
- Ít bị phụ thuộc vào một cây duy nhất nên ổn định hơn Decision Tree đơn lẻ.
- Có thể tính feature importance để biết biến nào ảnh hưởng mạnh đến kết quả dự đoán.
- Phù hợp với bài toán cần giải thích yếu tố rủi ro trong dữ liệu kinh doanh.

### 3.3. Cách áp dụng vào bài toán Olist

Nhóm tạo tập đặc trưng ở cấp review/order. Mỗi dòng dữ liệu đại diện cho một review gắn với một đơn hàng.

Các nhóm biến đầu vào gồm:

- Logistics: `is_late`, `delay_days`, `delivery_days`, `approval_hours`, `carrier_handoff_days`, `order_status`.
- Giá trị đơn hàng: `total_price`, `total_freight_value`, `avg_item_price`, `freight_to_price_pct`.
- Cấu trúc đơn hàng: `order_item_count`, `product_count`, `seller_count`.
- Thanh toán: `total_payment_value`, `max_payment_installments`, `payment_type`.
- Sản phẩm: `product_category_name`, khối lượng, thể tích, số ảnh, độ dài mô tả.
- Địa lý: bang của seller và customer. Nhóm không dùng city vì city có quá nhiều giá trị khác nhau, dễ gây nhiễu.
- Thời gian: năm, tháng review.

Trước khi train, dữ liệu được xử lý như sau:

- Biến số bị thiếu được điền bằng median.
- Biến phân loại bị thiếu được điền bằng `Unknown`.
- Biến phân loại được One-Hot Encoding.
- Tập dữ liệu được chia train/test theo tỷ lệ 75%/25%.
- Mô hình dùng `class_weight="balanced"` vì review tiêu cực chiếm khoảng 14.69%, tức là dữ liệu bị lệch lớp.

### 3.4. Vì sao chọn các biến này?

Khi chọn biến cho Random Forest, nhóm không chọn theo hướng càng nhiều càng tốt, mà chọn theo giả thuyết nghiệp vụ: review xấu thường đến từ vấn đề giao hàng, giá trị đơn hàng, cấu trúc đơn hàng, thanh toán, sản phẩm và khu vực vận hành.

| Nhóm biến | Biến đưa vào | Lý do đưa vào mô hình |
|---|---|---|
| Logistics | `is_late`, `delay_days`, `delivery_days`, `estimated_delivery_days`, `approval_hours`, `carrier_handoff_days`, `order_status` | Đây là nhóm biến quan trọng nhất vì trải nghiệm giao hàng ảnh hưởng trực tiếp đến mức độ hài lòng. Đơn giao trễ, giao lâu hoặc xử lý chậm thường có nguy cơ review thấp hơn. |
| Trạng thái đơn hàng | `order_status` | Trạng thái đơn cho biết đơn đã giao, đang vận chuyển, bị hủy, unavailable hay còn xử lý. Sau One-Hot Encoding, biến này tách thành các biến như `order_status_delivered`, `order_status_shipped`, `order_status_canceled`. |
| Giá trị đơn hàng | `total_price`, `total_freight_value`, `avg_item_price`, `freight_to_price_pct` | Giá sản phẩm và phí vận chuyển có thể ảnh hưởng kỳ vọng của khách. Ví dụ phí vận chuyển cao nhưng giao chậm có thể làm khách không hài lòng hơn. |
| Cấu trúc đơn hàng | `order_item_count`, `product_count`, `seller_count` | Đơn có nhiều item, nhiều sản phẩm hoặc nhiều seller thường phức tạp hơn trong xử lý và giao hàng, từ đó có thể tăng rủi ro phát sinh lỗi. |
| Thanh toán | `total_payment_value`, `max_payment_installments`, `payment_type` | Giá trị thanh toán và hình thức thanh toán phản ánh hành vi mua hàng. Đơn giá trị cao hoặc trả góp nhiều kỳ có thể đi kèm kỳ vọng dịch vụ cao hơn. |
| Sản phẩm | `product_category_name`, `product_weight_g`, `product_volume_cm3`, `product_photos_qty`, `product_name_length`, `product_description_length` | Danh mục, kích thước và mức độ mô tả sản phẩm có thể ảnh hưởng trải nghiệm. Sản phẩm cồng kềnh hoặc mô tả kém có thể tăng rủi ro giao hàng và kỳ vọng sai lệch. |
| Địa lý | `seller_state`, `customer_state` | Khoảng cách và khu vực vận hành có thể ảnh hưởng thời gian giao hàng. Nhóm dùng state thay vì city để giữ tín hiệu địa lý ở mức tổng quát, tránh nhiễu do quá nhiều city. |
| Thời gian | `year`, `month` | Thời gian giúp mô hình nhận diện yếu tố mùa vụ hoặc thay đổi vận hành theo từng giai đoạn. |

Ví dụ nếu bị hỏi vì sao có `order_status_delivered`, có thể trả lời:

> `order_status_delivered` không phải là biến được thêm thủ công, mà là biến được tạo ra sau khi One-Hot Encoding biến `order_status`. Nó có giá trị 1 nếu đơn hàng ở trạng thái delivered và 0 nếu không. Biến này có ý nghĩa vì trạng thái giao hàng phản ánh tiến trình vận hành của đơn. Trong feature importance, `order_status_delivered` đứng cao, cho thấy trạng thái đơn hàng có liên quan mạnh đến khả năng review tiêu cực.

Nhóm cũng cần nói rõ: các biến logistics như `delay_days`, `delivery_days`, `is_late` phù hợp nếu mục tiêu là đánh giá rủi ro sau khi đơn đã có thông tin giao hàng. Nếu muốn dự đoán ngay tại thời điểm khách vừa đặt hàng, cần tạo một phiên bản mô hình khác và loại các biến chỉ biết sau khi giao.

### 3.5. Kết quả hiện tại

Số dòng dữ liệu dùng cho mô hình:

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

### 3.6. Cách đọc kết quả

Accuracy đạt 84.72%, nhìn chung là tốt, nhưng vì dữ liệu bị lệch lớp nên không nên chỉ nhìn accuracy.

Điểm quan trọng hơn là:

- Recall đạt 57.05%, nghĩa là mô hình phát hiện được hơn một nửa số review tiêu cực thật.
- Precision đạt 48.30%, nghĩa là trong các trường hợp mô hình cảnh báo tiêu cực, khoảng một nửa là đúng.
- ROC-AUC đạt 78.80%, cho thấy mô hình có khả năng phân biệt giữa đơn hàng rủi ro và đơn hàng bình thường ở mức khá.

Vì vậy, mô hình này phù hợp để dùng như hệ thống cảnh báo sớm hoặc risk scoring. Ví dụ, doanh nghiệp có thể ưu tiên chăm sóc những đơn hàng có xác suất nhận review xấu cao. Tuy nhiên, không nên dùng mô hình này như quyết định tự động tuyệt đối, vì vẫn còn cảnh báo nhầm.

### 3.7. Yếu tố ảnh hưởng lớn nhất

Top feature importance hiện tại:

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

Nhìn vào đây có thể thấy nhóm yếu tố logistics là quan trọng nhất. Các biến như số ngày trễ, thời gian giao hàng và trạng thái đơn hàng có ảnh hưởng mạnh đến khả năng nhận review tiêu cực.

Insight chính là: trải nghiệm khách hàng trong Olist không chỉ phụ thuộc vào sản phẩm, mà phụ thuộc rất mạnh vào chất lượng giao hàng.

## 4. Mô hình 2: K-Means phân nhóm seller

### 4.1. Mục tiêu

Mô hình K-Means được dùng để phân nhóm seller theo hiệu quả kinh doanh và chất lượng vận hành.

Câu hỏi nghiệp vụ là:

- Seller nào đang tạo ra nhiều GMV?
- Seller nào có tỷ lệ giao trễ hoặc review thấp cao?
- Có nhóm seller nào nên được hỗ trợ phát triển?
- Có nhóm seller nào cần được giám sát rủi ro?

### 4.2. K-Means hoạt động như thế nào?

K-Means là thuật toán học không giám sát. Khác với Random Forest, K-Means không cần nhãn đúng/sai.

Thuật toán hoạt động theo ý tưởng:

1. Chọn số cụm `k`.
2. Khởi tạo `k` tâm cụm.
3. Gán mỗi seller vào cụm có tâm gần nhất.
4. Tính lại tâm cụm dựa trên các seller trong cụm.
5. Lặp lại đến khi cụm ổn định.

Mục tiêu của K-Means là gom các seller có đặc điểm giống nhau vào cùng một nhóm, đồng thời làm cho các nhóm khác nhau càng tách biệt càng tốt.

### 4.3. Cách áp dụng vào bài toán Olist

Dữ liệu đầu vào lấy từ `mart.mart_seller_performance`.

Ban đầu mart có grain:

```text
1 dòng = 1 tháng + 1 seller + 1 product category
```

Trước khi đưa vào mô hình, nhóm aggregate về:

```text
1 dòng = 1 seller
```

Các biến dùng để phân nhóm gồm:

- Quy mô kinh doanh: `total_orders`, `total_items`, `total_revenue`, `gross_merchandise_value`.
- Logistics/chi phí: `total_freight_value`, `avg_freight_value`, `freight_to_gmv_pct`.
- Giá bán: `avg_item_price`.
- Review: `avg_review_score`, `low_review_count`, `low_review_rate_pct`.
- Giao hàng: `late_orders`, `late_rate_pct`.
- Độ đa dạng hoạt động: `category_count`, `active_month_count`.

Lý do chọn các biến này:

| Nhóm biến | Ý nghĩa |
|---|---|
| Quy mô kinh doanh | Cho biết seller lớn hay nhỏ, đóng góp nhiều hay ít cho sàn. |
| Chi phí/logistics | Cho biết chi phí vận hành và mức độ tốn kém của giao hàng. |
| Review | Phản ánh trải nghiệm khách hàng sau mua. |
| Giao hàng | Phản ánh rủi ro vận hành, đặc biệt là trễ đơn. |
| Đa dạng danh mục | Seller bán nhiều category có thể có năng lực vận hành khác seller chỉ bán ít nhóm hàng. |
| Mức độ hoạt động | Seller hoạt động nhiều tháng ổn định hơn seller chỉ xuất hiện ngắn hạn. |

Nhóm lọc các seller có quá ít đơn bằng điều kiện:

```text
total_orders >= 5
```

Trước khi chạy K-Means:

- Các biến quy mô như doanh thu, GMV, số đơn được log-transform để giảm ảnh hưởng của giá trị quá lớn.
- Dữ liệu thiếu được điền bằng median.
- Các biến được chuẩn hóa bằng StandardScaler để tránh biến có đơn vị lớn chi phối kết quả.
- Mô hình thử `k` từ 2 đến 8 và chọn `k` có silhouette score tốt nhất.

### 4.4. Kết quả hiện tại

Số seller được đưa vào mô hình:

```text
1,796 sellers
```

Mô hình chọn:

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

### 4.5. Cách đọc kết quả

Nhóm High-Value Watchlist Sellers có số seller ít hơn nhưng tổng GMV cao hơn rất nhiều. Điều này nghĩa là đây là nhóm seller quan trọng về mặt doanh thu.

Tuy nhiên, nhóm này có review trung bình thấp hơn một chút và tỷ lệ giao trễ cao hơn một chút so với nhóm Emerging Sellers. Vì vậy, không nên gọi đây là nhóm seller xấu, mà nên hiểu là nhóm seller giá trị cao cần theo dõi. Nếu nhóm này vận hành kém thì tác động đến doanh thu và trải nghiệm khách hàng sẽ lớn.

Nhóm Emerging Sellers có GMV thấp hơn nhưng review trung bình tốt hơn một chút. Đây là nhóm có thể được hỗ trợ để tăng quy mô, ví dụ tăng hiển thị sản phẩm, hỗ trợ seller phát triển category hoặc theo dõi seller có dấu hiệu tăng trưởng tốt.

Silhouette score tốt nhất hiện tại là với `k = 2`, nên về mặt kỹ thuật đây là kết quả hợp lý nhất trong các lựa chọn đã thử. Tuy nhiên, `k = 2` chủ yếu tách seller theo quy mô/GMV, chưa tạo nhiều persona chi tiết. Nếu muốn kể chuyện business phong phú hơn, có thể dùng thêm `k = 4` như một góc nhìn exploratory, không thay thế model chính.

Với `k = 4`, các nhóm exploratory có thể đọc như sau:

| Nhóm exploratory | Số seller | GMV | Avg review | Avg late rate | Ý nghĩa |
|---|---:|---:|---:|---:|---|
| High-Value Core Sellers | 367 | 8,554,901.20 | 4.05 | 8.36% | Nhóm lõi tạo doanh thu lớn, cần ưu tiên quản trị SLA. |
| Growth Sellers | 568 | 3,434,362.66 | 4.19 | 7.04% | Nhóm đang có quy mô vừa và chất lượng tương đối ổn, có thể phát triển thêm. |
| Problem Sellers | 253 | 468,258.61 | 3.28 | 18.21% | Nhóm chất lượng thấp rõ rệt, cần cảnh báo hoặc can thiệp. |
| Healthy Emerging Sellers | 608 | 566,363.87 | 4.42 | 4.79% | Nhóm nhỏ nhưng chất lượng tốt, có thể hỗ trợ tăng trưởng. |

Cách trình bày chắc nhất là: dùng `k = 2` làm kết quả chính vì metric tốt nhất, sau đó dùng `k = 4` như phân tích mở rộng để minh họa chính sách seller chi tiết hơn.

## 5. Đánh giá: Kết quả hiện tại có ổn để báo cáo chưa?

Theo nhóm em, kết quả hiện tại đủ ổn để đưa vào báo cáo, với điều kiện trình bày đúng vai trò của từng mô hình.

Với Random Forest:

- Kết quả ROC-AUC 78.80% là mức khá cho bài toán phân loại review tiêu cực với định nghĩa `review_score <= 2`.
- Accuracy 84.72% nhìn tốt, nhưng cần nói rõ dữ liệu bị lệch lớp.
- Recall 57.05% và Precision 48.30% cho thấy mô hình phù hợp làm cảnh báo rủi ro, không phù hợp làm quyết định tự động tuyệt đối.
- Feature importance rất hợp lý về mặt nghiệp vụ vì các biến logistics đứng đầu.
- Mô hình hiện tại đã có xử lý missing value và one-hot encoding, nhưng vẫn nên trình bày đây là baseline; phiên bản tốt hơn nên bổ sung bước loại biến null nhiều, xử lý biến lệch mạnh và kiểm tra data leakage.

Với K-Means:

- Mô hình chọn `k = 2` theo silhouette score, nên có cơ sở kỹ thuật.
- Hai nhóm seller có khác biệt lớn về GMV, phù hợp để kể câu chuyện quản trị seller ở cấp tổng quan.
- Tuy nhiên khác biệt về review và late rate chưa quá lớn, nên khi báo cáo cần nói là phân nhóm theo quy mô kết hợp tín hiệu vận hành, không nên nói đây là phân nhóm chất lượng seller hoàn toàn tách biệt.
- Có thể bổ sung `k = 4` như phân tích exploratory để chỉ ra nhóm Problem Sellers và Healthy Emerging Sellers rõ hơn, nhưng không nên nói `k = 4` là model chính vì silhouette thấp hơn.

Kết luận: có thể báo cáo được. Phần nên nhấn mạnh là insight và ứng dụng quản trị, không nên phóng đại rằng mô hình đã dự đoán hoàn hảo.

## 6. Hướng đề xuất hành động

Từ Random Forest:

- Xây dựng risk score cho từng đơn hàng dựa trên xác suất review tiêu cực.
- Ưu tiên chăm sóc các đơn có `delay_days` cao hoặc `is_late = True`.
- Theo dõi seller/category thường xuyên xuất hiện trong nhóm đơn hàng rủi ro cao.
- Cải thiện logistics vì đây là nhóm biến ảnh hưởng mạnh nhất đến review xấu.

Từ K-Means:

- Với High-Value Watchlist Sellers: tiếp tục giữ vì đóng góp GMV lớn, nhưng cần theo dõi SLA, late rate và low review rate.
- Với Emerging Sellers: hỗ trợ tăng trưởng vì chất lượng tương đối ổn nhưng quy mô còn thấp.
- Không đánh giá seller chỉ bằng doanh thu; nên kết hợp GMV, review và hiệu quả giao hàng.

## 7. Kết luận thuyết trình

Tóm lại, phần Machine Learning giúp project chuyển từ phân tích mô tả sang phân tích dự đoán và phân nhóm.

Random Forest giúp nhận diện các đơn hàng có nguy cơ review tiêu cực. Kết quả cho thấy yếu tố logistics, đặc biệt là giao hàng trễ và thời gian giao hàng, là nguyên nhân nổi bật ảnh hưởng đến sự không hài lòng của khách hàng.

K-Means giúp phân nhóm seller theo quy mô kinh doanh và tín hiệu vận hành. Kết quả cho thấy một nhóm seller đóng góp GMV rất lớn nhưng cần được giám sát kỹ hơn về review và giao hàng, trong khi nhóm seller còn lại có tiềm năng phát triển thêm.

Do đó, hai mô hình này bổ sung trực tiếp cho dashboard và BSC: dashboard cho biết điều gì đang xảy ra, còn Machine Learning giúp dự đoán rủi ro và ưu tiên hành động.

Phần trình bày của nhóm em xin kết thúc tại đây. Em xin cảm ơn thầy/cô và các bạn đã lắng nghe.
