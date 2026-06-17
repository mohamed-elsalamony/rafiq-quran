import json

file_path = r"c:\Users\us mohamed\Desktop\مصحف\assets\data\companions.json"

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    for companion in data:
        if companion.get("id") == 19:
            print(f"Fixing ID 19 name: {companion.get('name')} -> خالد بن الوليد")
            companion["name"] = "خالد بن الوليد"
            
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print("companions.json fixed and formatted successfully.")
except Exception as e:
    print(f"Error: {e}")
