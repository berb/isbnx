#!/usr/bin/env perl -w
#
# isbnx.pl [--parallel NUMBER_OF_PROCESSES] [--sleep SECONDS_TO_WAIT] [--write] [--copy] [--move] [--completed-dir <target-dir>] [--failed-dir <target-dir>] <filename> [filename2 [...]] 
#
# This Perl script takes a set of PDF files as input and tries to extract the ISBN number from each file.
# If successful, the ISBN number is shown for each file.
# In addition, the script also allows the following further actions:
#   * --parallel to allow the execution of up to  N parallel jobs
#   * --sleep to add waiting time (in seconds) before fetching the online meta data
#   * --write new meta data into the PDF based on online sources and by using the ISBN
#   * --copy successfully and unsuccessfully resolved PDF files into different target folders
#   * --move successfully and unsuccessfully resolved PDF files into different target folders
#
# The target folders can be specified via --completed-dir and --failed-dir. If --copy or --move is used, the ISBN-13 identifier is used as filename.
#
# When using this script with a large batch of PDF files, it is recommended to disable parallelism and add a sleep time to prevent rate limiting penalties.
#

use strict;
use warnings;
use feature 'say';

use Parallel::ForkManager;
use Getopt::Long;
use POSIX;
use File::Copy;
use File::Path qw(make_path);
use File::Temp qw(tempfile);
use File::Spec qw(catfile);


use List::Util qw(max);
use Sys::Info;
use Business::ISBN;

use Data::Dumper qw(Dumper);

# Die with a usage message if no files were provided.
die "Usage: $0 file1.pdf [file2.pdf ...]\n" unless @ARGV;


my $targetDirWithoutISBN = "_WITHOUT_ISBN";
my $targetDirWithISBN = "_WITH_ISBN";
my $parallel = max((Sys::Info->new->device( CPU => my %options )->count || 1) -1, 1); #use N-1 cores, minimum 1 times multiplier (4)
my $moveflag = '';
my $copyflag = '';
my $sleep = 5;
my $writemetadataflag = '';
GetOptions ('parallel=i' => \$parallel,
            'completed-dir=s' => \$targetDirWithISBN,
            'failed-dir=s' => \$targetDirWithoutISBN,
            'sleep=i' => \$sleep,
            'move' => \$moveflag,
            'copy' => \$copyflag,
            'write' => \$writemetadataflag);

if($copyflag && $moveflag){
    die("Cannot combine copy and move flag");
}elsif($copyflag || $moveflag){
    unless (-d "$targetDirWithISBN"){ 
        make_path($targetDirWithISBN) or die "Error while creating the directory for completed PDFs: $!"; 
    }
    unless (-d "$targetDirWithoutISBN"){ 
        make_path($targetDirWithoutISBN) or die "Error while creating the directory for failed PDFs: $!"; 
    }
}


my $manager = Parallel::ForkManager->new($parallel);    #2 concurrent

PDFs: foreach my $file (@ARGV) {
    unless (-f $file && -r _) {
        warn "Skipping '$file': not a readable file.\n";
        next PDFs;
    }
    sleep(5);
    $manager->start and next PDFs;
    my ($isbn) = _extract_isbn($file);
    if($isbn){
        say "[$isbn] ".$file;
        if($writemetadataflag){
            if(_update_meta_data($file,$isbn)){

            }
            else{
                warn "Error while updating meta data of $file.";
            }
        }
        if($moveflag){
            move($file, File::Spec->catfile($targetDirWithISBN,$isbn.".pdf"));
        }elsif($copyflag){
            copy($file, File::Spec->catfile($targetDirWithISBN,$isbn.".pdf"));
        }
    } else {
        say "[???-?-?????-???-?] ".$file;
        if($moveflag){
            move($file, $targetDirWithoutISBN)
        }elsif($copyflag){
            copy($file, $targetDirWithoutISBN)
        }

    }
    $manager->finish;
}
$manager->wait_all_children;


sub _extract_isbn{
    my ($file) = @_;
	my $regex1=qr/(?:ISBN\-13|ISBN13|ISBN\-10|ISBN10|ISBN|isbn).*?\n*?.*?(?<isbn>[0-9\-\.–­―—\^ ]{9,28}[0-9xX])/;
	my $regex2=qr/(?<isbn>[0-9\-\.–­―—\^ ]{9,28}[0-9xX])/;
	my $ex_isbn;

	my $pdftext=`pdftotext -f 1 -l 16 "$file" - 2>/dev/null`;
    for my $regex ($regex1, $regex2){
        while ($pdftext=~ m/$regex/g)
        {	
            my $extracted_isbn = _verify_isbn($+{isbn});
            if ($extracted_isbn) { 
                return $extracted_isbn; 
            }			
        }
    }
    return 0;
}

sub _verify_isbn{
    my ($i) = @_;
	$i =~ s/[^0-9xX]//g;
	if (length($i) < 10) 
	{ 
		return 0;
	}
	if (length($i) > 10 && length($i) < 13)
	{
		$i = substr($i, 0, 10);
	}
	elsif (length($i) > 13)
	{
		$i = substr($i, 0, 13);
	}

    my $icheck = Business::ISBN->new($i) or return 0;
	unless ($icheck->is_valid || $icheck->error == -3) { 
		return 0;
	};
    return $icheck->as_isbn13->as_string;
}

sub _update_meta_data{
    my($file, $isbn) = @_;
    my ($tfh, $tmpfile) = tempfile();
    #say $tmpfile;

    if(system("fetch-ebook-metadata --isbn=$isbn --opf >$tmpfile 2> /dev/null") == 0){
        system("ebook-meta \"$file\" --isbn $isbn --from-opf $tmpfile 1> /dev/null 2> /dev/null");
		unlink "$tmpfile" or warn "Could not unlink $tmpfile: $!";
        return 1;        
    } else {
		unlink "$tmpfile" or warn "Could not unlink $tmpfile: $!";
        return 0;
    }
}