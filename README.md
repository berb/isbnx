# isbnx
Extracts ISBN numbers from PDF files. Very experimental.

isbnx.pl <filename> [filename2 [...]] 
This program tries to extract a ISBN number from each PDF file. Then it downloads metadata 
associated with the ISBN number and tags the pdf file with it. 

Needs to be in path: 
                      pdftotext (Xpdf command line tools, https://www.xpdfreader.com/download.html)
                      pdfinfo, fetch-ebook-metadata, ebook-meta (Included with Calibre, https://calibre-ebook.com/download)

Tested with:  ActivePerl v5.26.3 on MS Windows 8.1.
