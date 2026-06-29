
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select payment_type_key
from "olist_db"."dwh"."dim_payment_type"
where payment_type_key is null



  
  
      
    ) dbt_internal_test