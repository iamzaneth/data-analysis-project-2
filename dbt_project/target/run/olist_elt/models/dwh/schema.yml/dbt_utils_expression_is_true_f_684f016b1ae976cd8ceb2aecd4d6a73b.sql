
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from "olist_db"."dwh"."fact_order_item_sales"

where not(freight_value >= 0)


  
  
      
    ) dbt_internal_test