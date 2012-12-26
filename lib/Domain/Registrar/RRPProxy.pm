package Domain::Robot::Registrar::RRPProxy;
# ABSTRACT: client for the RRPProxy API

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

our $VERSION = '@VERSION@';

use XMLRPC::Lite;
use Try::Tiny;
use POSIX;    # for mktime

extends 'Domain::Robot::Registrar';

has 'base_url' => (
    'is'       => 'ro',
    'isa'      => 'Str',
    'required' => 1,
);

has 'client' => (
    'is'      => 'ro',
    'isa'     => 'XMLRPC::Lite',
    'lazy'    => 1,
    'builder' => '_init_client',
);

sub _init_client {
    my $self = shift;

    my $Client = XMLRPC::Lite->proxy( $self->base_url() );
    try {
        $Client->transport()->ssl_opts( verify_hostname => 0, );
    };

    return $Client;
}

# call('Api.xcall', (s_login => login, s_pw => pass, command => cmd, domain => ...));
sub _api_call {
    my $self     = shift;
    my $opts_ref = shift;
    my $key_col  = shift || undef;

    $opts_ref->{'s_login'} = $self->username();
    $opts_ref->{'s_pw'}    = $self->password();

    my $resp = $self->client()->call( 'Api.xcall', $opts_ref )->result();
    my $result_ref = {};

    # if key_col is specified the processing mode is changed
    # then not everything is copied but only the information from
    # the respective row ... this is dirty but the way this api works :(
    if ( $key_col && $resp->{'PROPERTY'}->{$key_col} ) {
        foreach my $i ( 0 .. $#{ $resp->{'PROPERTY'}->{$key_col} } ) {
            my $key = $resp->{'PROPERTY'}->{$key_col}->[$i];
            foreach my $prop ( keys %{ $resp->{'PROPERTY'} } ) {
                if ( scalar( @{ $resp->{'PROPERTY'}->{$prop} } ) == 1 ) {
                    $result_ref->{$key}->{ 'rrpproxy::' . $prop } = $resp->{'PROPERTY'}->{$prop}->[0];
                }
                else {
                    $result_ref->{$key}->{ 'rrpproxy::' . $prop } = $resp->{'PROPERTY'}->{$prop}->[$i];
                }
            }
        }
    }
    else {
        foreach my $prop ( keys %{ $resp->{'PROPERTY'} } ) {
            if ( scalar( @{ $resp->{'PROPERTY'}->{$prop} } ) == 1 ) {
                $result_ref->{ 'rrpproxy::' . $prop } = $resp->{'PROPERTY'}->{$prop}->[0];
            }
            elsif ( scalar( @{ $resp->{'PROPERTY'}->{$prop} } ) > 1 ) {
                $result_ref->{ 'rrpproxy::' . $prop } = $resp->{'PROPERTY'}->{$prop};
            }
        }
    }

    return $result_ref;
}

# Action 1.1 AddDomain
sub domain_create {
    my $self   = shift;
    my $domain = shift;
    my $opts   = shift;

    my $cmd_ref = {};
    $cmd_ref->{'command'}         = 'AddDomain';
    $cmd_ref->{'domain'}          = $domain;
    $cmd_ref->{'ownercontact0'}   = $opts->{'ownerc'};
    $cmd_ref->{'admincontact0'}   = $opts->{'adminc'};
    $cmd_ref->{'techcontact0'}    = $opts->{'techc'};
    $cmd_ref->{'billingcontact0'} = $opts->{'billingc'};

    my $result = $self->_api_call($cmd_ref);
    print Dumper($result);

    # TODO implement
    return;
}

# Action 1.2 CheckDomain
sub domain_check {
    my $self   = shift;
    my $domain = shift;

    my $cmd_ref = {};
    $cmd_ref->{'command'} = 'CheckDomain';
    $cmd_ref->{'domain'}  = $domain;
    my $result_ref = $self->_api_call($cmd_ref);
    print Dumper($result_ref);

    # TODO implement
    return;
}

# Action 1.3 CheckDomains
# Action 1.4 StatusDomain
sub domain_info {
    my $self   = shift;
    my $domain = shift;

    my $result_ref = $self->_api_call( { 'command' => 'StatusDomain', 'domain' => $domain, } );
    return $result_ref;
}

# Action 1.5 ModifyDomain
# Action 1.6 DeleteDomain
# Action 1.7 RenewDomain
# Action 1.8 PushDomain
# Action 1.9 TradeDomain
# Action 1.10 GetZone
# Action 1.11 QueryDomainList
sub domain_list {
    my $self = shift;

    # TODO parse known fields into default namespace, e.g. inwx::crDate -> create_ts (unix ts)

    my $result_ref = $self->_api_call( { 'command' => 'QueryDomainList', 'wide' => 1, }, 'DOMAIN', );
    my %dates = (
        'DOMAIN_RENEWAL_DATE'                 => 'renewal_ts',
        'DOMAIN_UPDATED_DATE'                 => 'update_ts',
        'DOMAIN_CREATED_DATE'                 => 'create_ts',
        'DOMAIN_REGISTRATION_EXPIRATION_DATE' => 'expiration_ts',
    );
    foreach my $domain ( keys %{$result_ref} ) {
        foreach my $skey ( keys %dates ) {
            my $dkey = $dates{$skey};
            $result_ref->{$dkey} = $self->_parse_datetime( $result_ref->{ 'rrpproxy::' . $skey } );
        }

        # TODO get additional domain information via StatusDomain?
    }

    return $result_ref;
}

sub _parse_datetime {
    my $self        = shift;
    my $date_string = shift;

    # YYYY-MM-DD HH:mm:ss
    if ( $date_string && $date_string =~ m/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/ ) {
        my ( $year, $month, $dom, $hour, $minute, $second ) = ( $1, $2, $3, $4, $5, $6 );
        my $ts = POSIX::mktime( $second, $minute, $hour, $dom, $month - 1, $year - 1900 );
        return $ts;
    }
    else {
        return 0;
    }
}

# Action 1.12 QueryDomainListByContact
# Action 1.13 GetZoneInfo
# Action 2.1 AddDomainApplication
# Action 2.2 CheckDomainApplication
# Action 2.3 StatusDomainApplication
# Action 2.4 DeleteDomainApplication
# Action 2.5 QueryDomainApplicationList
# Action 3.1 TransferDomain
# Action 3.2 CheckDomainTransfer
# Action 3.3 StatusDomainTransfer
# Action 3.4 SetAuthcode
# Action 3.5 ActivateTransfer
# Action 3.6 QueryTransferList
# Action 4.1 AddNameserver
# Action 4.2 CheckNameserver
# Action 4.3 StatusNameserver
# Action 4.4 ModifyNameserver
# Action 4.5 DeleteNameserver
# Action 4.6 QueryNameserverList
# Action 5.1 AddContact
sub contact_create {
    my $self = shift;
    my $opts = shift || {};

    my $cmd_ref = {};
    $cmd_ref->{'command'} = 'AddContact';
    foreach my $key (qw(title firstname lastname organization street zip city country phone fax email)) {
        if ( !$opts->{$key} ) {
            warn "Missing option to contact_create: $key!\n";
        }
        $cmd_ref->{$key} = $opts->{$key};
    }

    my $resp = $self->_api_call($cmd_ref);
    return $resp->{'rrpproxy::CONTACT'};
}

# Action 5.2 StatusContact
# Action 5.3 ModifyContact
# Action 5.4 DeleteContact
# Action 5.5 CheckContact
# Action 5.6 CheckContacts
# Action 5.7 CloneContact
# Action 5.8 QueryContactList
sub contact_list {
    my $self = shift;

    my $cmd_ref = {};
    $cmd_ref->{'command'} = 'QueryContactList';
    $cmd_ref->{'wide'}    = 1;

    my $result_ref = $self->_api_call( $cmd_ref, 'CONTACT', );
    return $result_ref;
}

# Action 6.1 QueryObjectLogList
# Action 6.2 StatusObjectLog
# Action 7.1 QueryEventList
# Action 7.2 StatusEvent
# Action 7.3 DeletEvent
# Action 8.1 StatusRegistrar
# Action 8.2 ModifyRegistrar
# Action 8.3 StatusAccount
# Action 8.4 GetAppendix
# Action 8.5 ActiveAppendix
# Action 8.6 QueryAppendixList
# Action 8.7 QueryRegistrarStatisticList
# Action 9.1 ConvertCurrency
# Action 9.2 ChargeCreditcard
# Action 9.3 QueryExchangeRates
sub accounting_exchangerates {
    my $self = shift;

    return $self->_api_call( { 'command' => 'QueryExchangeRates', } );
}

# Action 9.4 QueryAccountingList
sub accounting_log {
    my $self = shift;

    return $self->_api_call( { 'command' => 'QueryAccountingList', } );
}

# Action 9.5 QueryZoneList
sub domain_getprices {
    my $self = shift;

    my $domains = $self->_api_call( { 'command' => 'QueryZoneList', } );

    my $result_ref = {};
    foreach my $i ( 1 .. $#{ $domains->{'PROPERTY'}->{'ZONE'} } ) {
        my $key = $domains->{'PROPERTY'}->{'ZONE'}->[$i];
        foreach my $prop (qw(3RDS RESTORE SETUP APPLICATION CURRENCY TRADE DOMAIN_COUNT ANNUAL TRANSFER ACTIVE PERIODTYPE)) {
            $result_ref->{$key}->{ 'rrpproxy::' . $prop } = $domains->{'PROPERTY'}->{$prop}->[$i];
        }
    }

    # parse known fields into default namespace, e.g. inwx::crDate -> create_ts (unix ts)
    my %mapping = (
        'TRADE'       => 'price_trade',
        'RESTORE'     => 'price_restore',
        'APPLICATION' => 'price_application',
        'TRANSFER'    => 'price_transfer',
        'ANNUAL'      => 'price_renew',
    );
    my @periods = qw(create renew transfer trade);
    foreach my $domain ( keys %{$result_ref} ) {
        if ( $result_ref->{$domain}->{'rrpproxy::PERIODTYPE'} ne 'YEAR' ) {
            delete $result_ref->{$domain};
            next;
        }
        $result_ref->{$domain}->{'price_create'} =
          sprintf( "%.2f", $result_ref->{$domain}->{'rrpproxy::SETUP'} + $result_ref->{$domain}->{'rrpproxy::ANNUAL'} );
        foreach my $skey ( keys %mapping ) {
            my $dkey = $mapping{$skey};
            $result_ref->{$domain}->{$dkey} = sprintf( "%.2f", $result_ref->{$domain}->{ 'rrpproxy::' . $skey } );
        }
        foreach my $period (@periods) {
            $result_ref->{$domain}->{ 'period_' . $period } = 1;
        }
        $result_ref->{$domain}->{'currency'} = $result_ref->{$domain}->{'rrpproxy::CURRENCY'};
    }

    return $result_ref;
}

# Action 9.6 QueryServiceList
# Action 9.7 DomainPrice
# Action 9.8 ServicePrice

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Domain::Robot::RRPProxy;
    use Data::Dumper;
    
    my $r = Domain::Robot::RRPProxy::->new({
      'logger' => $l,  
      'username' => 'username',
      'password' => 'password',
      'base_url' => 'https://api-ote.rrpproxy.net:8083/xmlrpc/',
    });
    print Dumper($r->domain_list());
    
=cut
