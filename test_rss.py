import xml.etree.ElementTree as ET

tree = ET.parse('rss_test.xml')
root = tree.getroot()
ns = {'atom': 'http://www.w3.org/2005/Atom'}

count = 0
with open('rss_result.txt', 'w', encoding='utf-8') as f:
    for entry in root.findall('atom:entry', ns):
        published = entry.find('atom:published', ns)
        if published is not None and published.text.startswith('2026-02-27'):
            count += 1
            title = entry.find('atom:title', ns)
            f.write(f"[{published.text}] {title.text}\n")
    f.write(f"\nTOTAL: {count}\n")
