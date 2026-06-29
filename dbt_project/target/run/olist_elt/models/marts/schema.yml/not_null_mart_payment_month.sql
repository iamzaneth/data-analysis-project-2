
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select month
from "olist_db"."mart"."mart_payment"
where month is null



  
  
      
    ) dbt_internal_test