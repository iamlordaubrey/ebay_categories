import sqlite3
import subprocess
import xml.etree.ElementTree as ET

result = subprocess.run('./query_ebay.sh', stdout=subprocess.PIPE).stdout

# Parse xml from result (string) into an element, specifying root tag of CategoryArray (index 4)
root = ET.fromstring(result)[4]
db_name = 'pmath.db'

CategoryID = '{urn:ebay:apis:eBLBaseComponents}CategoryID'
CategoryName = '{urn:ebay:apis:eBLBaseComponents}CategoryName'
CategoryLevel = '{urn:ebay:apis:eBLBaseComponents}CategoryLevel'
CategoryParentID = '{urn:ebay:apis:eBLBaseComponents}CategoryParentID'
BestOfferEnabled = '{urn:ebay:apis:eBLBaseComponents}BestOfferEnabled'
LeafCategory = '{urn:ebay:apis:eBLBaseComponents}LeafCategory'

root_nodes = [element for element in list(root) if element.find(CategoryID).text == element.find(CategoryParentID).text]


def closure_values(the_root_node):
    queue = [the_root_node]
    exclusive_list = []
    values_list = []
    while len(queue):
        # List of root_node ids
        ids = [n.find(CategoryID).text for n in queue]
        current_node = queue.pop(0)

        values = [the_root_node.find(CategoryID).text, current_node.find(CategoryID).text]
        values[0] = int(values[0])
        values[1] = int(values[1])

        values_list.append((values[0], values[1]))

        current_id = current_node.find(CategoryID).text
        array_node = [
            element for element in list(root)
            if current_id == element.find(CategoryParentID).text
            and element.find(CategoryID).text not in ids
        ]

        exclusive_list.append(current_id)

        for child in array_node:
            queue.append(child)

    # Do a db insertion here / call a db insertion function
    print(values_list, 'closure')
    db_insert(values_list, 'category_closure')

    for node in [
        element for element in list(root)
        if the_root_node.find(CategoryID).text == element.find(CategoryParentID).text
        and element.find(CategoryID).text != the_root_node.find(CategoryID).text
    ]:
        closure_values(node)


def category_values():
    values_list = []
    for element in list(root):
        cat_id = element.find(CategoryID)
        cat_name = element.find(CategoryName)
        cat_level = element.find(CategoryLevel)
        cat_parent_id = element.find(CategoryParentID)
        best_offer_enabled = element.find(BestOfferEnabled)

        values = [
            cat_id, cat_name, cat_level, cat_parent_id, best_offer_enabled
        ]
        values = [i.text if i is not None else 'Null' for i in values]
        values[0] = int(values[0])
        values[2] = int(values[2])
        values[3] = int(values[3])

        values_list.append((values[0], values[1], values[2], values[3], values[4]))

    # Do a db insertion here / call a db insertion function
    print(values_list, 'category')
    db_insert(values_list, 'category')


def db_insert(values, table='category'):
    category_table = {
        'category': '(?, ?, ?, ?, ?)',
        'category_closure': '(?,?)',
    }

    conn = sqlite3.connect(db_name)
    c = conn.cursor()
    a = 'insert into {0} values {1}'.format(table, category_table[table])
    c.executemany(a, values)

    conn.commit()
    conn.close()


if __name__ == '__main__':
    [closure_values(node) for node in root_nodes]
    category_values()
