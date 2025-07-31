-- Create additional databases for n8n and litellm
SELECT 'CREATE DATABASE n8n_prod' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n_prod')\gexec
SELECT 'CREATE DATABASE litellm_prod' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'litellm_prod')\gexec

-- Create n8n schema
\c n8n_prod;
CREATE SCHEMA IF NOT EXISTS n8n_prod;
