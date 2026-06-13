
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select payment_value
from "olist_db"."dwh"."fact_payments"
where payment_value is null



  
  
      
    ) dbt_internal_test