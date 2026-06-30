import urllib.request
import os

url = "https://archive.org/download/way2llh22_20171016_1230/way2llh22_20171016_1230_djvu.txt"
dest_path = r"c:\Users\us mohamed\Desktop\مصحف\scratch\aldaa_full_text.txt"

print(f"Downloading from {url}...")
try:
    urllib.request.urlretrieve(url, dest_path)
    print("Download completed successfully!")
    
    # Inspect the first 50 lines
    with open(dest_path, "r", encoding="utf-8") as f:
        lines = [next(f) for _ in range(50)]
    print("\n--- First 50 lines of the file ---")
    for i, line in enumerate(lines):
        print(f"{i+1}: {line.strip()}")
except Exception as e:
    print(f"Error: {e}")
