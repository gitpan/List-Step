#!/usr/bin/perl
use strict;
use warnings;

use Test::Simple tests => 25;
use blib;
use List::Step ':all';

print "List::Step version $List::Step::VERSION\n";

ok  join('' => mapn {$_ % 2 ? "[@_]" : "@_"} 3 => 1 .. 10) eq '[1 2 3]4 5 6[7 8 9]10'
=>  'mapn';


ok  join(' ' => apply {s/a/b/g} 'abcba', 'aok') eq 'bbcbb bok'
=>  'apply';


ok  join(' ' => zip ['a'..'c'], [1 .. 3]) eq "a 1 b 2 c 3"
=>  'zip';


my @a = 1 .. 10;
my $twos = by 2 => @a;

ok  ref tied @$twos eq 'List::Step::SteppedArray'
=>  'by/every: scalar constructor';

ok  @$twos == 5
=>  'by/every: scalar length';

ok  ! defined eval {$$twos[5]} &&
    $@ =~ /index 5 out of bounds \[0 .. 4\]/
=>  'by/every: scalar bounds';

ok  "@{$$twos[0]}" eq "1 2" &&
    "@{$$twos[1]}" eq "3 4" &&
    "@{$$twos[2]}" eq "5 6" &&
    "@{$$twos[3]}" eq "7 8" &&
    "@{$$twos[4]}" eq "9 10"
=>  'by/every: scalar slices';

$$_[0] *= -1 for @$twos;

ok  "@a" eq "-1 2 -3 4 -5 6 -7 8 -9 10"
=>  'by/every: scalar element aliasing';

@a = 1 .. 9;
my @threes = by 3 => @a;

ok  @threes == 3
=>  'by/every: array length';

ok  "@{$threes[0]}" eq "1 2 3" &&
    "@{$threes[1]}" eq "4 5 6" &&
    "@{$threes[2]}" eq "7 8 9"
=>  'by/every: array slices';

$$_[0] *= -1 for @threes;

ok  "@a" eq "-1 2 3 -4 5 6 -7 8 9"
=>  'by/every: array element aliasing';


ok  "@{range 0, 10}" eq "@{[0 .. 10]}"
=>  'range: simple';

ok  "@{range 11, 10}" eq "@{[11 .. 10]}"
=>  'range: empty';

ok  "@{range 0, 0}" eq "@{[0 .. 0]}"
=>  'range: short';

ok  "@{range -10, 10}" eq "@{[-10 .. 10]}"
=>  'range: negative to positive';

ok  "@{range 0, 5, 0.5}" eq "@{[map $_/2 => 0 .. 10]}"
=>  'range: fractional step';

ok  "@{range 10, -5, -1}" eq "@{[reverse -5 .. 10]}"
=>  'range: negative step';

ok  $#{range 0, 10, 1/3} == 30
=>  'range: length';

ok  ! defined eval {range(0, 5, 0.5)->[11]} &&
    $@ =~ /range index 11 out of bounds \[0 .. 10\]/
=>  'range: bounds';


my $gen = gen {$_**2} 0, 10;

ok  $$gen[5] == 25
=>  'gen: direct';

$gen = gen {$_**3} range 0, 10;

ok  $$gen[3] == 27
=>  'gen: range';

my $ta = range 0, 2**128, 0.5;


ok  $ta->get(2**128) == 2**127
=>  'get > 2**31-1';

ok  $ta->size == 2**129
=>  'size > 2**31-1';


ok  join(' ' => map d, 1, [2, 3], 4, {5, 6}, 7, \8, 9 ) eq '1 2 3 4 5 6 7 8 9'
=>  'deref';


ok  join(', ' => slide {"@_"} 2 => 1 .. 5) eq '1 2, 2 3, 3 4, 4 5, 5'
=>  'slide';
