import os
import sys
import subprocess
import re

# --- Auto-install required modules if missing ---
def install_if_missing(package, import_name=None):
    try:
        __import__(import_name or package)
    except ImportError:
        print(f"[+] Installing missing package: {package}")
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])

for pkg, imp in [("requests", "requests"), ("beautifulsoup4", "bs4")]:
    install_if_missing(pkg, imp)

import requests
from bs4 import BeautifulSoup

# --- NOTE for users ---
print("\n[NOTE] MangaFreak sometimes changes domain (ww2, ww1, ww3, etc.).")
print("If you notice failures, script will try alternatives automatically.\n")

# --- Get inputs from user ---
base_url = input("Enter Manga link (e.g. https://ww2.mangafreak.me/Manga/Solo_Max_Level_Newbie): ").strip()
start_chapter = int(input("Enter start chapter number: ").strip())
end_chapter = int(input("Enter end chapter number: ").strip())

# --- Extract base domain and manga name ---
try:
    domain = base_url.split("/")[2]  # ww2.mangafreak.me
    manga_name = base_url.rstrip("/").split("/")[-1]
except Exception:
    print("[-] Invalid Manga URL. Exiting.")
    sys.exit(1)

# Possible domains to try
domains_to_try = [domain] + [f"ww{i}.mangafreak.me" for i in range(1, 6)]

# --- Create a download directory ---
if not os.path.exists(manga_name):
    os.makedirs(manga_name)

# --- Extract image URLs ---
def extract_image_urls(html):
    soup = BeautifulSoup(html, "html.parser")

    # 1. Standard <img src="">
    imgs = [img.get("src") for img in soup.find_all("img") if img.get("src") and (".jpg" in img.get("src") or ".png" in img.get("src"))]

    # 2. <img data-src="">
    imgs += [img.get("data-src") for img in soup.find_all("img") if img.get("data-src") and (".jpg" in img.get("data-src") or ".png" in img.get("data-src"))]

    # 3. Fallback: Regex search for jpg/png in raw HTML (covers JS variables)
    regex_imgs = re.findall(r"https?://[^'\"]+\.(?:jpg|png)", html)
    imgs += regex_imgs

    # Remove duplicates
    return list(dict.fromkeys(imgs))

# --- Download function with resume support ---
def download_chapter(chapter_num):
    for dom in domains_to_try:
        chapter_url = f"https://{dom}/Read1_{manga_name}_{chapter_num}"
        print(f"\n[+] Trying Chapter {chapter_num} from {dom}")

        try:
            response = requests.get(chapter_url, timeout=15)
            response.raise_for_status()
        except Exception as e:
            print(f"    [-] Failed on {dom}: {e}")
            continue  # try next domain

        image_urls = extract_image_urls(response.text)

        if not image_urls:
            print(f"    [-] No images found on {dom}")
            continue  # try next domain

        # If success, download images
        chapter_dir = os.path.join(manga_name, f"Chapter_{chapter_num}")
        os.makedirs(chapter_dir, exist_ok=True)

        # Track already downloaded images
        existing_files = set(os.listdir(chapter_dir))

        for i, img_url in enumerate(image_urls, start=1):
            img_filename = f"{i:03}.jpg"
            img_path = os.path.join(chapter_dir, img_filename)

            if img_filename in existing_files:
                print(f"    Skipping (already exists): {img_path}")
                continue

            try:
                img_data = requests.get(img_url, timeout=15).content
                with open(img_path, "wb") as f:
                    f.write(img_data)
                print(f"    Saved: {img_path}")
            except Exception as e:
                print(f"    [-] Failed to download {img_url}: {e}")

        print(f"[+] Chapter {chapter_num} downloaded successfully from {dom}")
        return  # stop trying once successful

    print(f"[-] Could not download Chapter {chapter_num} from any domain.")

# --- Loop through chapters ---
for ch in range(start_chapter, end_chapter + 1):
    try:
        download_chapter(ch)
    except Exception as e:
        print(f"[-] Unexpected error in Chapter {ch}: {e}")
        continue

print("\n[+] Download complete! Check the folder:", manga_name)
