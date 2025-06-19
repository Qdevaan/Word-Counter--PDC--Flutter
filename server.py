from fastapi import FastAPI, UploadFile, File  # Import FastAPI and file upload utilities
from fastapi.middleware.cors import CORSMiddleware  # Import CORS middleware for cross-origin requests
from typing import List  # Import List type for type hints
import os  # Import os for file and directory operations
import uvicorn  # Import uvicorn for running the ASGI server
import socket  # Import socket to get host IP address
from collections import Counter  # Import Counter for word counting
import time  # Import time for timing operations
import cupy as cp  # Import cupy for GPU-accelerated array operations
import re  # Import re for regular expressions
import json  # Import json for saving results
import fitz  # PyMuPDF, for PDF text extraction
from docx import Document  # Import Document for .docx files
import textract  # Import textract for .doc files

app = FastAPI()  # Create FastAPI app instance

# Add CORS middleware to allow all origins and methods
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = "uploads"  # Directory to save uploaded files
os.makedirs(UPLOAD_DIR, exist_ok=True)  # Create upload directory if it doesn't exist

@app.get("/ping")  # Define a health check endpoint
def ping():
    return {"status": "ok", "message": "Server is alive!"}  # Return server status

def preprocess(text: str):
    """Extract alphanumeric words, including single characters and numbers."""
    return re.findall(r'\b\w+\b', text.lower())  # Find all words using regex

def cuda_word_count(text: str):
    words = preprocess(text)  # Preprocess text to get list of words
    if not words:
        return {}  # Return empty dict if no words found

    unique_words = list(set(words))  # Get unique words
    word_indices = {word: i for i, word in enumerate(unique_words)}  # Map words to indices

    indices = cp.array([word_indices[word] for word in words], dtype=cp.int32)  # Convert words to indices (GPU array)
    counts = cp.bincount(indices)  # Count occurrences using GPU
    counts_cpu = counts.get()  # Move counts back to CPU

    result = {unique_words[i]: int(counts_cpu[i]) for i in range(len(unique_words))}  # Build result dict
    return result  # Return word count dictionary

def extract_text(file_path: str, content_type: str):
    ext = os.path.splitext(file_path)[1].lower()  # Get file extension

    try:
        if ext == ".pdf":
            doc = fitz.open(file_path)  # Open PDF file
            return "\n".join([page.get_text() for page in doc])  # Extract text from all pages
        elif ext == ".docx":
            doc = Document(file_path)  # Open DOCX file
            return "\n".join([p.text for p in doc.paragraphs])  # Extract text from all paragraphs
        elif ext == ".doc":
            return textract.process(file_path).decode('utf-8', errors='ignore')  # Extract text from DOC file
        else:  # fallback for .txt or unknown
            with open(file_path, "r", encoding="utf-8") as f:
                return f.read()  # Read text file
    except Exception as e:
        print(f"Failed to extract text: {e}")  # Print error if extraction fails
        return ""  # Return empty string on failure

@app.post("/upload-files")  # Define file upload endpoint
async def upload_files(files: List[UploadFile] = File(...)):
    saved_files = []  # List to store file results
    overall_counter = Counter()  # Counter for all files
    total_start = time.time()  # Start timing

    for file in files:  # Iterate over uploaded files
        file_location = os.path.join(UPLOAD_DIR, file.filename)  # File save path
        start_time = time.time()  # Start timing for this file

        contents = await file.read()  # Read file contents
        with open(file_location, "wb") as f:
            f.write(contents)  # Save file to disk

        text = extract_text(file_location, file.content_type)  # Extract text from file
        word_counter = cuda_word_count(text)  # Count words using GPU
        top_words = Counter(word_counter).most_common(10)  # Get top 10 words
        file_processing_time = time.time() - start_time  # Calculate processing time
        overall_counter.update(word_counter)  # Update overall counter

        saved_files.append({
            "filename": file.filename,
            "content_type": file.content_type,
            "size_bytes": os.path.getsize(file_location),
            "total_words": sum(word_counter.values()),
            "processing_time_seconds": round(file_processing_time, 4),
            "top_10_words": [{"word": w, "count": c} for w, c in top_words],
            "all_words": word_counter
        })  # Append file result

    total_time = time.time() - total_start  # Calculate total processing time

    result = {
        "status": "success",
        "total_files_received": len(files),
        "overall_processing_time_seconds": round(total_time, 4),
        "overall_top_30_words": [{"word": w, "count": c} for w, c in overall_counter.most_common(30)],
        "files": saved_files
    }  # Build result dictionary

    json_path = os.path.join(UPLOAD_DIR, "result.json")  # Path to save result JSON
    with open(json_path, "w", encoding="utf-8") as jf:
        json.dump(result, jf, ensure_ascii=False, indent=4)  # Save result to JSON

    with open(json_path, "r", encoding="utf-8") as jf:
        print(jf.read())  # Print result JSON

    return result  # Return result to client

if __name__ == "__main__":  # If script is run directly
    hostname = socket.gethostname()  # Get host name
    ip_address = socket.gethostbyname(hostname)  # Get IP address
    print(f"🚀 Server running at: http://{ip_address}:8000")  # Print server address
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)  # Start server with reload
