-- https://github.com/dwyl/postgres-history-spike/issues/3

CREATE OR REPLACE FUNCTION mirror_tables(db_name TEXT)
  RETURNS TEXT AS $$

  DECLARE
     i RECORD;
     str TEXT := '';
  BEGIN
  -- get the list of columns for the database:
  FOR i IN
    SELECT column_name, data_type, character_maximum_length
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_catalog = format('%I', db_name)
    AND table_schema = 'public'
    ORDER BY column_name ASC
  LOOP

    -- IF str = '' THEN
    --   str := i.column_name;
    -- ELSE
    str :=  str || ',' || i.column_name;
    -- END IF;

    RAISE NOTICE 'i.column_name: %', i.column_name;

  END LOOP;

  -- RAISE NOTICE 'str: %', str;

  RETURN '(' || str || ')';
END; $$
LANGUAGE plpgsql;

SELECT mirror_tables('hits_dev')




DO $$

DECLARE
  i RECORD;
  db_name TEXT := 'hits_dev';

BEGIN
  FOR i IN
    SELECT column_name, data_type, table_name, character_maximum_length
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_catalog = format('%I', db_name)
    AND table_schema = 'public'
    AND column_name NOT LIKE '_id'
    ORDER BY column_name ASC, table_name DESC -- history tables first
  LOOP

  IF i.table_name LIKE '%_history' THEN
    RAISE NOTICE 'LIKE _history %, i.column_name: %',
       i.table_name, i.column_name;
  ELSE
    -- do nothing
  END IF;

  END LOOP;
END; $$





DO $$

DECLARE
  i RECORD;
  db_name TEXT := 'hits_dev';
  previous_column TEXT;
  previous_table TEXT;

BEGIN
FOR i IN
  SELECT column_name, data_type, table_name, character_maximum_length
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_catalog = format('%I', db_name)
  AND table_schema = 'public'
  AND column_name NOT LIKE '_id'
  ORDER BY column_name ASC, table_name DESC -- history tables first
LOOP

  RAISE NOTICE 'column_name: %, table_name: %', i.column_name, i.table_name;

  IF previous_column = '' OR previous_column NOT LIKE '%_history' THEN
    -- first iteration of FOR LOOP do nothing
  ELSE
    -- compare column_name to previous_column in current FOR LOOP iteration

    IF previous_column = i.column_name AND (previous_table = i.table_name || '_history') THEN
      -- column already exists in _history table so do nothing
      RAISE NOTICE 'COLUMN EXISTS i.column_name: %, previous_column: %, table_name %',
        i.column_name, previous_column, i.table_name;
    ELSE
      -- check if current (primary) table matches previous_table (history)
      IF previous_table != i.table_name || '_history' THEN
        RAISE NOTICE 'COLUMN NOT EXIST i.column_name: %, previous_column: %, table_name %',
          i.column_name, previous_column, i.table_name;
        --

      ELSE
        str :=  str || ', $1.' || i.column_name;
      END IF;
      -- column does NOT exists so lets create it:
      -- EXECUTE format('CREATE TABLE IF NOT EXISTS %I
      --     (_id serial PRIMARY KEY, like %I)', new_table, table_name);

    END IF;

  END IF;

  -- assign data of the loop to "previous" so we can access it in next iteration
  previous_column := i.column_name;
  previous_table := i.table_name;

  END LOOP;
END; $$



















ALTER TABLE addresses ADD COLUMN test TEXT;
ALTER TABLE addresses DROP COLUMN test;
ALTER TABLE addresses_history DROP COLUMN test;

DO $$
DECLARE
  row RECORD;
  db_name TEXT := 'hits_dev';
  history_table_name TEXT;
  history_column_name TEXT;

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


    IF row.table_name LIKE '%_history' THEN
      history_table_name := row.table_name;
      history_column_name := row.column_name;

    ELSE

      -- do table names match?
      IF history_table_name LIKE (row.table_name || '_history') THEN

          -- does history_column_name match current_column_name
          IF history_column_name LIKE row.column_name THEN
              -- db name and column name match
          ELSE

            -- Table names match but column names do not
            -- This means that original table has a field that the history table does not
            RAISE NOTICE 'Original table has column that history does not. Adding %  to %', row.column_name, history_table_name;
            EXECUTE format('ALTER TABLE %I ADD COLUMN %I %s;', (row.table_name || '_history'), row.column_name, row.data_type);
          END IF;

      ELSE
        -- An original table does not match the history_table_name
        -- This means that the table has a row that the history table does not

        RAISE NOTICE '---> Original exists. Creating column in history table';
        EXECUTE format('ALTER TABLE %I ADD COLUMN %I %s;', (row.table_name || '_history'), row.column_name, row.data_type);
      END IF;
    END IF;
  END LOOP;
END; $$




-------------------------------
DO $$
DECLARE
  row RECORD;
  db_name TEXT := 'hits_dev';
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
END; $$
