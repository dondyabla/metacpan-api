package MetaCPAN::Script::Runner;

use strict;
use warnings;

use Config::JFDI ();
use Hash::Merge::Simple qw(merge);
use IO::Interactive qw(is_interactive);
use Module::Pluggable search_path => ['MetaCPAN::Script'];
use Module::Runtime qw(require_module);

sub run {
    my ( $class, @actions ) = @ARGV;
    my %plugins
        = map { ( my $key = $_ ) =~ s/^MetaCPAN::Script:://; lc($key) => $_ }
        plugins;
    die "Usage: metacpan [command] [args]" unless ($class);
    require_module( $plugins{$class} );

    my $config = build_config();
    my $module = $plugins{$class};

    my %args = map { $_ => $config->{$_} }
        grep { $module->can($_) } keys %{$config};

    my $obj = $module->new_with_options(%args);
    $obj->run;
}

sub build_config {
    my $config = Config::JFDI->new(
        name => 'metacpan',
        path => 'etc'
    )->get;
    if ( $ENV{HARNESS_ACTIVE} ) {
        my $tconf = Config::JFDI->new(
            name => 'metacpan',
            file => 'etc/metacpan_testing.pl'
        )->get;
        $config = merge $config, $tconf;
    }
    elsif ( is_interactive() ) {
        my $iconf = Config::JFDI->new(
            name => 'metacpan',
            file => 'etc/metacpan_interactive.pl'
        )->get;
        $config = merge $config, $iconf;
    }
    return $config;
}

# AnyEvent::Run calls the main method
*main = \&run;

1;
