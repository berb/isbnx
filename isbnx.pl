#! /usr/bin/perl
#
# isbnx.pl [--proc NUMBER_OF_PROCESSES] <filename> [filename2 [...]] 
#
# This program tries to extract a ISBN number from each PDF file in the current directory. 
# It downloads metadata associated with the ISBN number and tags the pdf file with it. 
# Then it moves the processed file to the "_ISBNX_complete" subdirectory.
#
# You can process the files in parallel by using the --proc option.
# Example:
# 	isbnx.pl --proc 5 *.pdf
#
# Needs to be in path:
# 	pdftotext (Xpdf command line tools, https://www.xpdfreader.com/download.html)
# 	pdfinfo, fetch-ebook-metadata, ebook-meta (Included with Calibre, https://calibre-ebook.com/download)
# Tested with: ActivePerl v5.26.3 on MS Windows 8.1. It can be made to work on Unix/Linux with some small modifications.
#


use warnings;
use strict;
use v5.10;
use English;
use File::Glob ':glob';
use Business::ISBN;
use File::Copy;
use List::MoreUtils qw(natatime);
use Getopt::Long;
use POSIX;

my $cmdline="start $PROGRAM_NAME";

die "Filenames cannot contain any of the following characters: \\ \/ \: \< \> \| \"\nThe input filenames must reside in the current directory.\n" if ("@ARGV"=~/\\|\/|\:|\<|\>|\||\"/);
my $proc=1;
GetOptions ('proc=i' => \$proc);

foreach my $arg(@ARGV)
{ 
	if ($arg=~/\*|\?/)
	{	#If the shell didn't take care of the globbing, we'll have to do it manually.
		my @star_files= bsd_glob("$arg");
		foreach my $list(@star_files)
		{	# Push each matching file back in the argument list.
			push @ARGV, $list;
		}
	}
}
@ARGV = grep {!/\*|\?/} @ARGV; #remove the wildard files

if ($proc > 1) # Multiple processes?
{
	my $argv_len=@ARGV;
	my $it = natatime POSIX::ceil($argv_len/$proc), @ARGV;
	my @vals;
	while (@vals = $it->())
	{
		#say @vals;
		# print "$argv_len ". POSIX::ceil($argv_len/$proc)." @vals\n";
		
		my $val_args = join("\" \"", @vals);
		say "$cmdline \"$val_args\"\n";
		system("$cmdline \"$val_args\"");
	}
	die "Parent exiting...";
}

foreach my $arg(@ARGV)
{ 
	my $dir="_ISBNX_complete";
	mkdir $dir;
	my $file=$arg;
	my $isbn;
#			say "\$isbn=extractisbn($file)";
	$isbn=extractisbn($file);
#	say "\$isbn = $isbn";
	if ($isbn ne "0") 
	{
		# $isbn=verifyisbn($isbn);
#		say "\$isbn = $isbn";
		if ($isbn ne "0")
		{
			say "$file has ISBN: $isbn\n";
			if(lookupandmark($file, $isbn))
			{
				move($file,$dir);
			}
		}
		else
		{
			say "$file has no ISBN!\n";
		}
	}
	else
	{
		say "$file has no ISBN!\n";
	}
}
print "Finished. Press Enter to continue...";
<STDIN>;

sub extractisbn
{
	my ($f) = @_;
	my $regex1=qr/(?:ISBN|isbn).*?\n*?.*?(?<isbn>[0-9\-\.–­―—\^ ]{9,28}[0-9xX])/;
	my $regex2=qr/(?<isbn>[0-9\-\.–­―—\^ ]{9,28}[0-9xX])/;
	my $ex_isbn;
#	say "\$f= $f";

#	say "$f har $pages sidor";
	say "pdftotext -f 1 -l 30 \"$f\" -";
	my $filedump=`pdftotext -f 1 -l 30 "$f" -`;
	while ($filedump=~ m/$regex1/g)
	{	
		#say "\$+{isbn} = $+{isbn}";
		$ex_isbn = verifyisbn($+{isbn});
		if ($ex_isbn) { return $ex_isbn; }
	}
#	while ($filedump=~ m/(?<isbn>[0-9\-\.–­―—\^ ]{9,28}[0-9xX])/g)
	while ($filedump =~ m/$regex2/g)
	{
		#say "\$+{isbn} = $+{isbn}";
		$ex_isbn = verifyisbn($+{isbn});
		if ($ex_isbn) { return $ex_isbn; }
	}

	my $pages=`pdfinfo "$f"`;
	$pages=~ m/Pages:\s*([0-9]+)/;
	$pages=$1;
	my $first=$pages-30;
	say "pdftotext -f $first -l $pages \"$f\" -";
	$filedump=`pdftotext -f $first -l $pages "$f" -`;
	while ($filedump=~ m/$regex1/g)
	{
		$ex_isbn = verifyisbn($+{isbn});
		if ($ex_isbn) { return $ex_isbn; }
	}
	while ($filedump=~ m/$regex2/g)
	{
		$ex_isbn = verifyisbn($+{isbn});
		if ($ex_isbn) { return $ex_isbn; }
	}
	return 0;
}

sub verifyisbn
{
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
	my $icheck = Business::ISBN->new($i);
	unless ($icheck->is_valid) { return 0 };
	return $i 
}
sub lookupandmark
{
	my $tempfilename="temp_$PID.txt";
	my($f, $i) = @_;
#	say "fetch-ebook-metadata -i $i";
	if ( system("fetch-ebook-metadata -i $i -o >$tempfilename") == 0 )
	{
		system("ebook-meta \"$f\" --isbn $i --from-opf $tempfilename");
		unlink "$tempfilename" or warn "Could not unlink $tempfilename: $!";
		return 1;
	}
	else
	{
		unlink "$tempfilename" or warn "Could not unlink $tempfilename: $!";
		return 0;
	}
	
	
}
