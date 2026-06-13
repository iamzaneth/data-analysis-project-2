
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select price
from "olist_db"."dwh"."fact_order_item_sales"
where price is null



  
  
      
    ) dbt_internal_test