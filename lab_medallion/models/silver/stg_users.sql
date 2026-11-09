with source as (
    select * from {{ source('bronze', 'users') }}
),

first_orders as (
    select user_uuid, min(date)::date as first_order_date
    from {{ source('bronze', 'orders') }}
    group by user_uuid
),

typed as (
    select
        cast(s.uuid as uuid) as user_id,
        trim(s.username) as username,
        lower(trim(s.username)) as username_normalized,
        trim(s.name) as name,
        upper(trim(s.sex)) as sex,
        lower(trim(s.mail)) as email,
        cast(s.birthdate as date) as original_birthdate,
        fo.first_order_date,
        split_part(s.address, chr(10), 1) as street,
        split_part(s.address, chr(10), 2) as address_line_2
    from source s
    left join first_orders fo on s.uuid = fo.user_uuid
)

select
    user_id,
    username,
    username_normalized,
    name,
    sex,
    email,
    original_birthdate <= first_order_date as birthdate_is_valid,
    case
        when original_birthdate <= first_order_date then original_birthdate
        else null
    end as birthdate,
    street,
    nullif(regexp_extract(address_line_2, '^(.+), [A-Z]{2} \d{5}$', 1), '') as city,
    regexp_extract(address_line_2, '([A-Z]{2}) (\d{5})$', 1) as state,
    regexp_extract(address_line_2, '([A-Z]{2}) (\d{5})$', 2) as zip_code
from typed
