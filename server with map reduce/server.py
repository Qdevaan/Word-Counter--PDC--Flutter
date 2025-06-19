from fastapi import FastAPI, UploadFile, File  # Import FastAPI and file upload classes
from fastapi.middleware.cors import CORSMiddleware  # Import CORS middleware for cross-origin requests
from typing import List  # Import List type for type hints
import os  # Import os for file and directory operations
import uvicorn  # Import uvicorn for running the ASGI server
import socket  # Import socket for network operations
from collections import Counter  # Import Counter for word counting
import time  # Import time for timing operations
import re  # Import re for regular expressions
import json  # Import json for JSON operations
import fitz  # PyMuPDF, for PDF text extraction
from docx import Document  # Import Document for DOCX file reading
import textract  # Import textract for DOC file reading
import math  # Import math for mathematical operations
from concurrent.futures import ProcessPoolExecutor  # Import for parallel processing
import multiprocessing  # Import multiprocessing for CPU core count

app = FastAPI()  # Create FastAPI app instance

# Enable CORS
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
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  # Create UDP socket
        s.connect(("8.8.8.8", 80))  # Connect to external server to get local IP
        ip_address = s.getsockname()[0]  # Get local IP address
        s.close()  # Close socket
    except Exception:
        ip_address = "127.0.0.1"  # Fallback to localhost if error

    print(f"🚀 Server running at: http://{ip_address}:8000")  # Print server URL
    print(f"👉 Add this IP to your app: {ip_address}")  # Print IP for client use

@app.get("/ping")
def ping():
    return {"status": "ok", "message": "Server is alive!"}  # Health check endpoint

# ---------------- MapReduce Word Count ---------------- #

def preprocess(text: str):
    return re.findall(r'\b\w+\b', text.lower())  # Tokenize text into lowercase words

def map_words(chunk: str):
    words = re.findall(r'\b\w+\b', chunk.lower())  # Tokenize chunk into words
    return Counter(words)  # Count words in chunk

def reduce_counts(counters: List[Counter]):
    total = Counter()  # Initialize total counter
    for counter in counters:
        total.update(counter)  # Merge counters
    return total  # Return combined counter

def split_text(text: str, num_chunks: int):
    words = preprocess(text)  # Tokenize text
    chunk_size = math.ceil(len(words) / num_chunks)  # Calculate chunk size
    return [" ".join(words[i:i + chunk_size]) for i in range(0, len(words), chunk_size)]  # Split into chunks

def map_reduce_word_count(text: str):
    words = preprocess(text)  # Tokenize text
    total_words = len(words)  # Count total words

    if total_words == 0:
        return {}  # Return empty if no words

    cpu_cores = multiprocessing.cpu_count()  # Get number of CPU cores
    num_chunks = min(cpu_cores * 2, total_words)  # Set number of chunks

    chunks = split_text(text, num_chunks)  # Split text into chunks

    with ProcessPoolExecutor() as executor:
        results = list(executor.map(map_words, chunks))  # Map step in parallel

    return reduce_counts(results)  # Reduce step

# ---------------- Text Extraction ---------------- #

def extract_text(file_path: str, content_type: str):
    ext = os.path.splitext(file_path)[1].lower()  # Get file extension
    try:
        if ext == ".pdf":
            doc = fitz.open(file_path)  # Open PDF
            return "\n".join([page.get_text() for page in doc])  # Extract text from all pages
        elif ext == ".docx":
            doc = Document(file_path)  # Open DOCX
            return "\n".join([p.text for p in doc.paragraphs])  # Extract text from all paragraphs
        elif ext == ".doc":
            return textract.process(file_path).decode('utf-8', errors='ignore')  # Extract text from DOC
        else:
            with open(file_path, "r", encoding="utf-8") as f:
                return f.read()  # Read plain text file
    except Exception as e:
        print(f"Failed to extract text: {e}")  # Print error
        return ""  # Return empty string on failure

# ---------------- Upload Endpoint ---------------- #

@app.post("/upload-files")
async def upload_files(files: List[UploadFile] = File(...)):
    saved_files = []  # List to store file results
    overall_counter = Counter()  # Counter for all files
    total_start = time.time()  # Start timing

    for file in files:
        file_location = os.path.join(UPLOAD_DIR, file.filename)  # File save path
        start_time = time.time()  # Start timing for this file

        contents = await file.read()  # Read file contents
        with open(file_location, "wb") as f:
            f.write(contents)  # Save file to disk

        text = extract_text(file_location, file.content_type)  # Extract text from file
        word_counter = map_reduce_word_count(text)  # Count words using MapReduce
        top_words = Counter(word_counter).most_common(10)  # Get top 10 words
        file_processing_time = time.time() - start_time  # Calculate processing time
        overall_counter.update(word_counter)  # Update overall counter

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
        "status": "success",  # Status
        "total_files_received": len(files),  # Number of files
        "overall_processing_time_seconds": round(total_time, 4),  # Total time
        "overall_top_30_words": [{"word": w, "count": c} for w, c in overall_counter.most_common(30)],  # Top 30 words overall
        "files": saved_files  # Per-file results
    }

    json_path = os.path.join(UPLOAD_DIR, "result.json")  # Path to save JSON result
    with open(json_path, "w", encoding="utf-8") as jf:
        json.dump(result, jf, ensure_ascii=False, indent=4)  # Save result to JSON

    with open(json_path, "r", encoding="utf-8") as jf:
        print(jf.read())  # Print result JSON

    return result  # Return result to client

# ---------------- Entry Point ---------------- #

if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)  # Run server if script is main
