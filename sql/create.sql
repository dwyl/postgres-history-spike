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
