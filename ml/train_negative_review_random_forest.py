from __future__ import annotations

import json

import joblib
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder

from common import MODEL_DIR, OUTPUT_DIR, ensure_ml_dirs, load_dataframe


ID_COLUMNS = ["review_id", "order_id", "review_score"]
TARGET = "is_negative_review"

NUMERIC_FEATURES = [
    "approval_hours",
    "carrier_handoff_days",
    "delivery_days",
    "estimated_delivery_days",
    "delay_days",
    "order_item_count",
    "product_count",
    "seller_count",
    "total_price",
    "total_freight_value",
    "avg_item_price",
    "freight_to_price_pct",
    "total_payment_value",
    "max_payment_installments",
    "product_name_length",
    "product_description_length",
    "product_photos_qty",
    "product_weight_g",
    "product_volume_cm3",
    "year",
    "month",
]

CATEGORICAL_FEATURES = [
    "is_late",
    "order_status",
    "payment_type",
    "product_category_name",
    "seller_state",
    "customer_state",
]


def build_pipeline() -> Pipeline:
    numeric_pipe = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="median")),
        ]
    )
    categorical_pipe = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="constant", fill_value="Unknown")),
            ("onehot", OneHotEncoder(handle_unknown="ignore", min_frequency=20)),
        ]
    )
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", numeric_pipe, NUMERIC_FEATURES),
            ("cat", categorical_pipe, CATEGORICAL_FEATURES),
        ],
        remainder="drop",
    )
    classifier = RandomForestClassifier(
        n_estimators=300,
        max_depth=14,
        min_samples_leaf=10,
        class_weight="balanced",
        random_state=42,
        n_jobs=-1,
    )
    return Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("model", classifier),
        ]
    )


def get_feature_names(pipeline: Pipeline) -> list[str]:
    preprocessor = pipeline.named_steps["preprocessor"]
    numeric_names = list(NUMERIC_FEATURES)
    categorical_names = list(
        preprocessor.named_transformers_["cat"]
        .named_steps["onehot"]
        .get_feature_names_out(CATEGORICAL_FEATURES)
    )
    return numeric_names + categorical_names


def main() -> None:
    ensure_ml_dirs()
    df = load_dataframe("negative_review_features.sql")
    df = df.dropna(subset=[TARGET]).copy()

    for col in NUMERIC_FEATURES:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    for col in CATEGORICAL_FEATURES:
        df[col] = df[col].replace({pd.NA: np.nan}).fillna("Unknown").astype(str)

    X = df[NUMERIC_FEATURES + CATEGORICAL_FEATURES]
    y = df[TARGET].astype(int)

    X_train, X_test, y_train, y_test, idx_train, idx_test = train_test_split(
        X,
        y,
        df.index,
        test_size=0.25,
        stratify=y,
        random_state=42,
    )

    pipeline = build_pipeline()
    pipeline.fit(X_train, y_train)

    y_pred = pipeline.predict(X_test)
    y_proba = pipeline.predict_proba(X_test)[:, 1]

    metrics = {
        "row_count": int(len(df)),
        "negative_review_rate": float(y.mean()),
        "accuracy": float(accuracy_score(y_test, y_pred)),
        "precision": float(precision_score(y_test, y_pred, zero_division=0)),
        "recall": float(recall_score(y_test, y_pred, zero_division=0)),
        "f1": float(f1_score(y_test, y_pred, zero_division=0)),
        "roc_auc": float(roc_auc_score(y_test, y_proba)),
        "confusion_matrix": confusion_matrix(y_test, y_pred).tolist(),
        "classification_report": classification_report(y_test, y_pred, zero_division=0),
    }

    feature_names = get_feature_names(pipeline)
    importances = pipeline.named_steps["model"].feature_importances_
    feature_importance = (
        pd.DataFrame({"feature": feature_names, "importance": importances})
        .sort_values("importance", ascending=False)
        .reset_index(drop=True)
    )

    predictions = df.loc[idx_test, ID_COLUMNS].copy()
    predictions["actual_is_negative_review"] = y_test.to_numpy()
    predictions["predicted_is_negative_review"] = y_pred
    predictions["negative_review_probability"] = y_proba
    predictions = predictions.sort_values("negative_review_probability", ascending=False)

    joblib.dump(pipeline, MODEL_DIR / "negative_review_rf.joblib")
    predictions.to_csv(OUTPUT_DIR / "negative_review_predictions.csv", index=False)
    feature_importance.to_csv(OUTPUT_DIR / "negative_review_feature_importance.csv", index=False)
    (OUTPUT_DIR / "negative_review_metrics.json").write_text(
        json.dumps(metrics, indent=2), encoding="utf-8"
    )

    print(json.dumps(metrics, indent=2))
    print("\nTop feature importance:")
    print(feature_importance.head(20).to_string(index=False))


if __name__ == "__main__":
    main()
