
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select order_item_id
from "olist_db"."dwh"."fact_order_item_sales"
where order_item_id is null



  
  
      
    ) dbt_internal_test