-- DROP TRIGGER ps_counters_history_trigger ON ps_counters;

CREATE OR REPLACE FUNCTION get_column_names(db_name TEXT, t_name TEXT)
  RETURNS TEXT AS $$

  DECLARE
     i RECORD;
     str text := '';
  BEGIN

  FOR i IN
    SELECT column_name
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_catalog = format('%I', db_name)
    AND table_name = format('%I', t_name)
  LOOP

    IF str = '' THEN
      str := i.column_name;
    ELSE
      str :=  str || ',' || i.column_name;
    END IF;

  END LOOP;

  RAISE NOTICE 'str: %', str;

  RETURN '(' || str || ')';
END; $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_column_names_values(db_name TEXT, t_name TEXT)
RETURNS TEXT AS $$

  DECLARE
     i RECORD;
     str text := '';
  BEGIN

  FOR i IN
    SELECT column_name
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_catalog = format('%I', db_name)
    AND table_name = format('%I', t_name)
  LOOP

    IF str = '' THEN
      str := '$1.' || i.column_name;
    ELSE
      str :=  str || ', $1.' || i.column_name;
    END IF;

  END LOOP;

  RAISE NOTICE 'str: %', str;

  RETURN '(' || str || ')';
END; $$
LANGUAGE plpgsql;

-- function that creates the trigger:
CREATE OR REPLACE FUNCTION history_trigger()
  RETURNS trigger AS
$$
  DECLARE
    -- stackoverflow.com/questions/7726237/postgres-trigger-function-with-params
	db_name TEXT := TG_ARGV[0];
	t_name TEXT := TG_ARGV[1];

  BEGIN
    EXECUTE 'INSERT INTO ' || t_name || '_history' ||
            (SELECT get_column_names(db_name, t_name))  ||
            'VALUES' ||
            (SELECT get_column_names_values(db_name, t_name)) || ';'
            USING NEW;
    RETURN NEW;
END; $$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION create_history(db_name TEXT)

RETURNS boolean

AS $func$

DECLARE
  tables RECORD;
  table_name TEXT;
  new_table TEXT;
  trigger_name TEXT;

BEGIN

FOR tables IN
  (SELECT t.table_name
  FROM information_schema.tables t
  WHERE t.table_catalog = format('%I', db_name)
  AND t.table_schema = 'public'
  AND t.table_name not like '%_history'
  AND t.table_name not like 'schema_migrations'
  )
LOOP
  table_name := tables.table_name;
  new_table := table_name || '_history';
  trigger_name := new_table || '_trigger';

  EXECUTE format('CREATE TABLE IF NOT EXISTS %I (_id serial, like %I)',
    new_table, table_name);

  RAISE NOTICE 'trigger_name: $', trigger_name
  -- CREATE TRIGGER EXECUTE format('%I', trigger_name)
  --   AFTER INSERT OR UPDATE ON ps_counters FOR EACH ROW
  --   EXECUTE PROCEDURE history_trigger(db_name, table_name);

  END LOOP;

  RETURN true;  -- boolean!
END; $func$

LANGUAGE plpgsql;

SELECT create_history('hits_dev')
