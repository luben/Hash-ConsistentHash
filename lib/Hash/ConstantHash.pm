package Hash::ConstantHash;

use v5.10;
use strict;
use warnings;
use String::CRC32;

=head1 NAME

Hash::ConstantHash - Constant hash algorithm

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Hash::ConstantHash;

    my $chash = Hash::ConstantHash->new(
        buckets => [qw(10.0.0.1 10.0.0.2 10.0.0.3 10.0.0.4)]
    );
    my $next  = $chash->lookup($key);
    my $server= $next->(); # get bucket
    # do stuff with $server
    $server   = $next->(); # get another bucket
    ...

=head1 DESCRIPTION

Hash::ConstantHash algorithm distributes keys over fixed number of buckets. 
Constant hash distribution means that if we add a bucket to a hash with N 
buckets filled with M keys we have to reassign only M/(N+1) keys to new 
buckets.

=head1 METHODS

=head2 new

Creates ConstantHash object. It accept following params:

=over

=item buckets

Arrayref or Hashref. If buckets are given as arrayref they will have
same weight. If given as hashref, every bucket could have differend
weight. 

Examples:

    # All buckets have same weight so they will hold equal amount of keys
    my $chash = Hash::ConstantHash->new( buckets => [qw(A B C)] );

    # Bucket "B" will hold twice the amount of keys of bucket A or C
    my $chash = Cash::ConstantHash->new( buckets => {A=>1, B=>2, C=>1} );


=item factor

Randomization factor for the sequence. Default 10.

=back

=cut

sub new {
    my $self   = shift;
    my $class  = ref($self)||$self;
    $self   = bless {bukets=>0}, $class;

    my %params = @_;
    my $max    = $params{factor} // 10;
    my (@dest,$weight);
    if (ref $params{buckets} eq 'ARRAY'){
        @dest  = @{$params{buckets}};
        $weight= { map {$_ => 1 } @dest };
    }elsif(ref $params{buckets} eq 'HASH'){
        @dest  = keys %{$params{buckets}};
        $weight= $params{buckets};
    }
    return unless @dest;
    $self->{buckets} = scalar(@dest);
    $self->{ring} = {
        map{
            srand(crc32(my $dest = $_));
            my %result;
            $result{int(rand(0xFFFFFFFF))}=$dest
                for ( 1..$max * $weight->{$dest} );
            %result
        } @dest };
    $self->{sorted} = [ sort {$a <=> $b } keys ( %{$self->{ring}} ) ];
    return $self;
}


=head2 lookup

Lookup a key in the hash. Accept one param - the key. Returns an iterator 
over the hash buckets.

Example: 
    my $chash = Hash::ConstantHash->new( buckets => [qw(A B C)] );

    my $next   = $chash->lookup('foo');
    my $bucket = $next->(); # B
    $bucket    = $next->(); # A 
    $bucket    = $next->(); # C, hash is exhausted 
    $bucket    = $next->(); # A 
    ...

Returned buckets will not repeat until all buckets are exhausted.

=cut

sub lookup {
    my ($self,$key) = @_;
    my $idx = crc32($key);
    my $ring= $self->{ring};
    my %seen;
    my $returned = 0;
    return sub {
        my $first;
        # start from the beggining if we have already returned all buckets
        if ($returned >= $self->{buckets}){
            $returned = 0;
            %seen = ();
        }
        while (1){
            for my $n ( @{ $self->{sorted} }){
                $first //= $n;
                if(($n > $idx) and (not $seen{$ring->{$n}})){
                    $seen{$ring->{$n}} = 1;
                    $returned ++;
                    return $ring->{$idx = $n};
                }
            }
            $idx = $first;
            if (not $seen{$ring->{$idx}}){
                $seen{$ring->{$idx}} = 1;
                $returned ++;
                return $ring->{$idx};
            }
        }
    }
}

=head1 AUTHOR

Luben Karavelov, C<< <karavelov at spnet.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-constanthash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-ConstantHash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::ConstantHash


You can also look for information at:

=over 4

=item * GIT repository with the latest stuff

L<https://github.com/luben/Hash-ConstantHash>
L<git://github.com/luben/Hash-ConstantHash.git>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-ConstantHash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-ConstantHash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-ConstantHash>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-ConstantHash/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Luben Karavelov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Hash::ConstantHash
