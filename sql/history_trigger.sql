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
