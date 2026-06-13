
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select seller_key
from "olist_db"."dwh"."fact_order_item_sales"
where seller_key is null



  
  
      
    ) dbt_internal_test