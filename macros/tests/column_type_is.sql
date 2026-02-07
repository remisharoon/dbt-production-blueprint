{% test column_type_is(model, column_name, column_type) %}
select
    *
from information_schema.columns
where 1 = 1
{% if model.database %}
  and upper(table_catalog) = upper('{{ model.database }}')
{% endif %}
  and upper(table_schema) = upper('{{ model.schema }}')
  and upper(table_name) = upper('{{ model.identifier }}')
  and upper(column_name) = upper('{{ column_name }}')
  and upper(data_type) not like upper('{{ column_type }}%')
{% endtest %}
