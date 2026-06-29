
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    geolocation_key as unique_field,
    count(*) as n_records

from "olist_db"."dwh"."dim_geolocation"
where geolocation_key is not null
group by geolocation_key
having count(*) > 1



  
  
      
    ) dbt_internal_test