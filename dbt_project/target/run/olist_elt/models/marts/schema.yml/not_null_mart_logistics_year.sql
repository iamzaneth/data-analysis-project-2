
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select year
from "olist_db"."mart"."mart_logistics"
where year is null



  
  
      
    ) dbt_internal_test