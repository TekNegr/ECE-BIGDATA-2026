select u.user_id, u.state, u.zip_code
from {{ ref('stg_users') }} u
left join {{ ref('zip_state') }} z
  on u.zip_code = z.zip_code
where z.zip_code is null
   or u.state != z.state
