# pmath-v chal
Consume eBay's GetCategories API, showing all the descendants of a giving category

##### To run locally:
```commandline
./categories.sh --rebuild
./categories.sh --render <category_id>
```

The above output's a file called `<category_id>`.html containing all descendants nodes of the current category

The file is saved in the root directory and can be viewed in a browser.
