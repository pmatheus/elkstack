import os
import json
import requests
import sys

ELASTIC_URL = "https://localhost:9200"
CA_CERT = "ca.crt"
ENV_FILE = ".env"
EVIDENCE_DIR = "/home/user/.gemini/tmp/srv155/evidence_data"

def load_env():
    env = {}
    with open(ENV_FILE, "r") as f:
        for line in f:
            if "=" in line:
                key, val = line.strip().split("=", 1)
                env[key] = val
    return env

def ingest():
    env = load_env()
    password = env.get("ELASTIC_PASSWORD")
    if not password:
        print("ELASTIC_PASSWORD not found in .env")
        sys.exit(1)
    
    headers = {"Content-Type": "application/json"}
    auth = ("elastic", password)
    
    for filename in os.listdir(EVIDENCE_DIR):
        if not filename.endswith(".json"):
            continue
        
        index_name = filename.replace(".json", "")
        file_path = os.path.join(EVIDENCE_DIR, filename)
        
        print(f"Ingesting {filename} into {index_name}...")
        
        with open(file_path, "r") as f:
            data = json.load(f)
            
        # Bulk ingest for better performance
        bulk_data = ""
        for item in data:
            bulk_data += json.dumps({"index": {"_index": index_name}}) + "\n"
            bulk_data += json.dumps(item) + "\n"
            
        if bulk_data:
            try:
                response = requests.post(
                    f"{ELASTIC_URL}/_bulk",
                    auth=auth,
                    headers=headers,
                    data=bulk_data,
                    verify=CA_CERT,
                    timeout=60
                )
                if response.status_code == 200:
                    print(f"Successfully ingested {len(data)} items into {index_name}.")
                else:
                    print(f"Error ingesting {index_name}: {response.status_code} - {response.text}")
            except Exception as e:
                print(f"Exception during ingestion of {index_name}: {e}")

if __name__ == "__main__":
    ingest()
