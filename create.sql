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


CREATE OR REPLACE FUNCTION apply_alterations(db_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  row RECORD;
  history_table_name TEXT;
  history_column_name TEXT;
  hist_tbl TEXT;
  table_names_match BOOLEAN;
  column_names_match BOOLEAN;

BEGIN
  FOR row IN
    SELECT column_name, data_type, table_name, character_maximum_length
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_catalog = format('%I', db_name)
    AND table_schema = 'public'
    AND column_name NOT LIKE '_id'
    AND table_name not like 'schema_migrations'
    ORDER BY column_name ASC, table_name DESC -- history tables first
  LOOP

    RAISE NOTICE 'column_name: %, table_name: %', row.column_name, row.table_name;

    -- if we have a history table, update the variables
    IF row.table_name LIKE '%_history' THEN
      history_table_name := row.table_name;
      history_column_name := row.column_name;

    ELSE
      hist_tbl := (row.table_name || '_history');
      table_names_match := history_table_name = hist_tbl;
      column_names_match := history_column_name = row.column_name;
    -- Route for original tables

      IF NOT table_names_match OR (table_names_match AND NOT column_names_match) THEN

        RAISE NOTICE '---> Original exists. Creating column in history table';
        EXECUTE format('ALTER TABLE %I ADD COLUMN %I %s;', hist_tbl, row.column_name, row.data_type);
      END IF;
    END IF;
  END LOOP;

  RETURN true;  -- boolean!
END; $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_history(db_name TEXT)
RETURNS boolean AS $func$

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

  EXECUTE format('CREATE TABLE IF NOT EXISTS %I
      (_id serial PRIMARY KEY, like %I)', new_table, table_name);

  --  execute the mirror tables function here:
  PERFORM apply_alterations(db_name);

  EXECUTE format ('DROP TRIGGER IF EXISTS %I on %I', trigger_name, table_name);
  EXECUTE format('CREATE TRIGGER %I
    AFTER INSERT OR UPDATE ON %I FOR EACH ROW
    EXECUTE PROCEDURE history_trigger(%I, %I)',
      trigger_name, table_name, db_name, table_name);


  END LOOP;

  RETURN true;  -- boolean!
END; $func$
LANGUAGE plpgsql;

SELECT create_history(insert db name here)
