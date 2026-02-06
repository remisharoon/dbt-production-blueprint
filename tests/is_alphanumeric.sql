{% test is_alphanumeric(model, column_name) %}
select *
from {{ model }}
where {{ column_name }} is not null
  and regexp_like({{ column_name }}::string, '^[A-Za-z0-9]+$') = false
{% endtest %}
