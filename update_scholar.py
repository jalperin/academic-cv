import yaml
import csv
import time
import sys
from datetime import datetime
import frontmatter  # pip install python-frontmatter
from scholarly import scholarly

# ----------------------------
# GET MARKDOWN FILE FROM ARGUMENT
# ----------------------------

if len(sys.argv) < 2:
    print("Usage: python fetch_citations.py <markdown_file>")
    sys.exit(1)

MARKDOWN_FILE = sys.argv[1]

# ----------------------------
# LOAD CONFIG FROM YAML
# ----------------------------

post = frontmatter.load(MARKDOWN_FILE)
AUTHOR_ID = post.metadata.get("gs_author_id")
CITE_FILE = post.metadata.get("gs_csv")
AUTHOR_STATS_FILE = post.metadata.get("gs_author_stats", "gs_author_stats.yaml")
DELAY_BETWEEN_REQUESTS = post.metadata.get("gs_delay_between_requests", 2)

if not AUTHOR_ID or not CITE_FILE:
    raise ValueError("Both 'gs_author_id' and 'gs_csv' must be defined in YAML metadata")

# ----------------------------
# FUNCTIONS
# ----------------------------

def load_existing_csv(file_path):
    data = {}
    try:
        with open(file_path, mode='r', newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                data[row['title']] = row
    except FileNotFoundError:
        pass
    return data

def save_csv(publications_dict, file_path):
    with open(file_path, mode='w', newline='', encoding='utf-8') as f:
        fieldnames = ["author_id","pub_id","title","year","num_citations","url","date_scraped"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for pub in publications_dict.values():
            writer.writerow(pub)

def save_author_stats(data, output_file):
    """
    Saves author stats dict to a YAML file.
    """
    with open(output_file, 'w', encoding='utf-8') as f:
        yaml.dump(data, f, sort_keys=False, allow_unicode=True)
    print(f"[INFO] Author stats saved to {output_file}")

def fetch_author_profile(author_id):
    """Fetch author profile with publications."""
    author = scholarly.search_author_id(author_id)
    author_filled = scholarly.fill(author, sections=['publications'])
    return author_filled

def fetch_publications(author_filled, existing_data):
    """Fetch all publications, saving CSV after each publication."""
    pubs_list = author_filled.get('publications', [])
    total_pubs = len(pubs_list)

    for idx, pub in enumerate(pubs_list, start=1):
        try:
            pub_filled = scholarly.fill(pub)
            title = pub_filled['bib'].get('title', '')
            pub_id = pub_filled.get('author_pub_id', '')  
            pub_url = pub_filled.get('pub_url', '')
            entry = {
                "author_id": AUTHOR_ID,
                "pub_id": pub_id,  # now correctly saved
                "title": title,
                "year": pub_filled['bib'].get('year', ''),
                "num_citations": pub_filled.get('num_citations', 0),
                "url": pub_url,
                "date_scraped": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
            existing_data[title] = entry

            # Save CSV after each publication
            save_csv(existing_data, CITE_FILE)

            print(f"[{idx}/{total_pubs}] Fetched: '{title}' ({entry['num_citations']} citations) – CSV updated.")
            time.sleep(DELAY_BETWEEN_REQUESTS)
        except Exception as e:
            print(f"[WARN] Failed to fetch publication {idx}/{total_pubs}: {e}")


def fetch_author_stats(author_profile):
    """
    Fetches all available author stats from Google Scholar.
    Returns a Python dict with summary.
    """
    data = {
        'author_id': author_profile.get('id', ''),
        'name': author_profile.get('name', ''),
        'affiliation': author_profile.get('affiliation', ''),
        'total_citations': author_profile.get('citedby', 0),
        'total_citations_5y': author_profile.get('citedby5y', 0),
        'h_index': author_profile.get('hindex', 0),
        'h_index_5y': author_profile.get('hindex5y', 0),
        'i10_index': author_profile.get('i10index', 0),
        'i10_index_5y': author_profile.get('i10index5y', 0),
        'num_publications': len(author_profile.get('publications', 0)),
        'date_scraped': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

    return data


# ----------------------------
# MAIN
# ----------------------------

if __name__ == "__main__":
    print(f"Fetching publications for author {AUTHOR_ID} from {MARKDOWN_FILE}...\n")

    author_profile = fetch_author_profile(AUTHOR_ID)
    existing_data = load_existing_csv(CITE_FILE)

    # Fetch publications, writing CSV after each iteration
    fetch_publications(author_profile, existing_data)

    # Fetch author stats
    author_stats = fetch_author_stats(author_profile)
    save_author_stats(author_stats, AUTHOR_STATS_FILE)

    print(f"\nCompleted. Publications CSV: {CITE_FILE}")
    print(f"Author statistics CSV: {AUTHOR_STATS_FILE}")
