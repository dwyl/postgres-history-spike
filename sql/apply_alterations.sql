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
