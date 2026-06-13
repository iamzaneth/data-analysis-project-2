
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from "olist_db"."mart"."mart_product_category"

where not(gross_merchandise_value >= 0)


  
  
      
    ) dbt_internal_test