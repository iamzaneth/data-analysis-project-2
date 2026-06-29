
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    payment_type_key as unique_field,
    count(*) as n_records

from "olist_db"."dwh"."dim_payment_type"
where payment_type_key is not null
group by payment_type_key
having count(*) > 1



  
  
      
    ) dbt_internal_test