
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select customer_city
from "olist_db"."mart"."mart_geolocation"
where customer_city is null



  
  
      
    ) dbt_internal_test