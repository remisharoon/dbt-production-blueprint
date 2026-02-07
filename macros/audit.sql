{% macro log_run_start() %}
    {% if target.name == 'ci' %}
        {% do log('Skipping audit_run hook for ci target.', info=true) %}
    {% else %}
        {% set create_sql %}
            create table if not exists {{ target.database }}.{{ target.schema }}.audit_run (
                run_started_at {{ dbt.type_timestamp() }},
                invocation_id {{ dbt.type_string() }},
                target_name {{ dbt.type_string() }}
            )
        {% endset %}

        {% do run_query(create_sql) %}

        {% set insert_sql %}
            insert into {{ target.database }}.{{ target.schema }}.audit_run
            (run_started_at, invocation_id, target_name)
            values ({{ dbt.current_timestamp() }}, '{{ invocation_id }}', '{{ target.name }}')
        {% endset %}

        {% do run_query(insert_sql) %}
    {% endif %}
{% endmacro %}
