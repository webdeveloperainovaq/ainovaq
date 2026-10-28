#!/usr/bin/perl
# Ed25519 signatures (RFC 8032) in plain Perl, using only core modules (Math::BigInt, Digest::SHA).
# macOS's LibreSSL cannot sign with Ed25519, and this is what the MCP Registry's domain login needs.
#
#   perl ed25519-sign.pl --selftest                 check against the RFC 8032 test vectors
#   perl ed25519-sign.pl <seed-hex-file> <message>  print the hex signature of <message>
#   perl ed25519-sign.pl --pub <seed-hex-file>      print the base64 public key
use strict;
use warnings;
use Math::BigInt try => 'GMP';
use Digest::SHA qw(sha512);
use MIME::Base64 qw(encode_base64);

my $P = Math::BigInt->new(2)->bpow(255)->bsub(19);
my $L = Math::BigInt->new(2)->bpow(252)->badd('27742317777372353535851937790883648493');
my $D = Math::BigInt->new(-121665)->bmul( inv( Math::BigInt->new(121666) ) )->bmod($P);
my $BX = Math::BigInt->new('15112221349535400772501151409588531511454012693041857206046113283949847762202');
my $BY = Math::BigInt->new('46316835694926478169428394003475163141307993866256225615783033603165251855960');
my @B = ( $BX, $BY, Math::BigInt->new(1), $BX->copy->bmul($BY)->bmod($P) );

sub inv { my $x = shift; return $x->copy->bmodpow( $P->copy->bsub(2), $P ) }
sub md  { return $_[0]->copy->bmod($P) }

# extended coordinates (X, Y, Z, T), RFC 8032 section 5.1.4
sub add {
	my ( $p, $q ) = @_;
	my $A = md( ( $p->[1] - $p->[0] ) * ( $q->[1] - $q->[0] ) );
	my $Bv = md( ( $p->[1] + $p->[0] ) * ( $q->[1] + $q->[0] ) );
	my $C = md( $p->[3] * 2 * $D * $q->[3] );
	my $Dv = md( $p->[2] * 2 * $q->[2] );
	my ( $E, $F, $G, $H ) = ( $Bv - $A, $Dv - $C, $Dv + $C, $Bv + $A );
	return [ md( $E * $F ), md( $G * $H ), md( $F * $G ), md( $E * $H ) ];
}
sub mul {
	my ( $s, $pt ) = @_;
	my $q = [ Math::BigInt->new(0), Math::BigInt->new(1), Math::BigInt->new(1), Math::BigInt->new(0) ];
	my $bits = $s->as_bin; $bits =~ s/^0b//;
	for my $bit ( split //, $bits ) {
		$q = add( $q, $q );
		$q = add( $q, $pt ) if $bit;
	}
	return $q;
}
sub le2int { return Math::BigInt->from_hex( unpack( 'H*', scalar reverse $_[0] ) ) }
sub int2le {
	my ( $n, $len ) = @_;
	my $h = $n->as_hex; $h =~ s/^0x//; $h = ( '0' x ( $len * 2 - length $h ) ) . $h;
	return scalar reverse pack( 'H*', $h );
}
sub encode {
	my $pt = shift;
	my $zi = inv( $pt->[2] );
	my $x = md( $pt->[0] * $zi );
	my $y = md( $pt->[1] * $zi );
	my $out = int2le( $y, 32 );
	if ( $x->is_odd ) { substr( $out, 31, 1 ) = chr( ord( substr( $out, 31, 1 ) ) | 0x80 ) }
	return $out;
}
sub keys_from_seed {
	my $seed = shift;
	my $h = sha512($seed);
	my @a = unpack 'C32', substr( $h, 0, 32 );
	$a[0] &= 248; $a[31] &= 127; $a[31] |= 64;
	my $a = le2int( pack 'C32', @a );
	return ( $a, substr( $h, 32 ), encode( mul( $a, \@B ) ) );
}
sub sign {
	my ( $seed, $msg ) = @_;
	my ( $a, $prefix, $A ) = keys_from_seed($seed);
	my $r = le2int( sha512( $prefix . $msg ) )->bmod($L);
	my $R = encode( mul( $r, \@B ) );
	my $k = le2int( sha512( $R . $A . $msg ) )->bmod($L);
	my $S = $r->copy->badd( $k->bmul($a) )->bmod($L);
	return $R . int2le( $S, 32 );
}
sub read_seed {
	open my $f, '<', $_[0] or die "cannot read $_[0]\n";
	my $hex = do { local $/; <$f> }; $hex =~ s/\s+//g;
	die "seed must be 64 hex characters\n" unless $hex =~ /^[0-9a-f]{64}$/i;
	return pack 'H*', $hex;
}

if ( ( $ARGV[0] // '' ) eq '--selftest' ) {
	my @v = (
		[ '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60', '', 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a', 'e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b' ],
		[ '4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb', '72', '3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c', '92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00' ],
	);
	my $ok = 1;
	for my $t (@v) {
		my $seed = pack 'H*', $t->[0];
		my ( undef, undef, $A ) = keys_from_seed($seed);
		my $sig = sign( $seed, pack 'H*', $t->[1] );
		my $pass = unpack( 'H*', $A ) eq $t->[2] && unpack( 'H*', $sig ) eq $t->[3];
		print( ( $pass ? 'PASS' : 'FAIL' ), " RFC 8032 vector, message length ", length( $t->[1] ) / 2, "\n" );
		$ok &&= $pass;
	}
	exit( $ok ? 0 : 1 );
}
if ( ( $ARGV[0] // '' ) eq '--pub' ) {
	my ( undef, undef, $A ) = keys_from_seed( read_seed( $ARGV[1] ) );
	print encode_base64( $A, '' ), "\n";
	exit 0;
}
die "usage: perl ed25519-sign.pl <seed-hex-file> <message>\n" unless @ARGV == 2;
print unpack( 'H*', sign( read_seed( $ARGV[0] ), $ARGV[1] ) ), "\n";
