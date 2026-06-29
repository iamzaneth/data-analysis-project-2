
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select geolocation_key
from "olist_db"."dwh"."dim_geolocation"
where geolocation_key is null



  
  
      
    ) dbt_internal_test