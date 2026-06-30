# ML Result Analysis

## 1. Random Forest: Negative Review Prediction

Model objective: predict whether an order/review is likely to become a negative review, defined as review score <= 2.

### Dataset

- Rows used: 99,224
- Negative review rate: 14.69%

### Model Performance

- Accuracy: 84.72%
- Precision: 48.30%
- Recall: 57.05%
- F1-score: 52.32%
- ROC-AUC: 78.80%

Confusion matrix:

| | Predicted non-negative | Predicted negative |
|---|---:|---:|
| Actual non-negative | 18,937 | 2,225 |
| Actual negative | 1,565 | 2,079 |

### Interpretation

The model has moderate discrimination power with ROC-AUC around 78.80%. Recall for negative reviews is 57.05%, meaning it captures a meaningful but incomplete share of bad-review cases. Precision is still limited because negative reviews remain a minority class, so some predicted risky orders are false alarms.

For business use, this model is more suitable as an early warning/risk ranking tool than as a strict automatic decision system.

### Top Drivers

- `delay_days`: 0.1469
- `delivery_days`: 0.1383
- `order_status_delivered`: 0.1235
- `is_late_False`: 0.0917
- `is_late_True`: 0.0911
- `order_item_count`: 0.0488
- `order_status_shipped`: 0.0313
- `carrier_handoff_days`: 0.0295
- `total_freight_value`: 0.0249
- `product_count`: 0.0211

The strongest signals are related to delivery delay and order status. This supports the BSC narrative that customer dissatisfaction is closely connected to internal process and logistics performance.

Recommended actions:

- Prioritize orders with late delivery or high delay days for proactive support.
- Monitor sellers/categories that repeatedly produce delayed or high-risk orders.
- Use the prediction probability as a risk score, not just a binary label.

## 2. K-Means: Seller Segmentation

Model objective: group sellers by business value and operational health.

### Dataset

- Sellers used: 1,796
- Selected k: 2

### k Selection

- k=2: silhouette 0.3035, inertia 18,494.07
- k=3: silhouette 0.2115, inertia 16,005.91
- k=4: silhouette 0.2122, inertia 14,109.14
- k=5: silhouette 0.2233, inertia 12,463.53
- k=6: silhouette 0.1913, inertia 11,686.08
- k=7: silhouette 0.1713, inertia 10,977.32
- k=8: silhouette 0.1764, inertia 10,399.58

k = 2 is used as the main model because it has the highest silhouette score. Higher k values reduce inertia, but their silhouette scores are lower, so the clusters become less clean.

### Segment Summary

- High-Value Watchlist Sellers: 607 sellers, GMV 10,577,202.61, avg review 4.08, avg late rate 8.16%
- Emerging Sellers: 1,189 sellers, GMV 2,446,683.73, avg review 4.13, avg late rate 8.09%

### Interpretation

K-Means selected k = 2 based on silhouette score. The current result separates sellers mainly by scale/value. The high-GMV segment contributes most of the marketplace value, but its review and late-delivery signals should still be watched, so the segment should be treated as a management watchlist rather than a removal list.

Recommended actions:

- High-Value Watchlist Sellers: keep and prioritize because they drive high GMV, but monitor late delivery and low review signals.
- Emerging Sellers: lower GMV but relatively healthy profile; support them with exposure or seller development programs.
- For presentation, k = 4 can be used as an exploratory business view if the story needs more seller personas, but k = 2 is the cleanest separation according to the current silhouette score.

### Exploratory k = 4 View

- Problem Sellers: 253 sellers, GMV 468,258.61, avg review 3.28, avg late rate 18.21%, low review rate 36.77%
- High-Value Core Sellers: 367 sellers, GMV 8,554,901.20, avg review 4.05, avg late rate 8.36%, low review rate 15.74%
- Healthy Emerging Sellers: 608 sellers, GMV 566,363.87, avg review 4.42, avg late rate 4.79%, low review rate 6.89%
- Growth Sellers: 568 sellers, GMV 3,434,362.66, avg review 4.19, avg late rate 7.04%, low review rate 12.46%

This view is useful for business storytelling because it surfaces more seller personas, but it should be presented as exploratory because its silhouette score is lower than k = 2.

## Visuals

- `negative_review_feature_importance.png`
- `negative_review_confusion_matrix.png`
- `seller_segment_gmv.png`
- `seller_kmeans_silhouette.png`
