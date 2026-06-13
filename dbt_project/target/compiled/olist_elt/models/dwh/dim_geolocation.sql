

WITH geo_aggregates AS (
    SELECT
        geolocation_zip_code_prefix AS zip_code_prefix,
        ROUND(AVG(geolocation_lat)::NUMERIC, 8) AS geolocation_lat,
        ROUND(AVG(geolocation_lng)::NUMERIC, 8) AS geolocation_lng,
        COUNT(*)::INTEGER AS source_record_count
    FROM "olist_db"."staging"."olist_geolocation"
    WHERE geolocation_zip_code_prefix IS NOT NULL
    GROUP BY geolocation_zip_code_prefix
),
geo_city_state_ranked AS (
    SELECT
        geolocation_zip_code_prefix AS zip_code_prefix,
        geolocation_city,
        geolocation_state,
        ROW_NUMBER() OVER (
            PARTITION BY geolocation_zip_code_prefix
            ORDER BY COUNT(*) DESC, geolocation_state, geolocation_city
        ) AS location_rank
    FROM "olist_db"."staging"."olist_geolocation"
    WHERE geolocation_zip_code_prefix IS NOT NULL
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state
)
SELECT
    md5(cast(coalesce(cast(a.zip_code_prefix as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS geolocation_key,
    a.zip_code_prefix,
    r.geolocation_city,
    r.geolocation_state,
    a.geolocation_lat,
    a.geolocation_lng,
    a.source_record_count
FROM geo_aggregates a
LEFT JOIN geo_city_state_ranked r
    ON r.zip_code_prefix = a.zip_code_prefix
   AND r.location_rank = 1