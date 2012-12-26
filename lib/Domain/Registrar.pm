package Domain::Robot::Registrar;
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
use LWP::UserAgent;

# extends ...
# has ...
has 'parent' => (
    'is'    => 'ro',
    'isa'   => 'Domain::Robot',
    'required' => 1,
);

has 'priority' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'lazy'  => 1,
    'builder' => '_init_priority',
);

has '_ua' => (
    'is'      => 'rw',
    'isa'     => 'LWP::UserAgent',
    'lazy'    => 1,
    'builder' => '_init_ua',
);

has 'username' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 1,
);

has 'base_url' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'lazy'  => 1,
    'builder' => '_init_base_url',
);

has 'password' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 1,
);

has 'name' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => 'Unnamed Robot',
);

has 'description' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => 'Unnamed Robot',
);
# with ...
with qw(Log::Tree::RequiredLogger);
# initializers ...
sub _init_priority { return 0; }

sub _init_ua {
    my $self = shift;

    my $UA = LWP::UserAgent::->new();
    $UA->agent('Domain::Robot/1.0');

    return $UA;
}

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
