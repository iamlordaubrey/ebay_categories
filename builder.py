import sqlite3
import subprocess
import xml.etree.ElementTree as ET

result = subprocess.run('./query_ebay.sh', stdout=subprocess.PIPE).stdout

# Parse xml from result (string) into an element, specifying root tag of CategoryArray (index 4)
root = ET.fromstring(result)[4]
print(len(root))


def xml_parser(root_tag):
    for child in root_tag:
        best_offer_enabled = child.find('{urn:ebay:apis:eBLBaseComponents}BestOfferEnabled')
        category_id = child.find('{urn:ebay:apis:eBLBaseComponents}CategoryID')
        category_name = child.find('{urn:ebay:apis:eBLBaseComponents}CategoryName')
        category_level = child.find('{urn:ebay:apis:eBLBaseComponents}CategoryLevel')
        category_parent_id = child.find('{urn:ebay:apis:eBLBaseComponents}CategoryParentID')
        leaf_category = child.find('{urn:ebay:apis:eBLBaseComponents}LeafCategory')

        category_values = [
            category_id, category_name, category_level, best_offer_enabled, category_parent_id, leaf_category
        ]
        category_values = [i.text if i is not None else None for i in category_values]
        category_values[0] = int(category_values[0])
        category_values[2] = int(category_values[2])
        category_values[4] = int(category_values[4])

        closure_values = (category_values[4], category_values[0], category_values[2])

        yield category_values, closure_values


def db_insert(values):
    category_val = values[0]
    closure_val = values[1]

    # Try in-memory database https://stackoverflow.com/a/32239587/4333429
    # OR
    # use sql transactions https://stackoverflow.com/questions/5942402/python-csv-to-sqlite/7137270#7137270
    # print(closure_val)
    c.execute('INSERT INTO category VALUES (?, ?, ?, ?, ?, ?)', category_val)
    c.execute('INSERT INTO category_closure VALUES (?, ?, ?)', closure_val)


if __name__ == '__main__':
    conn = sqlite3.connect('pmath.db')
    c = conn.cursor()

    for value in xml_parser(root):
        db_insert(value)

    conn.commit()
    conn.close()
