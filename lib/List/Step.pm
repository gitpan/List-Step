package List::Step;
    use warnings;
    use strict;
    use Carp;
    use Exporter 'import';
    use Scalar::Util 'reftype';
    use List::Util
    our @list_util = qw/first max maxstr min minstr reduce shuffle sum/;
    our $VERSION   = '0.10';
    our @EXPORT_OK = (our @list_util, qw/mapn by every range apply d deref zip slide/);
    our @EXPORT    = qw/mapn by every range apply zip min max reduce/;
    our %EXPORT_TAGS = (all => \@EXPORT_OK, base => \@EXPORT);

=head1 NAME

List::Step - provides functions for walking lists with arbitrary step sizes

=head1 VERSION

version 0.10

=head1 SYNOPSIS

this module provides higher order functions, iterators, and other utility functions for
working with lists. it is primarily the home of the variable step list walking function
C<mapn>, and its progeny C<by> and C<every> that give its functionality to perl's own
control structures.  in addition, there are several other hopefully useful functions,
and all functions from List::Util are available.

    use List::Step;

    print "@$_\n" for every 5 => 1 .. 15;
    # 1 2 3 4 5
    # 6 7 8 9 10
    # 11 12 13 14 15

    print mapn {"$_[0]: $_[1]\n"} 2 => %myhash;

    for (range 0.345, -21.5, -0.5) {
        # loops over 0.345, -0.155, -0.655, -1.155 ... -21.155
    }

=head1 EXPORT

    use List::Step; # is the same as
    use List::Step qw/mapn by every range apply zip min max reduce/;

    the following functions are available:
        mapn by every range apply d deref zip slide
        from List::Util => first max maxstr min minstr reduce shuffle sum

=head1 FUNCTIONS

=over 8

=item C<mapn {CODE} NUM LIST>

this function works like the builtin C<map> but takes C<NUM> sized steps
over the list, rather than one element at a time.  inside the C<CODE> block,
the current slice is in C<@_> and C<$_> is set to C<$_[0]>.  slice elements
are aliases to the original list.  if C<mapn> is called in void context,
the C<CODE> block will be executed in void context for efficiency.

    print mapn {$_ % 2 ? "@_" : " [@_] "} 3 => 1..20;
    # 1 2 3 [4 5 6] 7 8 9 [10 11 12] 13 14 15 [16 17 18] 19 20

    print "student grades: \n";
    mapn {
        print shift, ": ", (reduce {$a + $b} @_)/@_, "\n";
    } 5 => qw {
        bob   90 80 65 85
        alice 75 95 70 100
        eve   80 90 80 75
    };

=cut
    sub mapn (&$@) {
        my ($sub, $n, @ret) = splice @_, 0, 2;
        croak '$_[1] must be >= 1' unless $n >= 1;
        my $ret = defined wantarray;
        while (@_) {
            local *_ = \$_[0];
            if ($ret) {push @ret =>
                  $sub->(splice @_, 0, $n)}
            else {$sub->(splice @_, 0, $n)}
        }
        @ret
    }


=item C<apply {CODE} LIST>

apply a function that modifies C<$_> to a copy of C<LIST> and return the copy

    print join ", " => apply {s/$/ one/} "this", "and that";
    > this one, and that one

=cut
    sub apply (&@) {
        my ($sub, @ret) = @_;
        $sub->() for @ret;
        wantarray ? @ret : pop @ret
    }


=item C<zip LIST_of_ARRAYREF>

interleaves the passed in lists to create a new list.
C<zip> continues until the end of the longest list,
C<undef> is returned for missing elements of shorter lists.

    %hash = zip [qw/a b c/], [1..3]; # same as
    %hash = (a => 1, b => 2, c => 3);


=cut
    sub zip {
        map {my $i = $_;
            map $$_[$i] => @_
        } 0 .. max map $#$_ => @_
    }


=item C<by NUM LIST>

=item C<every NUM LIST>

C<by> and C<every> are exactly the same, and allow you to add variable step size
to any other list control structure with whichever reads better to you.

    for (every 2 => @_) {do something with pairs in @$_}

    grep {do something with triples in @$_} by 3 => @list;

the functions generate an array of array references to C<INT> sized slices of C<LIST>.
the elements in each slice are aliases to the original list.

in list context, returns a real array.
in scalar context, returns a reference to a tied array iterator.

    my @slices = every 2 => 1 .. 10;     # real array
    my $slices = every 2 => 1 .. 10;     # tied array iterator
    for (every 2 => 1 .. 10) { ... }     # real array
    for (@{every 2 => 1 .. 10}) { ... }  # tied array iterator

if you plan to use all the slices, the real array is better.
if you only need a few, the tied array won't need to generate all of
the other slices.

    print "@$_\n" for every 3 => 1..9;
    # 1 2 3
    # 4 5 6
    # 7 8 9

    my @a = 1 .. 10;
    for (every 2 => @a) {
        @$_[0, 1] = @$_[1, 0]  # flip each pair
    }
    print "@a";
    # 2 1 4 3 6 5 8 7 10 9

    print "@$_\n" for grep {$$_[0] % 2} by 3 => 1 .. 9;
    # 1 2 3
    # 7 8 9

=cut

{package
    List::Step::SteppedArray;
    use base 'Tie::Array';
    use Carp;
    sub TIEARRAY {
        my ($class, $n, $array) = @_;
        my $size = @$array / $n;
        $size++ if $size > int $size;
        bless [$n, $array, int $size] => $class
    }
    sub FETCHSIZE {$_[0][2]}
    sub FETCH {
        my ($n, $array) = @{ $_[0] };
        my $i = $n * $_[1];
        $i < @$array
            ? sub{\@_}->(@$array[$i .. $i + $n - 1])
            : croak "index $_[1] out of bounds [0 .. @{[int( $#$array / $n )]}]"
    }
}
    sub by ($@) {
        croak '$_[0] must be >= 1' unless $_[0] >= 1;
        wantarray and return mapn {\@_} shift, @_;
        tie my @ret => 'List::Step::SteppedArray', shift, \@_;
        \@ret
    }
    sub every ($@); *every = \&by;


=item C<range START STOP>

=item C<range START STOP STEP>

generates a tied array containing values from C<START> to C<STOP> by C<STEP>, inclusive.

C<STEP> defaults to 1 but can be fractional and negative.
depending on your choice of C<STEP>, the last value returned may
not always be C<STOP>.

    range(0, 3, 0.4) returns (0, 0.4, 0.8, 1.2, 1.6, 2, 2.4, 2.8)

in list context, returns a tied array.
in scalar context, returns a reference to the tied array.
to obtain a real array, simply assign a range to an C<ARRAY> variable.

    print "$_ " for range 0, 1, 0.1;
    # 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1

    print "$_ " for range 5, 0, -1;
    # 5 4 3 2 1 0

    my $nums = range 0, 1_000_000, 2;
    print "@$nums[10, 100, 1000]";
    # gets the tenth, hundredth, and thousandth numbers in the range
    # without calculating any other values

since the returned "array" is just an iterator, even gigantic ranges are
created instantly, and take little space.  however, when used directly in
a for loop, perl seems to preallocate space for the array anyway.
for reasonably sized ranges this is unnoticeable, but for huge ranges,
avoiding the problem is as simple as wrapping the range with C<@{ }>

    for (@{range 2**30, -2**30, -1.3}) {
        # the loop will start immediately without eating all
        # your memory, and hopefully you will exit the loop early
    }

=cut

{package
    List::Step::RangeArray;
    use base 'Tie::Array';
    use Carp;
    sub TIEARRAY {
        my ($class, $low, $high, $step) = (@_, 1);
        my $size = 1 + ($step > 0 ? $high - $low : $low - $high) / abs $step;
        bless [$low, $step, $size > 0 ? int $size : 0] => $class
    }
    sub FETCHSIZE {$_[0][2]}
    sub FETCH {
        my ($low, $step, $size) = @{ $_[0] };
        $_[1] < $size
            ? $low + $step * $_[1]
            : croak "range index $_[1] out of bounds [0 .. @{[$size - 1]}]"
    }
}
    sub range {
        tie my @ret => 'List::Step::RangeArray', @_;
        wantarray ? @ret : \@ret
    }


=item C<d>

=item C<d SCALAR>

=item C<deref>

=item C<deref SCALAR>

dereference a C<SCALAR>, C<ARRAY>, or C<HASH> reference.  any other value is returned unchanged

    print join " " => map deref, 1, [2, 3, 4], \5, {6 => 7}, 8, 9, 10;
    # prints 1 2 3 4 5 6 7 8 9 10

=cut
    sub d (;$) {
        my ($x)  = (@_, $_);
        return $x unless my $type = reftype $x;
        $type eq 'ARRAY'  ? @$x :
        $type eq 'HASH'   ? %$x :
        $type eq 'SCALAR' ? $$x : $x
    }
    sub deref (;$); *deref = \&d;


=item C<slide {CODE} WINDOW LIST>

slides a C<WINDOW> sized slice over C<LIST>,
calling C<CODE> for each slice and collecting the result

as the window reaches the end, the passed in slice will shrink

    print slide {"@_\n"} 2 => 1 .. 4
    # 1 2
    # 2 3
    # 3 4
    # 4         # only one element here

=cut
    sub slide (&$@) {
        my ($code, $n, @ret) = splice @_, 0, 2;

        push @ret, $code->( @_[ $_ .. $_ + $n ] )
            for 0 .. $#_ - --$n;

        push @ret, $code->( @_[ $_ .. $#_ ])
                for $#_ - $n + 1 .. $#_;
        @ret
    }

=back

=head1 AUTHOR

Eric Strom, C<< <ejstrom at gmail.com> >>

=head1 BUGS

please report any bugs or feature requests to C<bug-list-functional at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=List-Functional>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

copyright 2009 Eric Strom.

this program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut

1; # End of List::Step
