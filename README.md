# isbnx

This is a fork and enhancement from [amigatomte/isbnx/fork](https://github.com/amigatomte/isbnx/).

## Overview

```
isbnx.pl [--parallel NUMBER_OF_PROCESSES] [--sleep SECONDS_TO_WAIT] [--write] [--copy] [--move] [--completed-dir <target-dir>] [--failed-dir <target-dir>] <filename> [filename2 [...]] 
```

This Perl script takes a set of PDF files as input and tries to extract the ISBN number from each file.
If successful, the ISBN number is shown for each file.
In addition, the script also allows the following further actions:
  * `--parallel` -ize the execution to N parallel jobs
  * `--sleep` to add waiting time (in seconds) before fetching the online meta data
  * `--write` new meta data into the PDF based on online sources and by using the ISBN
  * `--copy` successfully and unsuccessfully resolved PDF files into different target folders
  * `--move` successfully and unsuccessfully resolved PDF files into different target folders

The target folders can be specified via `--completed-dir` and `--failed-dir`. If `--copy` or `--move` is used, the ISBN-13 identifier is used as the target filename for successfully resolved PDFs.

## Caution

 * This script can be run to modify and move PDF files. Please backup original files before usage.
 * When using this script with a large batch of PDF files, it is recommended to disable parallelism and add a sleep time to prevent running into rate limiting.

## Requirements

The following dependencies are required on a Debian/Ubuntu-based system:

 * `libparallel-forkmanager-perl`
 * `libsys-info-perl`
 * `libbusiness-isbn-perl`
 * `poppler-utils` (for `pdftotext`)
 * `calibre` (for `fetch-ebook-metadata` and `ebook-meta`)


