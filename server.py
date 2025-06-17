from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from typing import List
import os
import uvicorn
import socket
from collections import Counter
import time
import cupy as cp
import re
import json
import fitz  # PyMuPDF
from docx import Document
import textract  # Optional, for .doc files

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.get("/ping")
def ping():
    return {"status": "ok", "message": "Server is alive!"}


def preprocess(text: str):
    """Extract alphanumeric words, including single characters and numbers."""
    return re.findall(r'\b\w+\b', text.lower())


def cuda_word_count(text: str):
    words = preprocess(text)
    if not words:
        return {}

    unique_words = list(set(words))
    word_indices = {word: i for i, word in enumerate(unique_words)}

    indices = cp.array([word_indices[word] for word in words], dtype=cp.int32)
    counts = cp.bincount(indices)
    counts_cpu = counts.get()

    result = {unique_words[i]: int(counts_cpu[i]) for i in range(len(unique_words))}
    return result


def extract_text(file_path: str, content_type: str):
    ext = os.path.splitext(file_path)[1].lower()

    try:
        if ext == ".pdf":
            doc = fitz.open(file_path)
            return "\n".join([page.get_text() for page in doc])
        elif ext == ".docx":
            doc = Document(file_path)
            return "\n".join([p.text for p in doc.paragraphs])
        elif ext == ".doc":
            return textract.process(file_path).decode('utf-8', errors='ignore')
        else:  # fallback for .txt or unknown
            with open(file_path, "r", encoding="utf-8") as f:
                return f.read()
    except Exception as e:
        print(f"Failed to extract text: {e}")
        return ""


@app.post("/upload-files")
async def upload_files(files: List[UploadFile] = File(...)):
    saved_files = []
    overall_counter = Counter()
    total_start = time.time()

    for file in files:
        file_location = os.path.join(UPLOAD_DIR, file.filename)
        start_time = time.time()

        contents = await file.read()
        with open(file_location, "wb") as f:
            f.write(contents)

        text = extract_text(file_location, file.content_type)
        word_counter = cuda_word_count(text)
        top_words = Counter(word_counter).most_common(10)
        file_processing_time = time.time() - start_time
        overall_counter.update(word_counter)

        saved_files.append({
            "filename": file.filename,
            "content_type": file.content_type,
            "size_bytes": os.path.getsize(file_location),
            "total_words": sum(word_counter.values()),
            "processing_time_seconds": round(file_processing_time, 4),
            "top_10_words": [{"word": w, "count": c} for w, c in top_words],
            "all_words": word_counter
        })

    total_time = time.time() - total_start

    result = {
        "status": "success",
        "total_files_received": len(files),
        "overall_processing_time_seconds": round(total_time, 4),
        "overall_top_30_words": [{"word": w, "count": c} for w, c in overall_counter.most_common(30)],
        "files": saved_files
    }

    json_path = os.path.join(UPLOAD_DIR, "result.json")
    with open(json_path, "w", encoding="utf-8") as jf:
        json.dump(result, jf, ensure_ascii=False, indent=4)

    with open(json_path, "r", encoding="utf-8") as jf:
        print(jf.read())

    return result


if __name__ == "__main__":
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)
    print(f"🚀 Server running at: http://{ip_address}:8000")
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)
