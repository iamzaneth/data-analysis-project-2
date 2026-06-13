
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    order_status_key as unique_field,
    count(*) as n_records

from "olist_db"."dwh"."dim_order_status"
where order_status_key is not null
group by order_status_key
having count(*) > 1



  
  
      
    ) dbt_internal_test