#!/usr/bin/perl
# get SHOGI players database.

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

my $filePlayers = $FindBin::RealBin . '/ShogiPlayers.yml';
my $urlTop      = 'https://www.shogi.or.jp';
my $urlPlayers  = $urlTop . '/player/numerical_order.html';
my $regPlayers  = qr{/player/(pro|lady)/(\d+).html};

my $ua = LWP::UserAgent->new( keep_alive => 4 );
$ua->cookie_jar( {} );

my $players = getPlayers($urlPlayers);
DumpFile( $filePlayers, $players );

sub getPlayers {
    my $url = shift or return;
    my $res = $ua->request( HTTP::Request->new( GET => $url ) );
    if ( !$res->is_success ) {
        die( "Failed: " . $res->status_line . "\n" );
    }
    my $tree = new HTML::DOM( url => $url );
    $tree->write( $res->decoded_content );
    $tree->close();
    my $anchors       = $tree->getElementsByTagName('a');
    my @anchorPlayers = ();
    foreach my $anchor ( @{$anchors} ) {
        if ( $anchor->href !~ $regPlayers ) {
            next;
        }
        push( @anchorPlayers, [ $1, $2, $anchor ] );
    }
    my $total   = scalar(@anchorPlayers);
    my $index   = 0;
    my $players = {
        pro  => {},
        lady => {},
    };
    foreach my $refAnchor (@anchorPlayers) {
        ++$index;
        print "${index}/${total}\r";
        my $anchor     = $refAnchor->[2];
        my $age        = $anchor->parent()->right()->right();
        my $birthPlace = $age->right()->right();
        my $note       = $birthPlace->right()->right();
        $players->{ $refAnchor->[0] }{ $refAnchor->[1] }
            = { %{ getPlayer( $urlTop . $anchor->href ) }, Note => $note->as_trimmed_text(), };
        sleep(1);
    }
    return $players;
}

sub getPlayer {
    my $url = shift or return;
    my $res = $ua->request( HTTP::Request->new( GET => $url ) );
    if ( !$res->is_success ) {
        die( "Failed: " . $res->status_line . "\n" );
    }
    my $tree = new HTML::DOM( url => $url );
    $tree->write( $res->decoded_content );
    $tree->close();
    my $block  = $tree->getElementsByClassName('innerBlock01')->[0];
    my %record = ();
    $record{'NameJp'} = $block->getElementsByClassName('jp')->[0]->as_trimmed_text();
    $record{'NameEn'} = $block->getElementsByClassName('en')->[0]->as_trimmed_text();
    $record{'Title'} = $block->getElementsByClassName('headingElementsA01')->[0]->as_trimmed_text();
    my $rows = $block->getElementsByTagName('tr');

    foreach my $row ( @{$rows} ) {
        my $head = $row->getElementsByTagName('th')->[0];
        my $data = $row->getElementsByTagName('td')->[0];
        $record{ $head->as_trimmed_text() } = $data->as_trimmed_text();
    }
    return \%record;
}
