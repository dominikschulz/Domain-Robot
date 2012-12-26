package Domain::Robot;
# ABSTRACT: baseclass for any registrar plugin

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
# has ...
# with ...
with qw(Config::Yak::NamedPlugins);
# initializers ...
sub _plugin_base_class { return 'Domain::Robot::Registrar'; }

# your code here ...

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Domain::Robot::Registrar;
    my $Mod = Domain::Robot::Registrar::->new();

=head1 DESCRIPTION

Some description.

=cut
