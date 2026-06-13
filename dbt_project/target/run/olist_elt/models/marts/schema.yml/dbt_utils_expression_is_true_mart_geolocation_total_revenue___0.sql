
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from "olist_db"."mart"."mart_geolocation"

where not(total_revenue >= 0)


  
  
      
    ) dbt_internal_test