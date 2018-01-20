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
my $filePdg      = $FindBin::RealBin . '/../Samples/ShogiPlayers';
my $fileMakeWin  = $FindBin::RealBin . '/../makefile.ShogiPlayers.win';
my @groups       = qw(pro lady extra);
my $attributes   = <<EOL;
attribute %male { color="blue", style=filled, fillcolor="lightblue" }
attribute %female { color="red", style=filled, fillcolor="pink" }
EOL
my $makeRules = <<'EOS';

.SUFFIXES: .svg .png .dot .pdg

.dot.svg:
	dot -Tsvg -o $@ $<

.dot.png:
	dot -Tpng -o $@ $<

.pdg.dot:
	perl ./PdgToDot.pl $<

all: svg png

svg: $(SVGS)

png: $(PNGS)

dot: $(DOTS)

clean:
	del /Q "$(DIR_SAMPLES)\*.svg" "$(DIR_SAMPLES)\*.png" "$(DIR_SAMPLES)\*.dot" "$(DIR_SAMPLES)\*_LR.pdg"
EOS
my $makeTarget = <<'EOS';
ShogiPlayers_N_: $(DIR_SAMPLES)/ShogiPlayers_N_.svg $(DIR_SAMPLES)/ShogiPlayers_N_.png
$(DIR_SAMPLES)/ShogiPlayers_N_.svg:
$(DIR_SAMPLES)/ShogiPlayers_N_.png:
$(DIR_SAMPLES)/ShogiPlayers_N_.dot:
EOS
my $players      = LoadFile($filePlayers);
my $extraIndex   = 0;
my @persons      = ();
my %grandMasters = ();

prepareMaster();
scanPlayers();
my $template = loadTemplate($fileTemplate);
$template =~ s/(direction\s+)TB/$1LR/;
my $grandMasterIndex  = 0;
my @grandMasterLabels = sort {
    my ( $aGroup, $aNo ) = split( '_', $a );
    my ( $bGroup, $bNo ) = split( '_', $b );
    return $aGroup cmp $bGroup || $aNo <=> $bNo;
} ( keys(%grandMasters) );
foreach my $grandMasterLabel (@grandMasterLabels) {
    ++$grandMasterIndex;
    my $grandMaster = $grandMasters{$grandMasterLabel};
    my %replace     = (
        PdgTitle    => 'ShogiPlayers' . $grandMasterIndex,
        Options     => '',
        Attributes  => $attributes,
        Persons     => convPersons( $grandMaster->{'Players'} ),
        Generations => '',
        Families    => convFamilies( $grandMaster->{'Families'} ),
    );
    my $body = $template;
    $body =~ s/\{\{\{([^\}]+)\}\}\}/$replace{$1}/ge;
    savePdg( $filePdg . sprintf( "%02d", $grandMasterIndex ) . '.pdg', $body );
}
makeMakeFile($grandMasterIndex);

sub prepareMaster {
    foreach my $g (@groups) {
        my $group = $players->{$g};
        foreach my $no ( sort { $a <=> $b } ( keys( %{$group} ) ) ) {
            my $player = $group->{$no};
            my $playerId = [ $g, $no ];
            $player->{'MasterId'} = findMaster( $player->{'師匠'} );
        }
    }
}

sub scanPlayers {
    foreach my $g (@groups) {
        my $group = $players->{$g};
        foreach my $no ( sort { $a <=> $b } ( keys( %{$group} ) ) ) {
            my $player           = $group->{$no};
            my $playerId         = [ $g, $no ];
            my $masterId         = $player->{'MasterId'};
            my $grandMasterId    = findGrandMaster($masterId) || $playerId;
            my $grandMasterLabel = $grandMasterId->[0] . '_' . $grandMasterId->[1];
            if ( !$grandMasters{$grandMasterLabel} ) {
                $grandMasters{$grandMasterLabel} = {};
            }
            my $grandMaster = $grandMasters{$grandMasterLabel};
            push(
                @{ $grandMaster->{'Players'} },
                [   $playerId->[0] . '_' . $playerId->[1],
                    $player->{'NameJp'},
                    $g eq 'lady' ? '%female' : '%male',
                ]
            );
            if ($masterId) {
                push(
                    @{ $grandMaster->{'Families'}{ $masterId->[0] }{ $masterId->[1] } },
                    $playerId->[0] . '_' . $playerId->[1]
                );
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
    ++$extraIndex;
    $players->{'extra'}{$extraIndex} = { 'NameJp' => $name, };
    return [ 'extra', $extraIndex ];
}

sub findGrandMaster {
    my $masterId = shift or return;
    my ( $group, $no ) = @{$masterId};
    while ( my $grandMasterId = $players->{$group}{$no}{'MasterId'} ) {
        ( $group, $no ) = @{$grandMasterId};
    }
    return [ $group, $no ];
}

sub convPersons {
    my $refPersons = shift or return;
    return join( "\n",
        map { 'person ' . $_->[0] . ' {' . $_->[1] . '} [' . $_->[2] . ']' } @{$refPersons} );
}

sub convFamilies {
    my $refFamilies = shift or return '';
    my @families = ();
    foreach my $g (@groups) {
        my $group = $refFamilies->{$g};
        if ( !$group ) {
            next;
        }
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
    open( my $fhOut, ">:utf8", encode( $charsetConsole, $file ) ) or die("$file: $!");
    print $fhOut $body;
    close($fhOut);
}

sub makeMakeFile {
    my $maxTarget = shift or return;
    my @body = ( "# PdgToDot sample (Shogi Players)", "", "DIR_SAMPLES = ./Samples", "", );
    push(
        @body,
        (   "SVGS = \\\n"
                . join( " \\\n",
                map { sprintf( "\t\$(DIR_SAMPLES)/ShogiPlayers%02d.svg", $_ ); }
                    ( 1 .. $maxTarget ) ),
            "PNGS = \\\n"
                . join( " \\\n",
                map { sprintf( "\t\$(DIR_SAMPLES)/ShogiPlayers%02d.png", $_ ); }
                    ( 1 .. $maxTarget ) ),
            "DOTS = \\\n"
                . join( " \\\n",
                map { sprintf( "\t\$(DIR_SAMPLES)/ShogiPlayers%02d.dot", $_ ); }
                    ( 1 .. $maxTarget ) ),
        )
    );
    push( @body, $makeRules );
    push( @body,
        map { my $t = $makeTarget; $t =~ s/_N_/sprintf("%02d", $_)/ge; $t; } ( 1 .. $maxTarget ) );
    open( my $fhOut, ">:utf8", encode( $charsetConsole, $fileMakeWin ) ) or die("$fileMakeWin: $!");
    print $fhOut join( "\n", @body );
    close($fhOut);
}
