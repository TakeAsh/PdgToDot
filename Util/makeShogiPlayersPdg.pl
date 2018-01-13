#!/usr/bin/perl
# make SHOGI players pedigree.

use strict;
use warnings;
use utf8;
use Encode;
use FindBin;
use LWP::UserAgent;
use HTML::DOM;
use YAML::Syck qw(Load Dump LoadFile DumpFile);

$|                           = 1;
$YAML::Syck::ImplicitUnicode = 1;

my $charsetConsole = $^O eq 'MSWin32' ? 'CP932' : 'UTF-8';    # detect platform
my $charsetFile = 'UTF-8';

binmode( STDIN,  ":encoding($charsetConsole)" );
binmode( STDOUT, ":encoding($charsetConsole)" );
binmode( STDERR, ":encoding($charsetConsole)" );

my $filePlayers  = $FindBin::RealBin . '/ShogiPlayers.yml';
my $fileTemplate = $FindBin::RealBin . '/template.pdg';
my $filePdg      = $FindBin::RealBin . '/../Samples/ShogiPlayers.pdg';
my @groups       = qw(pro lady extra);
my $attributes   = <<EOL;
attribute %male { color="blue", style=filled, fillcolor="lightblue" }
attribute %female { color="red", style=filled, fillcolor="pink" }
EOL
my $players    = LoadFile($filePlayers);
my $extraIndex = 0;
my @persons    = ();
my %families   = ();

scanPlayers();
my %replace = (
    PdgTitle    => 'ShogiPlayers',
    Options     => '',
    Attributes  => $attributes,
    Persons     => convPersons( \@persons ),
    Generations => '',
    Families    => convFamilies( \%families ),
);
my $body = loadTemplate($fileTemplate);
$body =~ s/\{\{\{([^\}]+)\}\}\}/$replace{$1}/ge;
savePdg( $filePdg, $body );

sub scanPlayers {
    foreach my $g (@groups) {
        my $group = $players->{$g};
        foreach my $no ( sort { $a <=> $b } ( keys( %{$group} ) ) ) {
            my $player = $group->{$no};
            my $label  = $g . '_' . $no;
            push( @persons, [ $label, $player->{'NameJp'}, $g eq 'lady' ? '%female' : '%male', ] );
            my $master = findMaster( $player->{'師匠'} );
            if ($master) {
                push( @{ $families{ $master->[0] }{ $master->[1] } }, $label );
            }
        }
    }
}

sub findMaster {
    my $name = shift or return;
    $name =~ s/^[\(（]故[\)）]//;
    while ( $name
        =~ s/([四五六七八九十]段|竜王|名人|棋聖|王位|王座|棋王|王将)$//g )
    {
        $name =~ s/(名誉|永世|十[三四五六]世|実力制第四代)$//;
        $name =~ s/・$//;
    }
    $name =~ s/\s//g;
    foreach my $g (@groups) {
        my $group = $players->{$g};
        foreach my $no ( sort { $a <=> $b } ( keys( %{$group} ) ) ) {
            my $player = $group->{$no};
            if ( $name eq $player->{'NameJp'} ) {
                return [ $g, $no ];
            }
        }
    }
    $players->{'extra'}{ ++$extraIndex } = { 'NameJp' => $name, };
    return [ 'extra', $extraIndex ];
}

sub convPersons {
    my $refPersons = shift or return;
    return join( "\n",
        map { 'person ' . $_->[0] . ' {' . $_->[1] . '} [' . $_->[2] . ']' } @{$refPersons} );
}

sub convFamilies {
    my $refFamilies = shift or return;
    my @families = ();
    foreach my $g (@groups) {
        my $group = $refFamilies->{$g};
        foreach my $no ( sort { $a <=> $b } ( keys( %{$group} ) ) ) {
            my $f = $group->{$no};
            push( @families, '(' . $g . '_' . $no . ') - (' . join( " ", @{$f} ) . ')' );
        }
    }
    return join( "\n", @families );
}

sub loadTemplate {
    my $file = shift or return;
    open( my $fhIn, "<:utf8", encode( $charsetConsole, $file ) ) or die("$!: $file");
    my @body = <$fhIn>;
    close($fhIn);
    return join( "", @body );
}

sub savePdg {
    my $file = shift or return;
    my $body = shift or return;
    open( my $fhOut, ">:utf8", encode( $charsetConsole, $file ) ) or die("$!: $file");
    print $fhOut $body;
    close($fhOut);
}
