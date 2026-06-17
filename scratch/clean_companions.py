import json
import os

def main():
    file_path = r"c:\Users\us mohamed\Desktop\مصحف\assets\data\companions.json"
    if not os.path.exists(file_path):
        print("Error: companions.json not found!")
        return

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"Total companions in database: {len(data)}")
        
        for comp in data:
            # Clean sources to strictly show Al-Isti'ab and Siyar A'lam al-Nubala
            comp["sources"] = "الاستيعاب في معرفة الأصحاب لابن عبد البر، سير أعلام النبلاء للذهبي"
            
            # Also clean individual sources inside sections if any
            # (lineage, islam, moments, virtues) to prevent referencing other books
            comp["lineage"] = comp["lineage"].split("(المصدر:")[0].strip() + " (المصدر: الاستيعاب لابن عبد البر)"
            comp["islam"] = comp["islam"].split("(المصدر:")[0].strip() + " (المصدر: سير أعلام النبلاء للذهبي)"
            comp["moments"] = comp["moments"].split("(المصدر:")[0].strip() + " (المصدر: سير أعلام النبلاء للذهبي)"
            comp["virtues"] = comp["virtues"].split("(المصدر:")[0].strip() + " (المصدر: سير أعلام النبلاء للذهبي)"
            
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            
        print("Successfully cleaned sources for all companions in companions.json.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
