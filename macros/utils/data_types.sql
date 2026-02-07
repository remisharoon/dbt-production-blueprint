{% macro numeric_type(precision, scale) %}
  {{ adapter.dispatch('numeric_type', 'dbt_production_blueprint')(precision, scale) }}
{% endmacro %}

{% macro default__numeric_type(precision, scale) %}
  {{ return('numeric(' ~ precision ~ ', ' ~ scale ~ ')') }}
{% endmacro %}

{% macro snowflake__numeric_type(precision, scale) %}
  {{ return('number(' ~ precision ~ ', ' ~ scale ~ ')') }}
{% endmacro %}
