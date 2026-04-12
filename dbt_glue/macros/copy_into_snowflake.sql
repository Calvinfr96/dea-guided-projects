{% macro copy_json(table_nm) %}
    -- Delete the data from the copy table before running the copy command.
    -- target_db and target_schema are variables being referenced from the dbt_project.yml file.
    delete from {{var ('target_db') }}.{{var ('target_schema')}}.{{ table_nm }};

    -- Copy the data from the snowflake external stage to snowflake table
    COPY INTO {{var ('target_db') }}.{{var ('target_schema')}}.{{ table_nm }}
    FROM
    (
        SELECT
        $1 AS DATA
        -- stage_name is being referenced from the dbt_project.yml file.
        FROM @{{ var('stage_name') }}
    )

    FILE_FORMAT = (TYPE = JSON)
    FORCE = TRUE;
{% endmacro %}