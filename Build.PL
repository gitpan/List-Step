use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'List::Step',
    license             => 'perl',
    dist_author         => q{Eric Strom <ejstrom@gmail.com>},
    dist_version_from   => 'lib/List/Step.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'List-Step-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
