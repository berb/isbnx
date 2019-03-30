# isbnx
## Extracts ISBN numbers from PDF files. Very experimental.  

This program tries to extract a ISBN number from each PDF file. Then it downloads metadata 
associated with the ISBN number and tags the pdf file with it.  

You can process the files in parallell by using the --proc option. 

	isbnx.pl [--proc NUMBER_OF_PROCESSES] <filename> [filename2 [...]] 

Needs to be in path: 
pdftotext (Xpdf command line tools, https://www.xpdfreader.com/download.html)
pdfinfo, fetch-ebook-metadata, ebook-meta (Included with Calibre, https://calibre-ebook.com/download)

Tested with:  ActivePerl v5.26.3 on MS Windows 8.1. It can probably be made to work on Unix/Linux with small modifications.
