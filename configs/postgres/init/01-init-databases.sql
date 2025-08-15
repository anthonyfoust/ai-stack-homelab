-- Create additional databases for AI Stack services
SELECT 'CREATE DATABASE n8n_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n_db')\gexec
SELECT 'CREATE DATABASE litellm_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'litellm_db')\gexec
SELECT 'CREATE DATABASE open_webui_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'open_webui_db')\gexec

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE n8n_db TO aistack_user;
GRANT ALL PRIVILEGES ON DATABASE litellm_db TO aistack_user;
GRANT ALL PRIVILEGES ON DATABASE open_webui_db TO aistack_user;