#!/usr/bin/env python3
"""Extract all inmobiliaria detail links from TodoProps directory page."""
import sys, os, json, time

sys.path.insert(0, os.path.dirname(__file__))
from browser_lib import ensure_daemon, connect_cdp, disconnect_cdp

URL = "https://www.todoprops.com/inmobiliarias#inmobiliarias"
OUTPUT = os.path.join(os.path.dirname(__file__), "todoprops-links.jsonl")

EXTRACT_JS = """
(() => {
    const links = [...document.querySelectorAll('a[href*="/inmobiliarias/inmobiliaria/"]')];
    return [...new Set(links.map(a => a.href))];
})()
"""

def main():
    pw, browser, context, page = None, None, None, None
    all_links = set()
    
    try:
        print("Connecting to TodoProps...")
        # ensure_daemon opens the URL in a new tab automatically
        ws_url = ensure_daemon(URL)
        pw, browser, context, page = connect_cdp(ws_url)
        
        # Don't call page.goto() again - it triggers recaptcha redirect!
        # The page is already loaded via ensure_daemon
        
        # Wait for JS to render the list
        print("Waiting for content to render...")
        time.sleep(10)
        
        # Extract links
        links = page.evaluate(EXTRACT_JS)
        all_links.update(links)
        print(f"Page 1: {len(links)} links found")
        
        # Try pagination
        page_num = 1
        while page_num < 10:
            print(f"\nTrying to go to page {page_num + 1}...")
            
            # Try to find and click next page button
            selectors = [
                'text="→"',
                'button:has-text("Next")',
                'a:has-text("Next")',
                '[aria-label="Next"]',
                'text="Siguiente"',
                'button:has-text("Siguiente")',
                'text="2"',  # Click page 2 button
            ]
            
            clicked = False
            for selector in selectors:
                try:
                    btn = page.query_selector(selector)
                    if btn and btn.is_visible():
                        print(f"  Clicking: {selector}")
                        btn.click()
                        clicked = True
                        break
                except:
                    continue
            
            if not clicked:
                print("Could not find next page button")
                break
            
            # Wait for new content
            time.sleep(5)
            
            # Extract new links
            new_links = page.evaluate(EXTRACT_JS)
            new_unique = set(new_links) - all_links
            all_links.update(new_links)
            page_num += 1
            
            print(f"Page {page_num}: {len(new_links)} total, {len(new_unique)} new")
            
            if len(new_unique) == 0:
                print("No new links, stopping")
                break
        
        # Save all unique links
        with open(OUTPUT, "w") as f:
            for url in sorted(all_links):
                f.write(url + "\n")
        
        print(f"\n{'='*50}")
        print(f"Total: {len(all_links)} unique links saved to {OUTPUT}")
        print(f"{'='*50}")
        
        if all_links:
            print("\nSample links:")
            for url in sorted(all_links)[:3]:
                print(f"  {url}")
            if len(all_links) > 3:
                print(f"  ... and {len(all_links) - 3} more")

    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
    finally:
        if pw:
            disconnect_cdp(pw, browser)

if __name__ == "__main__":
    main()