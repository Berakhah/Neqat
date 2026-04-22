import json

def extract_ids(json_str):
    """
    Given a JSON string containing a top-level "results" list of objects
    with an "id" field, return a list of all the ids.
    """
    data = json.loads(json_str)
    return [item['id'] for item in data.get('results', [])]

if __name__ == '__main__':
    # Example: load from a file
    with open('response.json', 'r', encoding='utf-8') as f:
        content = f.read()
    ids = extract_ids(content)
    print(ids)
