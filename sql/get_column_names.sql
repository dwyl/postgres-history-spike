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
