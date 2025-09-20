# 📚 isbnx

This is a fork and enhancement from [amigatomte/isbnx](https://github.com/amigatomte/isbnx/).

## 💡 Overview

`isbnx.pl` is a Perl script to help organizing large collections of arbitrarily named, ebooks (PDF/EPUB) by extracting the ISBN-13 identifier – if available – from the contents and using it as filename (and optionally, to use the ISBN number as a unique identifier for online meta data fetching). 

Internally, the script utilizes `poppler-utils` for PDF-to-text conversion and `calibre` for EPUB and meta data handling.

## 🛠️ Usage

```
isbnx.pl 
	[--parallel NUMBER_OF_PROCESSES] 
	[--sleep SECONDS_TO_WAIT] 
	[--write] 
	[--copy] 
	[--move] 
	[--completed-dir <target-dir>] 
	[--failed-dir <target-dir>] 
	<filename> [filename2 [...]] 
```

This Perl script takes a set of book files as input and tries to extract the ISBN number from each file.
If successful, the ISBN number is shown for each file.
In addition, the script also allows the following further actions:
  * `--parallel` -ize the execution to N parallel jobs
  * `--sleep` to add waiting time (in seconds) before fetching the online meta data
  * `--write` new meta data into the book file based on online sources and by using the ISBN
  * `--copy` successfully and unsuccessfully resolved book files into different target folders
  * `--move` successfully and unsuccessfully resolved book files into different target folders
  * `--rename`  successfully resolved file in-place 

The target folders can be specified via `--completed-dir` and `--failed-dir`. If `--copy` or `--move` is used, the ISBN-13 identifier is used as the target filename for successfully resolved PDFs.

## 🛑 Caution

 * ⚠️ This script can be run to modify and move book files. Please backup original files before usage.
 * ⚠️ When using this script with a large batch of book files, it is recommended to disable parallelism and add a sleep time to prevent running into rate limiting.

## ✅ Requirements

The following dependencies are required on a Debian/Ubuntu-based system:

 * `libparallel-forkmanager-perl`
 * `libsys-info-perl`
 * `libbusiness-isbn-perl`
 * `poppler-utils` (for `pdftotext`)
 * `calibre` (for `fetch-ebook-metadata` and `ebook-meta`)

## 🧩 Example Usages

```sh
$ perl isbnx.pl --move --completed-dir okay/ --failed-dir oops/ *.pdf *.epub
```
Will process all files in the current directory. If the ISBN number can be extracted, the file will be renamed to the ISBN identifier and moved to folder `okay/`. 
Otherwise, the file will be moved to `oops/` for manual review.

```sh
$ perl isbnx.pl --write *.pdf
```
Will replace (overwrite!) the PDF meta data of all matching PDF files by online-fetched data in case the ISBN can be extracted from the PDF.

```sh
$ perl isbnx.pl --replace *.epub
```
Will rename all matching EPUB files to an ISBN-13-based filename when the ISBN had been resolved.


## 🤝 Acknowledgements

Thanks to [amigatomte](https://github.com/amigatomte) for the original script.