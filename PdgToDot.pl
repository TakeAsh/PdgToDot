#!/usr/bin/perl
# convert Pedigree to Graphviz dot.

use strict;
use warnings;
use utf8;
use Encode;
use File::Basename;

my @extPdg    = qw( .pdg );
my $suffixOut = '.dot';
my $attrJoint = hashToAttr(
    {   shape  => 'point',
        width  => 0.01,
        height => 0.01,
    }
);

my $platform       = $^O;                                          # MSWin32 | linux | darwin
my $charsetConsole = $platform eq 'MSWin32' ? 'CP932' : 'UTF-8';
my $charsetFile    = 'UTF-8';

binmode( STDIN,  ":encoding($charsetConsole)" );
binmode( STDOUT, ":encoding($charsetConsole)" );
binmode( STDERR, ":encoding($charsetConsole)" );

@ARGV = map { decode( $charsetConsole, $_ ); } @ARGV;

if ( !@ARGV ) {
    die("usage: PdgToDot.pl <-|input.pdg>\n");
}

my $ioLayer = $platform eq 'MSWin32' ? "raw:encoding($charsetFile):crlf" : "encoding($charsetFile)";
my $isDirTopBottom  = 1;
my %namedAttributes = ();
my $familyIndex     = -1;

my $fileNameIn = shift(@ARGV);
if ( $fileNameIn eq '-' ) {
    convertPipe();
} else {
    convertFile($fileNameIn);
}

exit;

sub convertPipe {
    my @body = <STDIN>;
    my $body = convertBody( join( "", @body ) );
    print STDOUT $body;
}

sub convertFile {
    my ($fileNameIn) = @_;
    my ( $name, $path, $suffixIn ) = fileparse( $fileNameIn, @extPdg );
    if ( !$suffixIn ) {
        return;
    }
    my $filenameOut = $path . $name . $suffixOut;
    open( my $fhIn, "<:$ioLayer", encode( $charsetConsole, $fileNameIn ) )
        or die("$!: $fileNameIn");
    my @body = <$fhIn>;
    close($fhIn);
    my $body = convertBody( join( "", @body ) );
    open( my $fhOut, ">:$ioLayer", encode( $charsetConsole, $filenameOut ) )
        or die("$!: $filenameOut");
    print $fhOut $body;
    close($fhOut);
}

sub convertBody {
    my $body = shift or return;
    my %graphAttr = ( 'charset' => $charsetFile, 'splines' => 'ortho' );
    getGlobalAttribute( \$body, \%graphAttr, 'rankdir', qr(^\s*direction\s+(\S+).*$)m );
    getGlobalAttribute( \$body, \%graphAttr, 'dpi',     qr(^\s*dpi\s+(\S+).*$)m );
    my %nodeAttr = ( 'shape' => 'record', );
    getGlobalAttribute( \$body, \%nodeAttr, 'fontname', qr(^\s*fontname\s+"([^"]+)".*$)m );
    setDefault( \$body, 'node',  \%nodeAttr );
    setDefault( \$body, 'graph', \%graphAttr );
    $isDirTopBottom = $graphAttr{'rankdir'} eq 'TB' ? 1 : 0;
    $body =~ s/attribute\s+(%\S+)\s+\{([^\}]+)\}/getNamedAttribute($1, $2)/eg;
    $body =~ s/person\s+(\S+)\s+\{([^\}]+)\}(?:\s+\[([^\]]+)\])?/convertPerson($1, $2, $3)/eg;
    $body =~ s/generation\s*\{([^\}]+)\}/convertGeneration($1)/eg;
    $body =~ s/\(([^\)]+)\)\s*-\s*\(([^\)]+)\)/convertFamily($1, $2)/eg;
    $body =~ s/\@startPdg\s+"([^"]+)"\s*/graph "$1" {\n/;
    $body =~ s/\@endPdg\s*/}\n/;
    return $body;
}

sub getGlobalAttribute {
    my ( $refBody, $refHash, $name, $reg ) = @_;
    if ( ${$refBody} !~ $reg ) {
        return;
    }
    $refHash->{$name} = $1;
    ${$refBody} =~ s/$reg//m;
}

sub setDefault {
    my ( $refBody, $name, $refHash ) = @_;
    my $attr = hashToAttr($refHash);
    ${$refBody} =~ s/(^\@startPdg\s+.*$)/$1\n$name $attr/m;
}

sub getNamedAttribute {
    my ( $name, $attributes ) = @_;
    $namedAttributes{$name} = {
        map {
            $_ = trim($_);
            my ( $key, $value ) = split( /\s*=\s*/, $_ );
            $value =~ s/^"(.*)"$/$1/;
            $key => $value;
        } split( /[,;]/, trim($attributes) )
    };
    return '';
}

sub convertPerson {
    my ( $label, $body, $attributes ) = @_;
    $body = trim($body);
    my @commnet = map { $_ = trim($_); s/\s+/&nbsp;/g; $_; } split( /\n/, $body );
    my @attrLabels = ( ' ' . shift(@commnet) );
    if (@commnet) {
        push( @attrLabels, join( '\\l', @commnet ) . '\\l' );
    }
    my $attLabel
        = $isDirTopBottom
        ? '{' . join( '| ', @attrLabels ) . '}'
        : join( '| ', @attrLabels );
    my %attributes = ();
    if ($attributes) {
        map {
            $_ = trim($_);
            if ( substr( $_, 0, 1 ) eq '%' && $namedAttributes{$_} ) {
                %attributes = ( %attributes, %{ $namedAttributes{$_} } );
            } else {
                my ( $key, $value ) = split( /\s*=\s*/, $_ );
                $value =~ s/^"(.*)"$/$1/;
                $attributes{$key} = $value;
            }
        } split( /[,;]/, trim($attributes) );
    }
    return $label . ' ' . hashToAttr( { %attributes, label => $attLabel } );
}

sub convertGeneration {
    my $persons = shift or return;
    return '{rank=same; ' . join( " -- ", split( /\s+/, trim($persons) ) ) . ' [style=invis]}';
}

sub convertFamily {
    my ( $parents, $children ) = @_;
    ++$familyIndex;
    my @family            = ();
    my @parents           = split( /\s+/, trim($parents) );
    my @children          = split( /\s+/, trim($children) );
    my @joints            = ();
    my @parentChildren    = ();
    my @lineJointChildren = ();
    my $rankParents       = undef;
    my $rankJoints        = undef;
    if ( @parents < 2 ) {
        push( @parentChildren, $parents[0] );
    } else {
        my $jointParents = 'f' . $familyIndex . '_p';
        push( @joints,         $jointParents . ' ' . $attrJoint );
        push( @parentChildren, $jointParents );
        my $p0 = shift(@parents);
        @parents = ( $p0, $jointParents, @parents );
        $rankParents = '{rank=same; ' . join( ' -- ', @parents ) . ' [style=bold]}';
    }
    if ( @children < 2 ) {
        my $jointChild = 'f' . $familyIndex . '_c';
        push( @joints,            $jointChild . ' ' . $attrJoint );
        push( @parentChildren,    $jointChild );
        push( @lineJointChildren, $jointChild . ' -- ' . $children[0] );
    } else {
        my @jointChildren = map { 'f' . $familyIndex . '_c' . $_; } ( 0 .. 2 );
        map { push( @joints, $_ . ' ' . $attrJoint ); } @jointChildren;
        $rankJoints = '{rank=same; ' . join( ' -- ', @jointChildren ) . '}';
        push( @parentChildren, $jointChildren[1] );
        for ( my $i = 0; $i < @children; ++$i ) {
            my $joint
                = $i == @children - 1
                ? $jointChildren[2]
                : $jointChildren[ int( 3 * $i / @children ) ];
            push( @lineJointChildren, $joint . ' -- ' . $children[$i] );
        }
    }
    push( @family, @joints );
    if ($rankParents) {
        push( @family, $rankParents );
    }
    if ($rankJoints) {
        push( @family, $rankJoints );
    }
    push( @family, join( ' -- ', @parentChildren ) );
    if (@lineJointChildren) {
        push( @family, @lineJointChildren );
    }
    return join( "\n", @family );
}

sub hashToAttr {
    my $refHash = shift or return;
    my @attr = map { $_ . '="' . $refHash->{$_} . '"' } sort( keys( %{$refHash} ) );
    return '[' . join( ", ", @attr ) . ']';
}

sub trim {
    my $text = shift or return;
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;
    return $text;
}
