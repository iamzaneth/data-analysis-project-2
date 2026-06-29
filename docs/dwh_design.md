# Thiết kế DWH - Chi tiết Chiều và Bảng Sự Kiện

## Tổng quan

Thiết kế DWH Olist sử dụng **Star Schema** với 7 bảng chiều (dimension) và 4 bảng sự kiện (fact). Star Schema được lựa chọn vì:

- **Truy vấn nhanh**: Số lượng join ít so với normalized schema
- **Dễ hiểu**: Cấu trúc rõ ràng cho các nhà phân tích
- **Linh hoạt**: Dễ mở rộng thêm chiều và chỉ số mới
- **Phù hợp với BI tools**: Các công cụ Dashboard/BI tự động hỗ trợ Star Schema

Kiến trúc Star Schema:

```
                        dim_date (Role-playing)
                         /   |   \
                        /    |    \
                       /     |     \
            dim_customer    dim_product    dim_order_status
                  |         /    |    \            |
                  |        /     |     \           |
                  |    dim_seller  dim_payment_type  |
                  |        /           \            |
                  |       /             \           |
                   \-----fact tables----/
                    (sales, delivery, payments, reviews)
                          |
                    dim_geolocation (linked via zip codes)
```

---

## 1. Bảng Chiều (Dimensions)

### 1.1 dim_date (Ngày - Role-Playing Dimension)

**Mục đích**: Cung cấp thông tin ngày tháng để phân tích theo thời gian. Đây là role-playing dimension vì nó được tham chiếu bởi nhiều khóa ngày khác nhau.

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa |
|-----------|------------|---------|
| `date_key` | INTEGER PRIMARY KEY | Khóa chính, định dạng YYYYMMDD (ví dụ: 20240115) để dễ đối chiếu |
| `full_date` | DATE UNIQUE | Ngày đầy đủ (ví dụ: 2024-01-15) |
| `year` | INTEGER | Năm (ví dụ: 2024) |
| `quarter` | INTEGER | Quý trong năm (1, 2, 3, hoặc 4) |
| `month` | INTEGER | Tháng trong năm (1-12) |
| `month_name` | TEXT | Tên tháng tiếng Anh (January, February, ...) |
| `day` | INTEGER | Ngày trong tháng (1-31) |
| `day_of_week` | INTEGER | Ngày trong tuần (1=Thứ 2, ..., 7=Chủ nhật) theo ISO |
| `day_name` | TEXT | Tên ngày trong tuần tiếng Anh (Monday, Tuesday, ...) |
| `is_weekend` | BOOLEAN | True nếu là thứ 6 hoặc chủ nhật |

**Cách sử dụng**: Được join với các khóa sau tùy theo ngữ cảnh:
- `purchase_date_key`: Ngày khách hàng mua hàng
- `approved_date_key`: Ngày đơn hàng được xác nhận
- `delivered_carrier_date_key`: Ngày giao cho đơn vị vận chuyển
- `delivered_customer_date_key`: Ngày giao cho khách hàng
- `estimated_delivery_date_key`: Ngày dự kiến giao
- `shipping_limit_date_key`: Hạn chót giao hàng
- `review_creation_date_key`: Ngày khách hàng viết review
- `review_answer_date_key`: Ngày người bán phản hồi review

**Ví dụ**: Phân tích doanh số theo tháng, theo quý, hoặc xác định đơn hàng nào giao trễ qua so sánh `delivered_customer_date_key` với `estimated_delivery_date_key`.

---

### 1.2 dim_customer (Khách hàng)

**Mục đích**: Lưu trữ thông tin nhân khẩu học của khách hàng.

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa |
|-----------|------------|---------|
| `customer_key` | BIGSERIAL PRIMARY KEY | Khóa chính thay thế (surrogate key) |
| `customer_id` | TEXT UNIQUE | ID khách hàng gốc từ dữ liệu nguồn |
| `customer_unique_id` | TEXT | ID duy nhất khách hàng (có thể mua nhiều lần với customer_id khác nhau) |
| `customer_zip_code_prefix` | TEXT | 5 chữ số đầu tiên của mã bưu chính (dùng để join với dim_geolocation) |
| `customer_city` | TEXT | Thành phố khách hàng |
| `customer_state` | TEXT | Tỉnh/Bang khách hàng (ví dụ: SP, RJ, MG) |

**Cách sử dụng**: Join với bảng sự kiện qua `customer_key`. Dùng `customer_zip_code_prefix` để tìm địa lý chi tiết trong `dim_geolocation`.

**Ví dụ**: Phân tích doanh số theo khu vực địa lý, RFM analysis (Recency, Frequency, Monetary), hoặc hành vi khách hàng.

---

### 1.3 dim_seller (Người bán)

**Mục đích**: Lưu trữ thông tin địa lý và định danh của người bán hàng.

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa |
|-----------|------------|---------|
| `seller_key` | BIGSERIAL PRIMARY KEY | Khóa chính thay thế |
| `seller_id` | TEXT UNIQUE | ID người bán gốc từ dữ liệu nguồn |
| `seller_zip_code_prefix` | TEXT | 5 chữ số đầu tiên của mã bưu chính người bán |
| `seller_city` | TEXT | Thành phố nơi người bán đặt trụ sở |
| `seller_state` | TEXT | Tỉnh/Bang người bán |

**Cách sử dụng**: Join với `fact_order_item_sales` qua `seller_key`. Dùng `seller_zip_code_prefix` để tìm địa lý chi tiết.

**Ví dụ**: Phân tích hiệu suất người bán, độ phân tán địa lý, hoặc so sánh chất lượng dịch vụ giữa các vùng.

---

### 1.4 dim_product (Sản phẩm)

**Mục đích**: Lưu trữ thông tin chi tiết sản phẩm bao gồm danh mục, kích thước và trọng lượng.

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa |
|-----------|------------|---------|
| `product_key` | BIGSERIAL PRIMARY KEY | Khóa chính thay thế |
| `product_id` | TEXT UNIQUE | ID sản phẩm gốc |
| `product_category_name` | TEXT | Danh mục sản phẩm tiếng Anh, lấy từ bảng translation (ví dụ: "telephony") |
| `product_name_length` | INTEGER | Số ký tự trong tên sản phẩm (chỉ số về độ dài mô tả) |
| `product_description_length` | INTEGER | Số ký tự trong mô tả sản phẩm |
| `product_photos_qty` | INTEGER | Số lượng ảnh sản phẩm |
| `product_weight_g` | INTEGER | Trọng lượng sản phẩm (grams) - NULL nếu không biết |
| `product_length_cm` | NUMERIC | Chiều dài sản phẩm (centimeters) - NULL nếu không biết |
| `product_height_cm` | NUMERIC | Chiều cao sản phẩm (centimeters) - NULL nếu không biết |
| `product_width_cm` | NUMERIC | Chiều rộng sản phẩm (centimeters) - NULL nếu không biết |
| `product_volume_cm3` | NUMERIC | Thể tích sản phẩm (cubic centimeters) - NULL nếu không biết |

**Cách sử dụng**: Join với `fact_order_item_sales` qua `product_key`.

**Ví dụ**: 
- Phân tích doanh số theo danh mục sản phẩm
- Nghiên cứu mối tương quan giữa số lượng ảnh và tỷ lệ bán hàng
- Phân tích logistics dựa trên trọng lượng/thể tích sản phẩm
- Xác định sản phẩm có chất lượng mô tả cao/thấp

---

### 1.5 dim_geolocation (Địa lý)

**Mục đích**: Lưu trữ thông tin địa lý theo mã bưu chính (zip code prefix). Được khử trùng lặp vì một zip code prefix có thể có nhiều thành phố.

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa |
|-----------|------------|---------|
| `geolocation_key` | BIGSERIAL PRIMARY KEY | Khóa chính thay thế |
| `zip_code_prefix` | TEXT UNIQUE | 5 chữ số đầu tiên của mã bưu chính - khóa tự nhiên |
| `geolocation_city` | TEXT | Thành phố (ví dụ: "sao paulo") |
| `geolocation_state` | TEXT | Tỉnh/Bang (ví dụ: "SP") |
| `geolocation_lat` | NUMERIC(12, 8) | Vĩ độ - tọa độ trung bình của zip code |
| `geolocation_lng` | NUMERIC(12, 8) | Kinh độ - tọa độ trung bình của zip code |
| `source_record_count` | INTEGER | Số bản ghi nguồn dùng để tính tọa độ trung bình |

**Cách sử dụng**: Join từ `dim_customer` hoặc `dim_seller` qua `zip_code_prefix`. Không join trực tiếp từ fact table mà thông qua dimension khác.

**Ví dụ**: 
- Vẽ bản đồ heatmap doanh số theo tỉnh/thành phố
- Tính khoảng cách giao hàng từ người bán đến khách hàng
- Phân tích hiệu suất logistics theo vùng địa lý

---

### 1.6 dim_order_status (Trạng thái đơn hàng)

**Mục đích**: Bảng kích thước nhỏ chứa các giá trị trạng thái đơn hàng có thể có.

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa |
|-----------|------------|---------|
| `order_status_key` | BIGSERIAL PRIMARY KEY | Khóa chính thay thế |
| `order_status` | TEXT UNIQUE | Trạng thái đơn hàng (ví dụ: "pending", "shipped", "delivered", "cancelled", "unavailable") |

**Giá trị tiêu biểu**:
- `pending`: Đơn hàng chưa được xác nhận
- `approved`: Đơn hàng được xác nhận nhưng chưa giao cho đơn vị vận chuyển
- `shipped`: Đơn hàng đã giao cho đơn vị vận chuyển
- `delivered`: Đơn hàng đã giao cho khách hàng
- `cancelled`: Đơn hàng bị hủy
- `unavailable`: Sản phẩm không còn sẵn

**Cách sử dụng**: Join với bảng sự kiện qua `order_status_key`.

**Ví dụ**: Phân tích tỷ lệ hủy đơn hàng, thời gian trung bình ở mỗi trạng thái, hoặc xác định bottleneck trong quy trình xử lý đơn hàng.

---

### 1.7 dim_payment_type (Loại thanh toán)

**Mục đích**: Bảng kích thước nhỏ chứa các loại phương thức thanh toán.

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa |
|-----------|------------|---------|
| `payment_type_key` | BIGSERIAL PRIMARY KEY | Khóa chính thay thế |
| `payment_type` | TEXT UNIQUE | Loại thanh toán (ví dụ: "credit_card", "boleto", "voucher", "debit_card") |

**Giá trị tiêu biểu**:
- `credit_card`: Thẻ tín dụng
- `boleto`: Hóa đơn thanh toán (phương thức thanh toán phổ biến ở Brazil)
- `debit_card`: Thẻ ghi nợ
- `voucher`: Phiếu giảm giá

**Cách sử dụng**: Join với `fact_payments` qua `payment_type_key`.

**Ví dụ**: Phân tích tỷ lệ sử dụng mỗi phương thức thanh toán, mức rủi ro theo loại thanh toán, hoặc phía ưa thích thanh toán của khách hàng.

---

## 2. Bảng Sự Kiện (Facts)

Tất cả bảng sự kiện được thiết kế với hạt (grain) rõ ràng:

### 2.1 fact_order_item_sales (Doanh số theo mặt hàng)

**Hạt (Grain)**: 1 dòng = 1 sản phẩm trong 1 đơn hàng

**Mục đích**: Lưu trữ chi tiết từng mặt hàng bán hàng, cho phép phân tích doanh số ở mức mặt hàng.

**Khóa**:
- `order_item_sales_key` (BIGSERIAL PRIMARY KEY): Khóa chính thay thế
- `order_id + order_item_id` (UNIQUE): Khóa tự nhiên (đơn hàng + vị trí mặt hàng trong đơn)

**Khóa ngoại (Foreign Keys)**:
| Khóa ngoại | Tham chiếu | Ý nghĩa |
|----------|----------|---------|
| `customer_key` | dim_customer | Khách hàng mua hàng |
| `seller_key` | dim_seller | Người bán sản phẩm |
| `product_key` | dim_product | Sản phẩm được bán |
| `customer_geolocation_key` | dim_geolocation | Địa lý của khách hàng |
| `seller_geolocation_key` | dim_geolocation | Địa lý của người bán |
| `order_status_key` | dim_order_status | Trạng thái đơn hàng hiện tại |
| `purchase_date_key` | dim_date | Ngày mua hàng |
| `shipping_limit_date_key` | dim_date | Hạn chót giao hàng |

**Chỉ số (Measures)**:
| Chỉ số | Kiểu dữ liệu | Ý nghĩa |
|------|------------|---------|
| `price` | NUMERIC(12, 2) | Giá bán sản phẩm (BRL - Real Brazil) |
| `freight_value` | NUMERIC(12, 2) | Chi phí vận chuyển cho sản phẩm này |
| `total_item_value` | NUMERIC(12, 2) | Tổng giá trị = price + freight_value |

**Thuộc tính khác (Attributes)**:
| Thuộc tính | Ý nghĩa |
|----------|---------|
| `order_id` | ID đơn hàng (lưu lại để tra cứu dễ dàng) |
| `order_item_id` | Vị trí mặt hàng trong đơn hàng (1, 2, 3, ...) |
| `customer_id` | ID khách hàng (lưu lại để tra cứu) |
| `seller_id` | ID người bán (lưu lại để tra cứu) |
| `product_id` | ID sản phẩm (lưu lại để tra cứu) |
| `order_purchase_timestamp` | Thời điểm mua hàng chính xác |
| `shipping_limit_date` | Hạn chót giao hàng chính xác |

**Ví dụ truy vấn**:
```sql
-- Doanh số hàng tháng theo danh mục sản phẩm
SELECT 
    d.month_name,
    p.product_category_name,
    SUM(f.total_item_value) as revenue,
    COUNT(*) as item_count
FROM fact_order_item_sales f
JOIN dim_date d ON f.purchase_date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY d.month_name, p.product_category_name;

-- Top 10 seller theo số lượng mặt hàng bán ra
SELECT 
    s.seller_id,
    s.seller_city,
    COUNT(*) as item_count,
    SUM(f.total_item_value) as total_revenue
FROM fact_order_item_sales f
JOIN dim_seller s ON f.seller_key = s.seller_key
GROUP BY s.seller_id, s.seller_city
ORDER BY item_count DESC
LIMIT 10;
```

---

### 2.2 fact_order_delivery (Vận chuyển đơn hàng)

**Hạt (Grain)**: 1 dòng = 1 đơn hàng

**Mục đích**: Lưu trữ tất cả thông tin về quy trình vận chuyển và giao hàng. Cho phép phân tích hiệu suất logistics.

**Khóa**:
- `order_delivery_key` (BIGSERIAL PRIMARY KEY): Khóa chính thay thế
- `order_id` (UNIQUE): Khóa tự nhiên (mỗi đơn hàng chỉ giao 1 lần)

**Khóa ngoại**:
| Khóa ngoại | Tham chiếu | Ý nghĩa |
|----------|----------|---------|
| `customer_key` | dim_customer | Khách hàng nhận hàng |
| `customer_geolocation_key` | dim_geolocation | Địa lý giao hàng |
| `order_status_key` | dim_order_status | Trạng thái hiện tại của đơn hàng |
| `purchase_date_key` | dim_date | Ngày mua hàng |
| `approved_date_key` | dim_date | Ngày xác nhận đơn hàng |
| `delivered_carrier_date_key` | dim_date | Ngày giao cho vận chuyển |
| `delivered_customer_date_key` | dim_date | Ngày giao cho khách hàng |
| `estimated_delivery_date_key` | dim_date | Ngày dự kiến giao |

**Chỉ số (Measures) - Thời gian (tính bằng giờ hoặc ngày)**:
| Chỉ số | Ý nghĩa | Tính toán |
|------|---------|---------|
| `approval_hours` | Thời gian xác nhận đơn hàng | Từ order_purchase_timestamp đến order_approved_at |
| `carrier_handoff_days` | Thời gian từ mua đến giao cho vận chuyển | Từ order_purchase_timestamp đến order_delivered_carrier_date |
| `delivery_days` | Tổng thời gian giao hàng | Từ order_purchase_timestamp đến order_delivered_customer_date |
| `estimated_delivery_days` | Thời gian giao hàng dự kiến | Từ order_purchase_timestamp đến order_estimated_delivery_date |
| `delay_days` | Số ngày giao trễ (có thể âm nếu giao sớm) | order_delivered_customer_date - order_estimated_delivery_date |

**Chỉ số khác**:
| Chỉ số | Kiểu dữ liệu | Ý nghĩa |
|------|------------|---------|
| `is_late` | BOOLEAN | True nếu giao trễ (delay_days > 0) |

**Thuộc tính khác**:
| Thuộc tính | Ý nghĩa |
|----------|---------|
| `customer_id` | ID khách hàng |
| `order_status` | Trạng thái đơn hàng (lưu lại từ dimension) |
| `order_purchase_timestamp` | Thời điểm mua hàng |
| `order_approved_at` | Thời điểm xác nhận |
| `order_delivered_carrier_date` | Thời điểm giao cho vận chuyển |
| `order_delivered_customer_date` | Thời điểm giao cho khách hàng |
| `order_estimated_delivery_date` | Thời điểm dự kiến giao |

**Ví dụ truy vấn**:
```sql
-- Tỷ lệ đơn hàng giao trễ theo tháng
SELECT 
    d.month_name,
    COUNT(*) as total_orders,
    SUM(CASE WHEN f.is_late THEN 1 ELSE 0 END) as late_orders,
    ROUND(100.0 * SUM(CASE WHEN f.is_late THEN 1 ELSE 0 END) / COUNT(*), 2) as late_rate_percent
FROM fact_order_delivery f
JOIN dim_date d ON f.purchase_date_key = d.date_key
GROUP BY d.month_name
ORDER BY d.month;

-- Phân tích delay_days theo tỉnh khách hàng
SELECT 
    g.geolocation_state,
    AVG(f.delay_days) as avg_delay,
    MIN(f.delivery_days) as min_delivery_time,
    MAX(f.delivery_days) as max_delivery_time
FROM fact_order_delivery f
JOIN dim_geolocation g ON f.customer_geolocation_key = g.geolocation_key
GROUP BY g.geolocation_state
ORDER BY avg_delay DESC;
```

---

### 2.3 fact_payments (Thanh toán)

**Hạt (Grain)**: 1 dòng = 1 bản ghi thanh toán của 1 đơn hàng

**Mục đích**: Lưu trữ chi tiết thanh toán. Một đơn hàng có thể thanh toán qua nhiều lần hoặc nhiều phương thức.

**Khóa**:
- `payment_key` (BIGSERIAL PRIMARY KEY): Khóa chính thay thế
- `order_id + payment_sequential` (UNIQUE): Khóa tự nhiên (đơn hàng + số thứ tự thanh toán)

**Khóa ngoại**:
| Khóa ngoại | Tham chiếu | Ý nghĩa |
|----------|----------|---------|
| `customer_key` | dim_customer | Khách hàng thanh toán |
| `customer_geolocation_key` | dim_geolocation | Địa lý khách hàng |
| `payment_type_key` | dim_payment_type | Loại phương thức thanh toán |
| `order_status_key` | dim_order_status | Trạng thái đơn hàng |
| `purchase_date_key` | dim_date | Ngày mua hàng |

**Chỉ số**:
| Chỉ số | Kiểu dữ liệu | Ý nghĩa |
|------|------------|---------|
| `payment_value` | NUMERIC(12, 2) | Giá trị thanh toán (BRL) |
| `payment_installments` | INTEGER | Số kỳ trả góp (1 = thanh toán 1 lần) |

**Thuộc tính khác**:
| Thuộc tính | Ý nghĩa |
|----------|---------|
| `order_id` | ID đơn hàng |
| `payment_sequential` | Số thứ tự thanh toán (1, 2, 3, ...) |
| `customer_id` | ID khách hàng |
| `payment_type` | Loại thanh toán (lưu lại từ dimension) |

**Lưu ý quan trọng**:
- Một đơn hàng có thể có nhiều bản ghi thanh toán nếu khách hàng thanh toán qua nhiều kỳ hoặc nhiều phương thức
- Tổng `payment_value` của tất cả thanh toán trong một đơn hàng phải bằng tổng giá trị đơn hàng (từ `fact_order_item_sales`)

**Ví dụ truy vấn**:
```sql
-- Doanh số theo loại thanh toán
SELECT 
    pt.payment_type,
    COUNT(DISTINCT f.order_id) as order_count,
    SUM(f.payment_value) as total_revenue,
    AVG(f.payment_installments) as avg_installments
FROM fact_payments f
JOIN dim_payment_type pt ON f.payment_type_key = pt.payment_type_key
GROUP BY pt.payment_type
ORDER BY total_revenue DESC;

-- Phân tích trả góp
SELECT 
    payment_installments,
    COUNT(*) as payment_count,
    SUM(payment_value) as total_value,
    AVG(payment_value) as avg_payment
FROM fact_payments
WHERE payment_installments > 1
GROUP BY payment_installments
ORDER BY payment_installments;
```

---

### 2.4 fact_reviews (Đánh giá/Review)

**Hạt (Grain)**: 1 dòng = 1 review của 1 đơn hàng

**Mục đích**: Lưu trữ thông tin đánh giá của khách hàng, cho phép phân tích mức độ hài lòng.

**Khóa**:
- `review_key` (BIGSERIAL PRIMARY KEY): Khóa chính thay thế
- `review_id + order_id` (UNIQUE): Khóa tự nhiên (review ID + đơn hàng)

**Khóa ngoại**:
| Khóa ngoại | Tham chiếu | Ý nghĩa |
|----------|----------|---------|
| `customer_key` | dim_customer | Khách hàng đánh giá |
| `customer_geolocation_key` | dim_geolocation | Địa lý khách hàng |
| `order_status_key` | dim_order_status | Trạng thái đơn hàng |
| `purchase_date_key` | dim_date | Ngày mua hàng |
| `review_creation_date_key` | dim_date | Ngày viết review |
| `review_answer_date_key` | dim_date | Ngày người bán phản hồi |

**Chỉ số**:
| Chỉ số | Kiểu dữ liệu | Ý nghĩa |
|------|------------|---------|
| `review_score` | INTEGER | Điểm đánh giá (1-5 sao) |
| `review_response_days` | NUMERIC(12, 2) | Số ngày người bán phản hồi |

**Chỉ báo (Boolean Flags)**:
| Chỉ báo | Ý nghĩa |
|--------|---------|
| `has_comment_title` | True nếu có tiêu đề bình luận |
| `has_comment_message` | True nếu có nội dung bình luận chi tiết |

**Thuộc tính khác**:
| Thuộc tính | Ý nghĩa |
|----------|---------|
| `review_id` | ID review |
| `order_id` | ID đơn hàng |
| `customer_id` | ID khách hàng |
| `review_creation_date` | Thời điểm khách hàng viết review |
| `review_answer_timestamp` | Thời điểm người bán phản hồi |

**Lưu ý**:
- Không phải tất cả đơn hàng đều có review (nếu không có thì không có bản ghi trong bảng này)
- Review score từ 1 đến 5, với 5 là đánh giá tốt nhất
- `review_response_days` tính từ ngày khách hàng viết review đến ngày người bán phản hồi
- Khách hàng có thể để tiêu đề hoặc nội dung bình luận trống

**Ví dụ truy vấn**:
```sql
-- Phân tích độ hài lòng khách hàng theo đánh giá sao
SELECT 
    review_score,
    COUNT(*) as review_count,
    COUNT(CASE WHEN has_comment_message THEN 1 END) as reviews_with_comments,
    ROUND(100.0 * COUNT(CASE WHEN has_comment_message THEN 1 END) / COUNT(*), 2) as comment_rate_percent
FROM fact_reviews
GROUP BY review_score
ORDER BY review_score DESC;

-- Đánh giá trung bình theo tháng
SELECT 
    d.month_name,
    AVG(f.review_score) as avg_score,
    AVG(f.review_response_days) as avg_response_time,
    COUNT(*) as total_reviews
FROM fact_reviews f
JOIN dim_date d ON f.review_creation_date_key = d.date_key
GROUP BY d.month_name, d.month
ORDER BY d.month;

-- Phân tích chất lượng phản hồi người bán
SELECT 
    COUNT(*) as total_reviews,
    COUNT(CASE WHEN review_response_days IS NOT NULL THEN 1 END) as answered_reviews,
    AVG(review_response_days) as avg_response_days,
    MAX(review_response_days) as max_response_days
FROM fact_reviews;
```

---

## 3. Nguồn Dữ Liệu và Công Thức Tính Trường DWH

Phần này mô tả rõ từng trường trong các bảng DWH được lấy trực tiếp từ dataset hay được tính trong quá trình ETL. Quy ước:

- **Có sẵn trong dataset**: trường được lấy trực tiếp từ bảng `staging.*`.
- **Tra cứu/join**: trường được sinh bằng cách join sang dimension hoặc bảng nguồn khác.
- **Tính toán**: trường không có sẵn, được tạo bằng công thức trong tầng DWH.
- Các trường thời gian dạng `*_date_key` đều là khóa ngày trong `dim_date`, được tra bằng ngày của timestamp tương ứng.

### 3.1 dim_date

**Ý nghĩa bảng**: Dimension lịch dùng chung cho mọi phân tích theo thời gian. Bảng này không lấy nguyên một bảng ngày có sẵn từ dataset, mà được sinh ra từ khoảng ngày nhỏ nhất đến lớn nhất xuất hiện trong các timestamp của đơn hàng, vận chuyển, hạn giao hàng và review.

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `date_key` | Khóa ngày dạng số để join nhanh với fact | `TO_CHAR(full_date, 'YYYYMMDD')::INTEGER` |
| `full_date` | Ngày đầy đủ | Sinh bằng `generate_series(min_date, max_date, interval '1 day')`, trong đó `min_date` và `max_date` lấy từ tất cả các ngày liên quan trong `olist_orders`, `olist_order_items`, `olist_order_reviews` |
| `year` | Năm của ngày | `EXTRACT(YEAR FROM full_date)` |
| `quarter` | Quý trong năm | `EXTRACT(QUARTER FROM full_date)` |
| `month` | Tháng trong năm | `EXTRACT(MONTH FROM full_date)` |
| `month_name` | Tên tháng tiếng Anh | `TO_CHAR(full_date, 'FMMonth')` |
| `day` | Ngày trong tháng | `EXTRACT(DAY FROM full_date)` |
| `day_of_week` | Thứ trong tuần theo ISO, 1 là thứ 2 và 7 là chủ nhật | `EXTRACT(ISODOW FROM full_date)` |
| `day_name` | Tên thứ tiếng Anh | `TO_CHAR(full_date, 'FMDay')` |
| `is_weekend` | Cờ cuối tuần | `EXTRACT(ISODOW FROM full_date) IN (6, 7)` |

### 3.2 dim_customer

**Ý nghĩa bảng**: Lưu một dòng cho mỗi khách hàng ở cấp `customer_id`, phục vụ phân tích hành vi mua hàng và phân tích địa lý theo nơi ở của khách.

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `customer_key` | Khóa thay thế nội bộ của DWH | Tự sinh bằng `BIGSERIAL` |
| `customer_id` | Mã khách hàng theo từng đơn trong dataset Olist | Có sẵn: `staging.olist_customers.customer_id` |
| `customer_unique_id` | Mã khách hàng duy nhất, có thể gom nhiều `customer_id` của cùng một người | Có sẵn: `staging.olist_customers.customer_unique_id` |
| `customer_zip_code_prefix` | 5 chữ số đầu của mã bưu chính khách hàng | Có sẵn: `staging.olist_customers.customer_zip_code_prefix` |
| `customer_city` | Thành phố của khách hàng | Có sẵn: `staging.olist_customers.customer_city` |
| `customer_state` | Bang/tỉnh của khách hàng | Có sẵn: `staging.olist_customers.customer_state` |

### 3.3 dim_seller

**Ý nghĩa bảng**: Lưu một dòng cho mỗi người bán, dùng để phân tích doanh thu, logistics và hiệu suất theo seller.

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `seller_key` | Khóa thay thế nội bộ của DWH | Tự sinh bằng `BIGSERIAL` |
| `seller_id` | Mã người bán trong dataset | Có sẵn: `staging.olist_sellers.seller_id` |
| `seller_zip_code_prefix` | 5 chữ số đầu của mã bưu chính người bán | Có sẵn: `staging.olist_sellers.seller_zip_code_prefix` |
| `seller_city` | Thành phố của người bán | Có sẵn: `staging.olist_sellers.seller_city` |
| `seller_state` | Bang/tỉnh của người bán | Có sẵn: `staging.olist_sellers.seller_state` |

### 3.4 dim_product

**Ý nghĩa bảng**: Lưu thông tin mô tả sản phẩm, danh mục và đặc tính vật lý để phân tích bán hàng, nội dung sản phẩm và logistics.

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `product_key` | Khóa thay thế nội bộ của DWH | Tự sinh bằng `BIGSERIAL` |
| `product_id` | Mã sản phẩm trong dataset | Có sẵn: `staging.olist_products.product_id` |
| `product_category_name` | Danh mục sản phẩm bằng tiếng Anh | Tra cứu `staging.product_category_name_translation.product_category_name_english` theo `product_category_name`; nếu không có bản dịch thì gán `'Unknown'` |
| `product_name_length` | Độ dài tên sản phẩm | Có sẵn: `staging.olist_products.product_name_lenght` (giữ nguyên lỗi chính tả của dataset nguồn khi đọc staging) |
| `product_description_length` | Độ dài mô tả sản phẩm | Có sẵn: `staging.olist_products.product_description_lenght` |
| `product_photos_qty` | Số ảnh của sản phẩm | Có sẵn: `staging.olist_products.product_photos_qty` |
| `product_weight_g` | Trọng lượng sản phẩm, đơn vị gram | Có sẵn: `staging.olist_products.product_weight_g` |
| `product_length_cm` | Chiều dài sản phẩm, đơn vị cm | Có sẵn: `staging.olist_products.product_length_cm` |
| `product_height_cm` | Chiều cao sản phẩm, đơn vị cm | Có sẵn: `staging.olist_products.product_height_cm` |
| `product_width_cm` | Chiều rộng sản phẩm, đơn vị cm | Có sẵn: `staging.olist_products.product_width_cm` |
| `product_volume_cm3` | Thể tích sản phẩm, đơn vị cm3 | `product_length_cm * product_height_cm * product_width_cm`; kết quả `NULL` nếu một trong ba chiều bị `NULL` |

### 3.5 dim_geolocation

**Ý nghĩa bảng**: Chuẩn hóa dữ liệu địa lý theo `zip_code_prefix`. Dataset geolocation có thể có nhiều dòng cho cùng một prefix, nên DWH gom về một dòng đại diện để join ổn định với customer và seller.

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `geolocation_key` | Khóa thay thế nội bộ của DWH | Tự sinh bằng `BIGSERIAL` |
| `zip_code_prefix` | 5 chữ số đầu của mã bưu chính | Có sẵn: `staging.olist_geolocation.geolocation_zip_code_prefix` |
| `geolocation_city` | Thành phố đại diện của prefix | Chọn city có số dòng xuất hiện nhiều nhất trong cùng `zip_code_prefix`; nếu hòa thì sắp xếp theo `geolocation_state`, `geolocation_city` |
| `geolocation_state` | Bang/tỉnh đại diện của prefix | Đi cùng dòng city được chọn bằng `ROW_NUMBER()` theo tần suất xuất hiện |
| `geolocation_lat` | Vĩ độ đại diện của prefix | `ROUND(AVG(geolocation_lat), 8)` theo `zip_code_prefix` |
| `geolocation_lng` | Kinh độ đại diện của prefix | `ROUND(AVG(geolocation_lng), 8)` theo `zip_code_prefix` |
| `source_record_count` | Số dòng nguồn dùng để tạo dòng địa lý đại diện | `COUNT(*)` theo `zip_code_prefix` |

### 3.6 dim_order_status

**Ý nghĩa bảng**: Dimension nhỏ chứa danh mục trạng thái đơn hàng, giúp chuẩn hóa trạng thái khi join với các fact.

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `order_status_key` | Khóa thay thế nội bộ của DWH | Tự sinh bằng `BIGSERIAL` |
| `order_status` | Trạng thái đơn hàng | Lấy danh sách distinct từ `staging.olist_orders.order_status` |

### 3.7 dim_payment_type

**Ý nghĩa bảng**: Dimension nhỏ chứa danh mục phương thức thanh toán, dùng cho phân tích thanh toán và hành vi khách hàng.

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `payment_type_key` | Khóa thay thế nội bộ của DWH | Tự sinh bằng `BIGSERIAL` |
| `payment_type` | Loại phương thức thanh toán | Lấy danh sách distinct từ `staging.olist_order_payments.payment_type` |

### 3.8 fact_order_item_sales

**Ý nghĩa bảng**: Fact doanh số ở cấp mặt hàng trong đơn hàng. Đây là bảng chính để tính doanh thu theo sản phẩm, seller, khách hàng, thời gian và khu vực.

**Hạt dữ liệu**: 1 dòng = 1 `order_item_id` trong 1 `order_id`.

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `order_item_sales_key` | Khóa thay thế của fact | Tự sinh bằng `BIGSERIAL` |
| `order_id` | Mã đơn hàng | Có sẵn: `staging.olist_order_items.order_id` |
| `order_item_id` | Số thứ tự mặt hàng trong đơn | Có sẵn: `staging.olist_order_items.order_item_id` |
| `customer_key` | Khóa khách hàng mua đơn | Join `staging.olist_orders.customer_id` sang `dwh.dim_customer.customer_id` |
| `seller_key` | Khóa người bán của mặt hàng | Join `staging.olist_order_items.seller_id` sang `dwh.dim_seller.seller_id` |
| `product_key` | Khóa sản phẩm được bán | Join `staging.olist_order_items.product_id` sang `dwh.dim_product.product_id` |
| `customer_geolocation_key` | Khóa địa lý của khách hàng | Join `dim_customer.customer_zip_code_prefix` sang `dwh.dim_geolocation.zip_code_prefix` |
| `seller_geolocation_key` | Khóa địa lý của người bán | Join `dim_seller.seller_zip_code_prefix` sang `dwh.dim_geolocation.zip_code_prefix` |
| `order_status_key` | Khóa trạng thái đơn hàng | Join `staging.olist_orders.order_status` sang `dwh.dim_order_status.order_status` |
| `purchase_date_key` | Ngày mua hàng ở dạng khóa ngày | Join `dwh.dim_date.full_date = order_purchase_timestamp::DATE` |
| `shipping_limit_date_key` | Ngày hạn giao hàng ở dạng khóa ngày | Join `dwh.dim_date.full_date = shipping_limit_date::DATE` |
| `customer_id` | Mã khách hàng lưu lại để tra cứu nhanh | Có sẵn sau khi join `staging.olist_orders.customer_id` |
| `seller_id` | Mã người bán lưu lại để tra cứu nhanh | Có sẵn: `staging.olist_order_items.seller_id` |
| `product_id` | Mã sản phẩm lưu lại để tra cứu nhanh | Có sẵn: `staging.olist_order_items.product_id` |
| `order_purchase_timestamp` | Thời điểm khách đặt hàng | Có sẵn: `staging.olist_orders.order_purchase_timestamp` |
| `shipping_limit_date` | Hạn giao hàng của seller cho đơn vị vận chuyển | Có sẵn: `staging.olist_order_items.shipping_limit_date` |
| `price` | Giá bán của mặt hàng, chưa gồm phí vận chuyển | Có sẵn: `staging.olist_order_items.price` |
| `freight_value` | Phí vận chuyển phân bổ cho mặt hàng | Có sẵn: `staging.olist_order_items.freight_value` |
| `total_item_value` | Tổng giá trị mặt hàng gồm hàng và vận chuyển | `price + freight_value` |

### 3.9 fact_order_delivery

**Ý nghĩa bảng**: Fact vận chuyển ở cấp đơn hàng, phục vụ phân tích tốc độ xử lý đơn, tốc độ giao hàng, giao sớm/trễ và hiệu suất logistics.

**Hạt dữ liệu**: 1 dòng = 1 `order_id`.

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `order_delivery_key` | Khóa thay thế của fact | Tự sinh bằng `BIGSERIAL` |
| `order_id` | Mã đơn hàng | Có sẵn: `staging.olist_orders.order_id` |
| `customer_key` | Khóa khách nhận hàng | Join `staging.olist_orders.customer_id` sang `dwh.dim_customer.customer_id` |
| `customer_geolocation_key` | Khóa địa lý giao hàng của khách | Join `dim_customer.customer_zip_code_prefix` sang `dwh.dim_geolocation.zip_code_prefix` |
| `order_status_key` | Khóa trạng thái đơn hàng | Join `staging.olist_orders.order_status` sang `dwh.dim_order_status.order_status` |
| `purchase_date_key` | Ngày mua hàng ở dạng khóa ngày | Join `dwh.dim_date.full_date = order_purchase_timestamp::DATE` |
| `approved_date_key` | Ngày đơn được phê duyệt ở dạng khóa ngày | Join `dwh.dim_date.full_date = order_approved_at::DATE` |
| `delivered_carrier_date_key` | Ngày giao cho đơn vị vận chuyển ở dạng khóa ngày | Join `dwh.dim_date.full_date = order_delivered_carrier_date::DATE` |
| `delivered_customer_date_key` | Ngày giao đến khách ở dạng khóa ngày | Join `dwh.dim_date.full_date = order_delivered_customer_date::DATE` |
| `estimated_delivery_date_key` | Ngày dự kiến giao ở dạng khóa ngày | Join `dwh.dim_date.full_date = order_estimated_delivery_date::DATE` |
| `customer_id` | Mã khách hàng lưu lại để tra cứu nhanh | Có sẵn: `staging.olist_orders.customer_id` |
| `order_status` | Trạng thái đơn hàng lưu lại để tra cứu nhanh | Có sẵn: `staging.olist_orders.order_status` |
| `order_purchase_timestamp` | Thời điểm khách đặt hàng | Có sẵn: `staging.olist_orders.order_purchase_timestamp` |
| `order_approved_at` | Thời điểm đơn được phê duyệt | Có sẵn: `staging.olist_orders.order_approved_at` |
| `order_delivered_carrier_date` | Thời điểm giao cho đơn vị vận chuyển | Có sẵn: `staging.olist_orders.order_delivered_carrier_date` |
| `order_delivered_customer_date` | Thời điểm giao đến khách | Có sẵn: `staging.olist_orders.order_delivered_customer_date` |
| `order_estimated_delivery_date` | Thời điểm dự kiến giao | Có sẵn: `staging.olist_orders.order_estimated_delivery_date` |
| `approval_hours` | Số giờ từ lúc đặt hàng đến lúc phê duyệt | `ROUND(EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp)) / 3600.0, 2)`; `NULL` nếu thiếu một trong hai timestamp |
| `carrier_handoff_days` | Số ngày từ lúc đặt hàng đến lúc giao cho đơn vị vận chuyển | `ROUND(EXTRACT(EPOCH FROM (order_delivered_carrier_date - order_purchase_timestamp)) / 86400.0, 2)`; `NULL` nếu thiếu timestamp |
| `delivery_days` | Số ngày từ lúc đặt hàng đến lúc giao đến khách | `ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400.0, 2)`; `NULL` nếu chưa giao hoặc thiếu timestamp |
| `estimated_delivery_days` | Số ngày giao hàng dự kiến tính từ lúc đặt hàng | `ROUND(EXTRACT(EPOCH FROM (order_estimated_delivery_date - order_purchase_timestamp)) / 86400.0, 2)`; `NULL` nếu thiếu timestamp |
| `delay_days` | Số ngày giao trễ so với dự kiến; âm nghĩa là giao sớm | `ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_estimated_delivery_date)) / 86400.0, 2)`; `NULL` nếu thiếu timestamp |
| `is_late` | Cờ đơn hàng giao trễ | `order_delivered_customer_date > order_estimated_delivery_date`; `NULL` nếu chưa đủ dữ liệu để so sánh |

### 3.10 fact_payments

**Ý nghĩa bảng**: Fact thanh toán ở cấp từng bản ghi thanh toán của đơn hàng. Một đơn có thể có nhiều dòng thanh toán do nhiều lần thanh toán hoặc nhiều phương thức.

**Hạt dữ liệu**: 1 dòng = 1 `payment_sequential` của 1 `order_id`.

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `payment_key` | Khóa thay thế của fact | Tự sinh bằng `BIGSERIAL` |
| `order_id` | Mã đơn hàng | Có sẵn: `staging.olist_order_payments.order_id` |
| `payment_sequential` | Số thứ tự bản ghi thanh toán trong đơn | Có sẵn: `staging.olist_order_payments.payment_sequential` |
| `customer_key` | Khóa khách hàng thanh toán | Join `staging.olist_orders.customer_id` sang `dwh.dim_customer.customer_id` |
| `customer_geolocation_key` | Khóa địa lý khách hàng | Join `dim_customer.customer_zip_code_prefix` sang `dwh.dim_geolocation.zip_code_prefix` |
| `payment_type_key` | Khóa phương thức thanh toán | Join `staging.olist_order_payments.payment_type` sang `dwh.dim_payment_type.payment_type` |
| `order_status_key` | Khóa trạng thái đơn hàng | Join `staging.olist_orders.order_status` sang `dwh.dim_order_status.order_status` |
| `purchase_date_key` | Ngày mua hàng ở dạng khóa ngày | Join `dwh.dim_date.full_date = order_purchase_timestamp::DATE` |
| `customer_id` | Mã khách hàng lưu lại để tra cứu nhanh | Có sẵn sau khi join `staging.olist_orders.customer_id` |
| `payment_type` | Loại thanh toán lưu lại để tra cứu nhanh | Có sẵn: `staging.olist_order_payments.payment_type` |
| `payment_installments` | Số kỳ trả góp | Có sẵn: `staging.olist_order_payments.payment_installments` |
| `payment_value` | Giá trị thanh toán | Có sẵn: `staging.olist_order_payments.payment_value` |

### 3.11 fact_reviews

**Ý nghĩa bảng**: Fact đánh giá khách hàng ở cấp review của đơn hàng, dùng để phân tích mức độ hài lòng, tỷ lệ có bình luận và tốc độ phản hồi.

**Hạt dữ liệu**: 1 dòng = 1 `review_id` gắn với 1 `order_id`.

| Trường | Ý nghĩa | Nguồn/công thức |
|---|---|---|
| `review_key` | Khóa thay thế của fact | Tự sinh bằng `BIGSERIAL` |
| `review_id` | Mã review | Có sẵn: `staging.olist_order_reviews.review_id` |
| `order_id` | Mã đơn hàng được review | Có sẵn: `staging.olist_order_reviews.order_id` |
| `customer_key` | Khóa khách hàng đánh giá | Join `staging.olist_orders.customer_id` sang `dwh.dim_customer.customer_id` |
| `customer_geolocation_key` | Khóa địa lý khách hàng | Join `dim_customer.customer_zip_code_prefix` sang `dwh.dim_geolocation.zip_code_prefix` |
| `order_status_key` | Khóa trạng thái đơn hàng | Join `staging.olist_orders.order_status` sang `dwh.dim_order_status.order_status` |
| `purchase_date_key` | Ngày mua hàng ở dạng khóa ngày | Join `dwh.dim_date.full_date = order_purchase_timestamp::DATE` |
| `review_creation_date_key` | Ngày tạo review ở dạng khóa ngày | Join `dwh.dim_date.full_date = review_creation_date::DATE` |
| `review_answer_date_key` | Ngày phản hồi review ở dạng khóa ngày | Join `dwh.dim_date.full_date = review_answer_timestamp::DATE` |
| `customer_id` | Mã khách hàng lưu lại để tra cứu nhanh | Có sẵn sau khi join `staging.olist_orders.customer_id` |
| `review_score` | Điểm đánh giá từ 1 đến 5 | Có sẵn: `staging.olist_order_reviews.review_score` |
| `has_comment_title` | Cờ cho biết review có tiêu đề hay không | `NULLIF(BTRIM(review_comment_title), '') IS NOT NULL` |
| `has_comment_message` | Cờ cho biết review có nội dung chi tiết hay không | `NULLIF(BTRIM(review_comment_message), '') IS NOT NULL` |
| `review_creation_date` | Thời điểm tạo review | Có sẵn: `staging.olist_order_reviews.review_creation_date` |
| `review_answer_timestamp` | Thời điểm seller/hệ thống phản hồi review | Có sẵn: `staging.olist_order_reviews.review_answer_timestamp` |
| `review_response_days` | Số ngày từ lúc khách tạo review đến lúc có phản hồi | `ROUND(EXTRACT(EPOCH FROM (review_answer_timestamp - review_creation_date)) / 86400.0, 2)`; `NULL` nếu thiếu một trong hai timestamp |

### 3.12 Lưu ý về trường `NULL` và công thức

- Với các trường lấy từ dataset, nếu dữ liệu nguồn là `NULL` thì DWH giữ `NULL`, trừ các trường có xử lý riêng như `product_category_name` được gán `'Unknown'` khi không có bản dịch.
- Với các công thức thời gian, DWH chỉ tính khi đủ các timestamp cần thiết. Nếu thiếu dữ liệu, kết quả là `NULL` để tránh tạo số liệu sai.
- Với các khóa ngoại, nếu không tìm thấy bản ghi dimension tương ứng thì khóa có thể là `NULL` do ETL dùng `LEFT JOIN`. Điều này giúp không làm mất dòng fact, nhưng cần kiểm tra chất lượng dữ liệu khi phân tích.
- Các trường như `order_id`, `customer_id`, `seller_id`, `product_id`, `payment_type`, `order_status` được lưu lại trong fact như degenerate/reference attributes để tra cứu nhanh; các phân tích chuẩn vẫn nên join bằng các khóa `*_key`.

---

## 4. Mối Quan Hệ Giữa Các Bảng

### 4.1 Liên kết giữa Fact Tables

```
fact_order_item_sales
└── order_id ──→ fact_order_delivery (1:1)
                  fact_payments (1:N)
                  fact_reviews (1:N)
```

**Ví dụ**: Từ 1 dòng trong `fact_order_item_sales`, có thể:
- Tìm 1 bản ghi giao hàng trong `fact_order_delivery`
- Tìm 1 hoặc nhiều bản ghi thanh toán trong `fact_payments`
- Tìm 0 hoặc 1 review trong `fact_reviews`

### 4.2 Liên kết từ Role-Playing Dimension

`dim_date` được sử dụng với các khóa ngày khác nhau. Ví dụ trong `fact_order_delivery`:

```sql
SELECT 
    o.order_id,
    purchase.full_date as purchase_date,
    approved.full_date as approved_date,
    delivered.full_date as delivered_date,
    estimated.full_date as estimated_date
FROM fact_order_delivery o
JOIN dim_date purchase ON o.purchase_date_key = purchase.date_key
JOIN dim_date approved ON o.approved_date_key = approved.date_key
JOIN dim_date delivered ON o.delivered_customer_date_key = delivered.date_key
JOIN dim_date estimated ON o.estimated_delivery_date_key = estimated.date_key
```

---

## 5. Quy Ước Thiết Kế

### 5.1 Khóa Chính (Primary Keys)
- Sử dụng **surrogate key** (BIGSERIAL) thay vì khóa tự nhiên cho tất cả bảng chiều và sự kiện
- Giúp tối ưu hóa join và tiết kiệm không gian lưu trữ

### 5.2 Khóa Ngoại (Foreign Keys)
- Tất cả `*_key` trong fact table đều có ràng buộc foreign key tương ứng
- Đảm bảo tính toàn vẹn dữ liệu

### 5.3 Dữ Liệu Khóa (Degenerate Dimension)
- Các thuộc tính như `order_id`, `customer_id`, `product_id` được lưu lại trong fact table
- Giúp tra cứu dễ dàng mà không cần join với dimension

### 5.4 Khóa Ngày (Date Key)
- Format: `YYYYMMDD` (ví dụ: 20240115 cho 15 tháng 1 năm 2024)
- Tối ưu hóa hiệu suất so với so sánh DATE hoặc TIMESTAMP

---

## 6. Khuyến Nghị Sử Dụng

### Phân tích Bán hàng
Dùng: `fact_order_item_sales` + `dim_product` + `dim_date`

### Phân tích Vận chuyển
Dùng: `fact_order_delivery` + `dim_customer` + `dim_geolocation` + `dim_date`

### Phân tích Thanh toán
Dùng: `fact_payments` + `dim_payment_type` + `dim_customer` + `dim_date`

### Phân tích Hài lòng Khách hàng
Dùng: `fact_reviews` + `dim_customer` + `dim_date`

### Phân tích Hiệu suất Người bán
Dùng: `fact_order_item_sales` + `dim_seller` + `dim_geolocation` + `dim_date`

---

## 7. Lưu Ý Kỹ Thuật

- **Null Values**: Nhiều trường có thể là NULL (ví dụ: trọng lượng sản phẩm, tọa độ địa lý). Cần xử lý cẩn thận trong truy vấn
- **Aggregation**: Khi join fact tables khác nhau, cần chú ý đến granularity (hạt) của mỗi bảng
- **Performance**: Sử dụng indexes (được tạo trong `04_create_indexes.sql`) để tối ưu hóa hiệu suất truy vấn
- **Updates**: Các dimension được thiết kế là slowly changing dimension Type 1 (chỉ cập nhật giá trị, không giữ lịch sử)
