import os
import time
import socket
import psutil
import requests
from flask import Flask, request, jsonify, Response, stream_with_context
from flask_cors import CORS
import chromadb
from chromadb.utils import embedding_functions
from pypdf import PdfReader
import uuid

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# --- CONFIGURATION ---
OLLAMA_BASE_URL = "http://localhost:11434"
CHROMA_PATH = "./chroma_db"
EMBEDDING_MODEL = "all-MiniLM-L6-v2"

# --- VECTOR DB SETUP ---
print("⏳ Initializing Vector Database...")
try:
    client = chromadb.PersistentClient(path=CHROMA_PATH)
    ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name=EMBEDDING_MODEL)
    collection = client.get_or_create_collection(name="knowledge_base", embedding_function=ef)
    print("✅ ChromaDB Initialized (Persistent)")
except Exception as e:
    print(f"❌ Error initializing ChromaDB: {e}")
    client = None
    collection = None

# --- UTILS ---
def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

# --- RAG ROUTES ---

@app.route('/rag/ingest', methods=['POST'])
def ingest_document():
    if not collection:
        return jsonify({"error": "Database not initialized"}), 500

    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    try:
        text = ""
        # Handle PDF
        if file.filename.lower().endswith('.pdf'):
            reader = PdfReader(file)
            for page in reader.pages:
                text += page.extract_text() + "\n"
        # Handle Text
        elif file.filename.lower().endswith('.txt') or file.filename.lower().endswith('.md'):
            text = file.read().decode('utf-8')
        else:
            return jsonify({"error": "Unsupported file format. Use PDF or TXT."}), 400

        # Chunking
        chunk_size = 500
        overlap = 50
        chunks = []
        for i in range(0, len(text), chunk_size - overlap):
            chunks.append(text[i:i+chunk_size])

        if not chunks:
            return jsonify({"error": "Document appears empty"}), 400

        ids = [str(uuid.uuid4()) for _ in chunks]
        metadatas = [{"source": file.filename} for _ in chunks]

        collection.add(documents=chunks, metadatas=metadatas, ids=ids)

        return jsonify({
            "status": "success",
            "message": f"Ingested {len(chunks)} chunks from {file.filename}",
            "filename": file.filename
        })

    except Exception as e:
        print(f"Error ingesting: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/rag/query', methods=['POST'])
def query_knowledge():
    if not collection:
        return jsonify({"error": "Database not initialized"}), 500

    data = request.json
    query_text = data.get('query')
    n_results = data.get('n_results', 3)

    if not query_text:
        return jsonify({"error": "No query provided"}), 400

    try:
        results = collection.query(query_texts=[query_text], n_results=n_results)
        
        # Flatten results
        docs = results['documents'][0] if results['documents'] else []
        metas = results['metadatas'][0] if results['metadatas'] else []
        
        formatted_results = []
        for i in range(len(docs)):
            formatted_results.append({
                "content": docs[i],
                "source": metas[i].get('source', 'Unknown')
            })

        return jsonify({"results": formatted_results})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/rag/delete', methods=['DELETE'])
def delete_document():
    if not collection:
        return jsonify({"error": "Database not initialized"}), 500
    
    filename = request.args.get('filename')
    if not filename:
        return jsonify({"error": "Filename required"}), 400
    
    try:
        collection.delete(where={"source": filename})
        return jsonify({"status": "success", "message": f"Deleted documents for {filename}"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- SYSTEM ROUTES ---

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status": "online",
        "ip": get_local_ip(),
        "ollama": check_ollama_status(),
        "rag_docs": collection.count() if collection else 0
    })

@app.route('/system/stats', methods=['GET'])
def system_stats():
    return jsonify({
        "cpu_percent": psutil.cpu_percent(),
        "memory_percent": psutil.virtual_memory().percent,
        "ip": get_local_ip()
    })

def check_ollama_status():
    try:
        resp = requests.get(f"{OLLAMA_BASE_URL}/api/tags")
        return "connected" if resp.status_code == 200 else "error"
    except:
        return "disconnected"

# --- OLLAMA PROXY ROUTES ---

@app.route('/v1/chat/completions', methods=['POST'])
def proxy_chat_completions():
    """Proxies requests from Mobile App -> Server -> Local Ollama"""
    try:
        # Forward request to Ollama
        ollama_resp = requests.post(
            f"{OLLAMA_BASE_URL}/v1/chat/completions",
            json=request.json,
            headers=request.headers,
            stream=True
        )

        # Stream response back to client
        def generate():
            for chunk in ollama_resp.iter_content(chunk_size=1024):
                if chunk:
                    yield chunk

        return Response(generate(), headers=dict(ollama_resp.headers))

    except requests.exceptions.ConnectionError:
        return jsonify({"error": "Failed to connect to Ollama. Is it running?"}), 503
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/tags', methods=['GET'])
def proxy_tags():
    try:
        resp = requests.get(f"{OLLAMA_BASE_URL}/api/tags")
        return jsonify(resp.json())
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    local_ip = get_local_ip()
    print(f"\n🚀 POCKETMIND BRIDGE RUNNING ON: http://{local_ip}:5000")
    print(f"🔗 Connect your mobile app to this IP.")
    print("------------------------------------------------")
    app.run(host='0.0.0.0', port=5000)
