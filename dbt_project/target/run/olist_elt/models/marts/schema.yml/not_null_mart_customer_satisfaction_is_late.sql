
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select is_late
from "olist_db"."mart"."mart_customer_satisfaction"
where is_late is null



  
  
      
    ) dbt_internal_test