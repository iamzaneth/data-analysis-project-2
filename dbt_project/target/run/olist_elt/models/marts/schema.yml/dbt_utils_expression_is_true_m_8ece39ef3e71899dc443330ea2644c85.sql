
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from "olist_db"."mart"."mart_sales"

where not(freight_to_gmv_pct >= 0 AND <= 100)


  
  
      
    ) dbt_internal_test