
select
    *
from information_schema.columns
where 1 = 1

  and upper(table_catalog) = upper('ci')

  and upper(table_schema) = upper('main_raw')
  and upper(table_name) = upper('raw_customers')
  and upper(column_name) = upper('email')
  and upper(data_type) not like upper('varchar%')
