{% macro is_alphanumeric_match(column_name) %}
    {{ adapter.dispatch('is_alphanumeric_match', 'dbt_production_blueprint')(column_name) }}
{% endmacro %}

{% macro default__is_alphanumeric_match(column_name) %}
    regexp_like(cast({{ column_name }} as {{ dbt.type_string() }}), '^[A-Za-z0-9]+$')
{% endmacro %}

{% macro duckdb__is_alphanumeric_match(column_name) %}
    regexp_matches(cast({{ column_name }} as {{ dbt.type_string() }}), '^[A-Za-z0-9]+$')
{% endmacro %}

{% test is_alphanumeric(model, column_name) %}
select *
from {{ model }}
where {{ column_name }} is not null
  and not {{ is_alphanumeric_match(column_name) }}
{% endtest %}
