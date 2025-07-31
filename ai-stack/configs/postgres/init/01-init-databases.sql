-- AI Stack PostgreSQL Initialization Script
-- Optimized for AI workflows with vector and AI extensions

-- Create additional databases for n8n and litellm
SELECT 'CREATE DATABASE n8n_prod' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n_prod')\gexec
SELECT 'CREATE DATABASE litellm_prod' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'litellm_prod')\gexec

-- Connect to main database and set up AI extensions
\c aistack_production;

-- Enable vector extension for embeddings and RAG
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable pgai extension for AI workflows (if available)
-- Note: pgai might need to be installed separately depending on PostgreSQL image
CREATE EXTENSION IF NOT EXISTS pgai;

-- Create vector search optimized indexes
-- These will be used by applications for efficient similarity search

-- Connect to n8n database and set up extensions
\c n8n_prod;
CREATE SCHEMA IF NOT EXISTS n8n_prod;

-- Enable vector extension for n8n AI workflows
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgai;

-- Connect to litellm database and set up extensions  
\c litellm_prod;

-- Enable vector extension for LiteLLM embedding storage
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgai;

-- Create optimized configuration for AI workloads
-- Enable parallel processing for vector operations
SET max_parallel_workers_per_gather = 4;
SET max_parallel_workers = 8;

-- Optimize for vector similarity searches
SET effective_cache_size = '3GB';
SET random_page_cost = 1.1;

-- Create a dedicated schema for vector operations in main DB
\c aistack_production;
CREATE SCHEMA IF NOT EXISTS ai_vectors;
CREATE SCHEMA IF NOT EXISTS embeddings;

-- Grant permissions for AI operations
-- These will be used by the applications
GRANT USAGE ON SCHEMA ai_vectors TO aistack_prod;
GRANT USAGE ON SCHEMA embeddings TO aistack_prod;
GRANT CREATE ON SCHEMA ai_vectors TO aistack_prod;
GRANT CREATE ON SCHEMA embeddings TO aistack_prod;

-- Create sample vector table structure for reference
-- Applications can use this as a template
CREATE TABLE IF NOT EXISTS ai_vectors.document_embeddings (
    id SERIAL PRIMARY KEY,
    document_id TEXT NOT NULL,
    content TEXT NOT NULL,
    embedding VECTOR(1536), -- OpenAI embedding size, adjust as needed
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for efficient vector similarity search
CREATE INDEX IF NOT EXISTS document_embeddings_embedding_idx 
ON ai_vectors.document_embeddings 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Create index for metadata queries
CREATE INDEX IF NOT EXISTS document_embeddings_metadata_idx 
ON ai_vectors.document_embeddings 
USING GIN (metadata);

-- Create index for document_id lookups
CREATE INDEX IF NOT EXISTS document_embeddings_document_id_idx 
ON ai_vectors.document_embeddings (document_id);

COMMENT ON TABLE ai_vectors.document_embeddings IS 'Sample table for storing document embeddings for RAG applications';
COMMENT ON COLUMN ai_vectors.document_embeddings.embedding IS 'Vector embedding (adjust dimensions based on your embedding model)';
COMMENT ON COLUMN ai_vectors.document_embeddings.metadata IS 'Additional metadata about the document (source, type, etc.)';
