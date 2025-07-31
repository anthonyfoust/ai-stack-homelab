# 🧠 Vector Database & AI Extensions Guide

Your AI Stack PostgreSQL database is enhanced with vector capabilities for advanced AI workflows like RAG (Retrieval-Augmented Generation), semantic search, and embedding storage.

## 🔧 Installed Extensions

### pgvector
- **Purpose**: Store and query vector embeddings
- **Use Cases**: Semantic search, RAG, similarity matching, clustering
- **Vector Dimensions**: Configurable (default setup for 1536 - OpenAI embeddings)

### pgai (if available)
- **Purpose**: Direct AI operations within PostgreSQL
- **Use Cases**: In-database AI inference, text processing, embedding generation

## 📊 Pre-configured Database Structure

### Main Database: `aistack_production`
```sql
-- Schemas created during setup:
ai_vectors     -- Vector operations and embeddings
embeddings     -- Dedicated embedding storage

-- Sample table for document embeddings:
ai_vectors.document_embeddings
├── id (SERIAL PRIMARY KEY)
├── document_id (TEXT) - Reference to your document
├── content (TEXT) - Original text content  
├── embedding (VECTOR(1536)) - Vector embedding
├── metadata (JSONB) - Additional document metadata
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)
```

### Optimized Indexes
- **IVFFlat index** on embeddings for fast similarity search
- **GIN index** on metadata for complex queries
- **B-tree index** on document_id for fast lookups

## 🚀 Usage Examples

### Connect to Database
```bash
# Connect to main database
docker exec -it ai-postgres psql -U aistack_prod -d aistack_production

# Connect to n8n database (also has vector extensions)
docker exec -it ai-postgres psql -U aistack_prod -d n8n_prod
```

### Basic Vector Operations
```sql
-- Insert a document with embedding
INSERT INTO ai_vectors.document_embeddings (document_id, content, embedding, metadata)
VALUES (
    'doc_001',
    'Your document content here',
    '[0.1, 0.2, 0.3, ...]'::vector,  -- Your actual embedding vector
    '{"source": "upload", "type": "pdf", "author": "user"}'::jsonb
);

-- Find similar documents (cosine similarity)
SELECT document_id, content, metadata, 
       1 - (embedding <=> '[your_query_embedding]'::vector) AS similarity
FROM ai_vectors.document_embeddings
ORDER BY embedding <=> '[your_query_embedding]'::vector
LIMIT 5;

-- Find documents with specific metadata
SELECT * FROM ai_vectors.document_embeddings
WHERE metadata @> '{"type": "pdf"}'::jsonb
ORDER BY created_at DESC;
```

### Advanced Queries
```sql
-- Combine similarity search with metadata filtering
SELECT document_id, content, 
       1 - (embedding <=> '[query_vector]'::vector) AS similarity
FROM ai_vectors.document_embeddings
WHERE metadata @> '{"source": "trusted"}'::jsonb
  AND 1 - (embedding <=> '[query_vector]'::vector) > 0.8
ORDER BY similarity DESC
LIMIT 10;

-- Get embedding statistics
SELECT 
    COUNT(*) as total_embeddings,
    AVG(array_length(embedding::float[], 1)) as avg_dimensions,
    COUNT(DISTINCT metadata->>'source') as unique_sources
FROM ai_vectors.document_embeddings;
```

## 🔗 Integration with Your AI Stack

### n8n Workflows
Your n8n instance can directly query the vector database for:
- **Document similarity search**
- **RAG workflows** (retrieve relevant context)
- **Semantic clustering** of documents
- **Content recommendation** systems

### Open WebUI RAG
The WebUI can leverage the vector database for:
- **Document upload and embedding**
- **Context retrieval** for better AI responses
- **Conversation memory** with semantic search

### LiteLLM Integration
LiteLLM can use the vector store for:
- **Caching embeddings** to reduce API calls
- **Context injection** for better responses
- **Usage analytics** with semantic grouping

## 🎯 Common AI Patterns

### 1. RAG (Retrieval-Augmented Generation)
```sql
-- Step 1: Store your documents as embeddings
-- Step 2: For each user query, find relevant documents
-- Step 3: Inject relevant context into AI prompt

-- Example: Find context for user question
WITH relevant_docs AS (
  SELECT content, 1 - (embedding <=> $1::vector) AS similarity
  FROM ai_vectors.document_embeddings
  WHERE 1 - (embedding <=> $1::vector) > 0.7
  ORDER BY similarity DESC
  LIMIT 3
)
SELECT string_agg(content, E'\n\n') AS context
FROM relevant_docs;
```

### 2. Semantic Search
```sql
-- Find documents semantically similar to a search term
-- (after converting search term to embedding)
SELECT document_id, content, metadata->>'title' as title,
       1 - (embedding <=> $1::vector) AS relevance_score
FROM ai_vectors.document_embeddings
ORDER BY relevance_score DESC
LIMIT 20;
```

### 3. Content Clustering
```sql
-- Group similar documents together
-- (requires more complex queries or application logic)
SELECT 
    metadata->>'category' as category,
    COUNT(*) as document_count,
    AVG(1 - (embedding <=> $1::vector)) as avg_similarity_to_topic
FROM ai_vectors.document_embeddings
GROUP BY metadata->>'category'
ORDER BY avg_similarity_to_topic DESC;
```

## ⚡ Performance Tips

### 1. Index Optimization
```sql
-- Create indexes for your specific use case
CREATE INDEX embedding_category_idx ON ai_vectors.document_embeddings 
USING ivfflat (embedding vector_cosine_ops) 
WHERE metadata->>'category' = 'important';
```

### 2. Query Optimization
- Use `<=>` for cosine distance (most common for embeddings)
- Use `<->` for L2 distance 
- Use `<#>` for inner product
- Combine with metadata filters for better performance

### 3. Maintenance
```sql
-- Periodically reindex for better performance
REINDEX INDEX document_embeddings_embedding_idx;

-- Update statistics
ANALYZE ai_vectors.document_embeddings;
```

## 🔧 Configuration Notes

- **Vector dimensions**: Adjust based on your embedding model
  - OpenAI: 1536 dimensions
  - Sentence Transformers: 384-768 dimensions  
  - Custom models: varies

- **Index parameters**: Tune `lists` parameter based on data size
  - Small datasets (< 1M vectors): lists = 100
  - Large datasets (> 1M vectors): lists = sqrt(rows)

- **Memory**: Vector operations are memory-intensive
  - Increased `work_mem` to 128MB for vector operations
  - Consider increasing further for large datasets

## 🚨 Important Notes

1. **Embedding Consistency**: Always use the same embedding model for consistent results
2. **Dimension Matching**: Ensure all vectors have the same dimensions
3. **Index Rebuilding**: Reindex periodically for optimal performance
4. **Backup Considerations**: Vector indexes can be large - factor into backup time/space

---

**🎉 Your AI Stack now has powerful vector search capabilities!**

*Perfect for RAG, semantic search, and advanced AI workflows.*
