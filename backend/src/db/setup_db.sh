#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Drop the database if it exists
psql -U postgres -c "DROP DATABASE IF EXISTS tritonspend;"

# Create the new database
psql -U postgres -c "CREATE DATABASE tritonspend;"

# Grant all privileges to the postgres user on the new database
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE tritonspend TO postgres;"

# Run the schema SQL file to create the tables (using absolute path)
psql -U postgres -d tritonspend -f "${SCRIPT_DIR}/database.sql"

# Change ownership of all tables to postgres user
psql -U postgres -d tritonspend -c "ALTER DATABASE tritonspend OWNER TO postgres;"
psql -U postgres -d tritonspend -c "ALTER SCHEMA public OWNER TO postgres;"

# Grant all privileges on the tables to postgres
psql -U postgres -d tritonspend -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;"

# Change ownership of all existing tables to postgres
psql -U postgres -d tritonspend -c "DO \$\$ DECLARE r RECORD; BEGIN FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP EXECUTE 'ALTER TABLE ' || quote_ident(r.tablename) || ' OWNER TO postgres'; END LOOP; END \$\$;"

# Change ownership of all sequences to postgres
psql -U postgres -d tritonspend -c "DO \$\$ DECLARE r RECORD; BEGIN FOR r IN (SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public') LOOP EXECUTE 'ALTER SEQUENCE ' || quote_ident(r.sequence_name) || ' OWNER TO postgres'; END LOOP; END \$\$;"

# Change ownership of all functions to postgres
psql -U postgres -d tritonspend -c "DO \$\$ DECLARE r RECORD; BEGIN FOR r IN (SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public' AND routine_type = 'FUNCTION') LOOP EXECUTE 'ALTER FUNCTION ' || quote_ident(r.routine_name) || ' OWNER TO postgres'; END LOOP; END \$\$;"

# Ensure future tables also get privileges automatically
psql -U postgres -d tritonspend -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres;"
psql -U postgres -d tritonspend -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;"

echo "✅ Database setup complete!"
