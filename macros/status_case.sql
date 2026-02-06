{% macro order_status_case(status_groups, field_name) %}
case
{% for group, statuses in status_groups.items() %}
    when lower({{ field_name }}) in (
        {% for status in statuses %}
            '{{ status | lower }}'{% if not loop.last %}, {% endif %}
        {% endfor %}
    ) then '{{ group }}'
{% endfor %}
    else 'other'
end
{% endmacro %}
