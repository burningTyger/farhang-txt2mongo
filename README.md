#txt2mongo#
with txt2mongo you can check the integrity of your lexicon text files as
used in farhang. You pass the file name or wildcard along to check the
file entries. If you pass in a database name as a second argument txt2mongo
will store the entries in your mongodb. If you don't get any output it means
your files are ok. If you get filenames and line numbers it means you need to
correct them. Usually a `;` is forgotten.

To check all files you need to put `*.txt` into quotation marks:

`ruby txt2mongo.rb file.txt|'*.txt' [database]`

example:

`ruby txt2mongo.rb k.txt test_db`

or:

`ruby txt2mongo.rb '*.txt'`
