import os
from flask import Flask, request, jsonify
from flask_cors import CORS
import chromadb
from chromadb.utils import embedding_functions
from pypdf import PdfReader
import uuid

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Initialize Vector DB (ChromaDB)
# PersistentClient ensures data is saved to disk
try:
    client = chromadb.PersistentClient(path="./chroma_db")
    print("ChromaDB initialized in persistent mode.")
except Exception as e:
    print(f"Error initializing ChromaDB: {e}")
    client = chromadb.Client() # Fallback to in-memory

# Use a standard, local embedding model
# all-MiniLM-L6-v2 is fast and effective for general purpose
ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")

# Get or Create Collection
collection = client.get_or_create_collection(name="knowledge_base", embedding_function=ef)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "message": "Python RAG Server Running"}), 200

@app.route('/add_document', methods=['POST'])
def add_document():
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file part"}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "No selected file"}), 400

        # Read PDF content
        reader = PdfReader(file)
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
        
        # Simple Chunking (Overlap could be added for better context)
        # Split by paragraphs or rough character count
        chunk_size = 500
        chunks = [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]
        
        ids = [str(uuid.uuid4()) for _ in chunks]
        metadatas = [{"source": file.filename} for _ in chunks]
        
        # Add to ChromaDB
        collection.add(
            documents=chunks,
            metadatas=metadatas,
            ids=ids
        )
        
        return jsonify({
            "status": "success", 
            "message": f"Added {len(chunks)} chunks from {file.filename}",
            "chunks_count": len(chunks)
        }), 200

    except Exception as e:
        print(f"Error adding document: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/query', methods=['POST'])
def query():
    try:
        data = request.json
        query_text = data.get('query')
        n_results = data.get('n_results', 3)
        
        if not query_text:
            return jsonify({"error": "No query provided"}), 400
            
        results = collection.query(
            query_texts=[query_text],
            n_results=n_results
        )
        
        # ChromaDB results structure:
        # { 'ids': [['id1', 'id2']], 'documents': [['text1', 'text2']], ... }
        
        output = []
        if results['documents']:
            for i in range(len(results['documents'][0])):
                output.append({
                    "content": results['documents'][0][i],
                    "score": results['distances'][0][i] if results['distances'] else 0, # Note: Distance != Similarity
                    "source": results['metadatas'][0][i]['source']
                })
                
        return jsonify({"results": output}), 200

    except Exception as e:
        print(f"Error querying: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/debug', methods=['GET'])
def debug():
    count = collection.count()
    return jsonify({"document_count": count}), 200

if __name__ == '__main__':
    # Run on 0.0.0.0 to accessible from network if needed, port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)
