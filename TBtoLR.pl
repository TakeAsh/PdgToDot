#!/usr/bin/perl
# convert "direction TB" to "direction LR".

use strict;
use warnings;
use utf8;
use Encode;

my $platform       = $^O;                                          # MSWin32 | linux | darwin
my $charsetConsole = $platform eq 'MSWin32' ? 'CP932' : 'UTF-8';
my $charsetFile    = 'UTF-8';

binmode( STDIN,  ":encoding($charsetConsole)" );
binmode( STDOUT, ":encoding($charsetConsole)" );
binmode( STDERR, ":encoding($charsetConsole)" );

@ARGV = map { decode( $charsetConsole, $_ ); } @ARGV;

my $ioLayer = $platform eq 'MSWin32' ? "raw:encoding($charsetFile):crlf" : "encoding($charsetFile)";

my $fileNameIn = shift(@ARGV) or die("usage: TBtoLR.pl <input.pdg>\n");
my $filenameOut = $fileNameIn;
$filenameOut =~ s/(\.pdg)$/_LR$1/;
open( my $fhIn, "<:$ioLayer", encode( $charsetConsole, $fileNameIn ) )
    or die("$!: $fileNameIn");
open( my $fhOut, ">:$ioLayer", encode( $charsetConsole, $filenameOut ) )
    or die("$!: $filenameOut");
while ( $_ = <$fhIn> ) {
    $_ =~ s/^(\s*direction\s+)TB/$1LR/;
    print $fhOut $_;
}
close($fhIn);
close($fhOut);
