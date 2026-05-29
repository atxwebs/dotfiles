#!/usr/bin/env python3
"""Extract JSON-LD product metadata from MercadoLibre listing or product page.

Usage:
    mercadolibre.py "search query"              # ML listing → first N products
    mercadolibre.py "https://listado.mercadolibre.com.ar/..."  # listing URL → first N
    mercadolibre.py "https://www.mercadolibre.com.ar/.../p/MLA12345"  # single product
    mercadolibre.py --limit 3 "curcuma jengibre"  # override default 5

Outputs clean JSON (array of product objects) to stdout.
Saves raw JSON to $MERCADOLIBRE_OUTPUT_DIR if set.

Uses Playwright CDP with humanize patches via browser_lib.
"""
import sys, os, re, json, time
from pathlib import Path
from datetime import datetime
from urllib.parse import quote

from browser_lib import ensure_daemon, connect_cdp, disconnect_cdp

EXTRACT_JSONLD_JS = """
(function() {
    var scripts = document.querySelectorAll('script[type="application/ld+json"]');
    for (var i = 0; i < scripts.length; i++) {
        try {
            var d = JSON.parse(scripts[i].textContent);
            if (d['@type'] === 'Product') return JSON.stringify(d);
            if (Array.isArray(d)) {
                for (var j = 0; j < d.length; j++) {
                    var item = d[j];
                    if ((item['@type'] || '').indexOf('Product') > -1) return JSON.stringify(item);
                    if (item['@graph']) {
                        for (var k = 0; k < item['@graph'].length; k++) {
                            if ((item['@graph'][k]['@type'] || '').indexOf('Product') > -1)
                                return JSON.stringify(item['@graph'][k]);
                        }
                    }
                }
            }
            if (d['@graph']) {
                for (var k = 0; k < d['@graph'].length; k++) {
                    if ((d['@graph'][k]['@type'] || '').indexOf('Product') > -1)
                        return JSON.stringify(d['@graph'][k]);
                }
            }
        } catch(e) {}
    }
    return 'null';
})()
"""

EXTRACT_LISTING_URLS_JS = """
(function() {
    var links = document.querySelectorAll('a');
    var seen = {};
    var products = [];
    for (var i = 0; i < links.length; i++) {
        var href = links[i].href || '';
        if (!href.includes('mercadolibre.com.ar')) continue;
        if (href.includes('listado') || href.includes('click1') || href.includes('/ads/')) continue;
        var idMatch = href.match(/\/(ML[AU]\d+)/);
        if (!idMatch) continue;
        var productId = idMatch[1];
        if (seen[productId]) continue;
        seen[productId] = true;
        var title = (links[i].textContent || '').trim();
        if (title.length < 5) continue;
        var cleanUrl = href.split('#')[0];
        products.push({id: productId, title: title.substring(0, 120), url: cleanUrl});
        if (products.length >= 50) break;
    }
    return JSON.stringify(products);
})()
"""

EXTRACT_PRICES_JS = """
(function() {
    var result = {};
    var priceEl = document.querySelector('[itemprop="price"]');
    if (priceEl) result.price = parseFloat(priceEl.getAttribute('content'));
    if (!result.price) {
        var amounts = document.querySelectorAll('.andes-money-amount__fraction');
        if (amounts.length > 0) {
            var raw = amounts[0].textContent.replace(/[^0-9.,]/g, '').replace(',', '.');
            result.price = parseFloat(raw);
        }
    }
    return JSON.stringify(result);
})()
"""

DEFAULT_LIMIT = 5
OUTPUT_DIR = Path(os.environ.get("MERCADOLIBRE_OUTPUT_DIR", "/tmp"))


def is_url(s):
    return bool(re.match(r"^https?://", s)) and "." in s


def is_listing_url(url):
    return bool(re.search(r"/listado[./]", url))


def is_product_url(url):
    return bool(re.search(r"/[pu]/(ML[AU]\d+)", url))


def parse_limit(args):
    limit = DEFAULT_LIMIT
    remaining = []
    i = 0
    while i < len(args):
        if args[i] == "--limit" and i + 1 < len(args):
            try:
                limit = int(args[i + 1])
                i += 2
                continue
            except ValueError:
                pass
        remaining.append(args[i])
        i += 1
    return limit, remaining


def get_listing_products(query_or_url, limit, pw, browser, context, page):
    """Get product URLs from a ML listing (URL or search query)."""
    if is_url(query_or_url):
        url = query_or_url
    else:
        url = f"https://listado.mercadolibre.com.ar/{quote(query_or_url)}"

    page.goto(url, wait_until="domcontentloaded", timeout=30000)
    page.wait_for_timeout(3000)

    # Lazy-load: 3 scrolls
    for _ in range(3):
        page.evaluate("window.scrollBy(0, 800)")
        time.sleep(1)

    raw = page.evaluate(EXTRACT_LISTING_URLS_JS)
    try:
        products = json.loads(raw) if isinstance(raw, str) else raw
        return (products if isinstance(products, list) else [])[:limit]
    except (json.JSONDecodeError, TypeError):
        return []


def crawl_product(url, pw, browser, context, page):
    """Crawl a single product page, extract JSON-LD + price."""
    page.goto(url, wait_until="domcontentloaded", timeout=15000)
    page.wait_for_timeout(3000)

    ld_raw = page.evaluate(EXTRACT_JSONLD_JS)
    price_raw = page.evaluate(EXTRACT_PRICES_JS)

    product = {"url": url}

    if ld_raw and ld_raw != "null":
        try:
            ld = json.loads(ld_raw)
            product["name"] = ld.get("name", "")
            product["brand"] = ld.get("brand", {}).get("name", "") if isinstance(ld.get("brand"), dict) else ld.get("brand", "")
            product["description"] = ld.get("description", "")
            product["rating"] = ld.get("aggregateRating", {}).get("ratingValue", "")
            product["review_count"] = ld.get("aggregateRating", {}).get("ratingCount", "")
            offers = ld.get("offers", {})
            if isinstance(offers, dict):
                product["price"] = offers.get("price")
                product["currency"] = offers.get("priceCurrency", "ARS")
                product["availability"] = offers.get("availability", "")
            product["image"] = ld.get("image", "")
            product["sku"] = ld.get("sku", "")
        except json.JSONDecodeError:
            pass

    if price_raw:
        try:
            prices = json.loads(price_raw)
            if prices.get("price"):
                product["price"] = prices["price"]
        except json.JSONDecodeError:
            pass

    return product


def main():
    limit, args = parse_limit(sys.argv[1:])
    if not args:
        print("Usage: mercadolibre.py [--limit N] <search|url>", file=sys.stderr)
        sys.exit(1)

    query_or_url = args[0]
    products = []

    pw, browser, context, page = None, None, None, None
    try:
        ws_url = ensure_daemon("about:blank")
        pw, browser, context, page = connect_cdp(ws_url)

        if is_url(query_or_url):
            if is_listing_url(query_or_url):
                products = get_listing_products(query_or_url, limit, pw, browser, context, page)
            elif is_product_url(query_or_url):
                m = re.search(r"(ML[AU]\d+)", query_or_url)
                products = [{"id": m.group(), "url": query_or_url.split('#')[0]}] if m else []
            else:
                print(f"Unrecognized ML URL type: {query_or_url}", file=sys.stderr)
                sys.exit(1)
        else:
            products = get_listing_products(query_or_url, limit, pw, browser, context, page)

        if not products:
            print("[]", file=sys.stderr)
            sys.exit(1)

        # Deduplicate by product ID, take first N
        seen = {}
        unique = []
        for p in products:
            pid = p.get("id", "")
            if pid and pid not in seen:
                seen[pid] = True
                unique.append(p)
            elif not pid:
                unique.append(p)
        unique = unique[:limit]

        # Crawl each product sequentially
        results = []
        for p in unique:
            url = p.get("url", "")
            if not url or not is_url(url):
                continue
            product_data = crawl_product(url, pw, browser, context, page)
            results.append(product_data)

    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if pw:
            disconnect_cdp(pw, browser)

    # Save output
    date_dir = datetime.now().strftime("%Y-%m-%d")
    hour = datetime.now().strftime("%H")
    slug = re.sub(r"[^a-z0-9]", "-", query_or_url.lower())[:60]
    out_file = OUTPUT_DIR / date_dir / f"{hour}-ml-{slug}.json"
    out_file.parent.mkdir(parents=True, exist_ok=True)
    out_file.write_text(json.dumps(results, ensure_ascii=False, indent=2))

    print(json.dumps(results, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
