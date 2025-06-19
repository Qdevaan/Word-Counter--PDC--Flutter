from fastapi import FastAPI, UploadFile, File  # Import FastAPI and file upload classes
from fastapi.middleware.cors import CORSMiddleware  # Import CORS middleware for cross-origin requests
from typing import List  # Import List type for type hints
import os  # Import os for file and directory operations
import uvicorn  # Import uvicorn for running the ASGI server
import socket  # Import socket for network operations
from collections import Counter  # Import Counter for word counting
import time  # Import time for measuring processing durations
import cupy as cp  # Import cupy for GPU-accelerated array operations
import re  # Import re for regular expressions
import json  # Import json for saving results
import fitz  # PyMuPDF, for PDF text extraction
from docx import Document  # Import Document for DOCX file reading
import textract  # Import textract for DOC file extraction

app = FastAPI()  # Create a FastAPI app instance

# Enable CORS for all origins and methods
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_credentials=True,  # Allow credentials
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)

UPLOAD_DIR = "uploads"  # Directory to save uploaded files
os.makedirs(UPLOAD_DIR, exist_ok=True)  # Create upload directory if it doesn't exist

@app.on_event("startup")
def show_device_ip():
    """Print the device's local IP on startup (even with uvicorn reload)."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  # Create a UDP socket
        s.connect(("8.8.8.8", 80))  # Connect to a public DNS server to get local IP
        ip_address = s.getsockname()[0]  # Get the local IP address
        s.close()  # Close the socket
    except Exception:
        ip_address = "127.0.0.1"  # Fallback to localhost if error

    print(f"🚀 Server running at: http://{ip_address}:8000")  # Print server URL
    print(f"👉 Add this IP to your app: {ip_address}")  # Print IP for client use

@app.get("/ping")
def ping():
    return {"status": "ok", "message": "Server is alive!"}  # Health check endpoint

def preprocess(text: str):
    return re.findall(r'\b\w+\b', text.lower())  # Lowercase and split text into words

def cuda_word_count(text: str):
    words = preprocess(text)  # Preprocess text to get words
    if not words:
        return {}  # Return empty dict if no words

    unique_words = list(set(words))  # Get unique words
    word_indices = {word: i for i, word in enumerate(unique_words)}  # Map words to indices

    indices = cp.array([word_indices[word] for word in words], dtype=cp.int32)  # Convert words to indices (GPU array)
    counts = cp.bincount(indices)  # Count occurrences using GPU
    counts_cpu = counts.get()  # Move counts back to CPU

    result = {unique_words[i]: int(counts_cpu[i]) for i in range(len(unique_words))}  # Build word count dict
    return result

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
        else:
            with open(file_path, "r", encoding="utf-8") as f:
                return f.read()  # Read plain text file
    except Exception as e:
        print(f"Failed to extract text: {e}")  # Print error if extraction fails
        return ""  # Return empty string on failure

@app.post("/upload-files")
async def upload_files(files: List[UploadFile] = File(...)):
    saved_files = []  # List to store file processing results
    overall_counter = Counter()  # Counter for all words across files
    total_start = time.time()  # Start timing total processing

    for file in files:
        file_location = os.path.join(UPLOAD_DIR, file.filename)  # Path to save file
        start_time = time.time()  # Start timing this file

        contents = await file.read()  # Read file contents
        with open(file_location, "wb") as f:
            f.write(contents)  # Save file to disk

        text = extract_text(file_location, file.content_type)  # Extract text from file
        word_counter = cuda_word_count(text)  # Count words using GPU
        top_words = Counter(word_counter).most_common(10)  # Get top 10 words
        file_processing_time = time.time() - start_time  # Calculate processing time
        overall_counter.update(word_counter)  # Update overall word counter

        saved_files.append({
            "filename": file.filename,  # File name
            "content_type": file.content_type,  # MIME type
            "size_bytes": os.path.getsize(file_location),  # File size
            "total_words": sum(word_counter.values()),  # Total word count
            "processing_time_seconds": round(file_processing_time, 4),  # Processing time
            "top_10_words": [{"word": w, "count": c} for w, c in top_words],  # Top 10 words
            "all_words": word_counter  # All word counts
        })

    total_time = time.time() - total_start  # Total processing time

    result = {
        "status": "success",  # Status message
        "total_files_received": len(files),  # Number of files processed
        "overall_processing_time_seconds": round(total_time, 4),  # Total time
        "overall_top_30_words": [{"word": w, "count": c} for w, c in overall_counter.most_common(30)],  # Top 30 words overall
        "files": saved_files  # Per-file results
    }

    json_path = os.path.join(UPLOAD_DIR, "result.json")  # Path to save JSON result
    with open(json_path, "w", encoding="utf-8") as jf:
        json.dump(result, jf, ensure_ascii=False, indent=4)  # Save result as JSON

    with open(json_path, "r", encoding="utf-8") as jf:
        print(jf.read())  # Print JSON result to console

    return result  # Return result as response

if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)  # Run server if script is main