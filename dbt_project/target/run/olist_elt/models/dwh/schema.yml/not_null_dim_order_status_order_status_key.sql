
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select order_status_key
from "olist_db"."dwh"."dim_order_status"
where order_status_key is null



  
  
      
    ) dbt_internal_test