package Domain::Robot::Registrar::INWX;
# ABSTRACT: client for the INWX API

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use HTTP::Cookies;
use XMLRPC::Lite; # +trace => 'all';

use Data::Dumper;

extends 'Domain::Robot::Registrar';

has 'cookies' => (
    'is'      => 'ro',
    'isa'     => 'HTTP::Cookies',
    'lazy'    => 1,
    'builder' => '_init_cookies',
);

has 'client' => (
    'is'      => 'ro',
    'isa'     => 'XMLRPC::Lite',
    'lazy'    => 1,
    'builder' => '_init_client',
);

has 'data_types' => (
    'is'      => 'ro',
    'isa'     => 'HashRef',
    'lazy'    => 1,
    'builder' => '_init_data_types',
);

sub _init_base_url {
    return 'https://api.domrobot.com/xmlrpc/';
}

sub _init_data_types {
    my %data_types = (
        'action'           => [qw(REQUEST APPROVE DENY CANCEL)],
        'addressTitle'     => [qw(MISS MISTER COMPANY)],
        'answer'           => [qw(ACK NACK)],
        'applicationorder' => [qw(DOMAINASC DOMAINDESC PRICEASC PRICEDESC REGISTRANTASC REGISTRANTDESC)],
        'domainorder'      => [qw(DOMAINASC DOMAINDESC STATUSASC STATUSDESC CRDATEASC CRDATEDESC EXDATEASC EXDATEDESC REDATEASC REDATEDESC TRANSFERLOCKASC TRANSFERLOCKDESC UPDATEASC UPDATEDESC SCDATEASC SCDATEDESC RENEWALMODEASC RENEWALMODEDESC)],
        'contactorder'     => [qw(IDDESC IDASC NAMEDESC NAMEASC)],
        'text64'           => qr/^.{1,64}$/,
        'email'            => qr/^[_a-zA-Z0-9-](\.{0,1}[_a-zA-Z0-9-+])*@([a-zA-Z0-9-]{1,}\.){0,}[a-zA-Z0-9-]{1,}(\.[a-zA-Z]{2,6}){1,2}$/,
        'NSsetType'        => [qw(PRIMARY SECONDARY EXTERNAL)],
        'timestamp'        => qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}(T([0-9]{2}):([0-9]{2})(:([0-9]{2})(\.([0-9]+))?)?(Z|(([-+])([0-9]{2}):([0-9]{2})))?)?$/,
        'skLegalForm'      => [qw(AS FO OTHER SRO Z)],
        'usPurpose'        => [qw(P1 P2 P3 P4 P5)],
        'usCategory'       => [qw(C11 C12 C21 C31 C32)],
        'urlRedirectType'  => [qw(HEADER301 HEADER302 FRAME)],
        'text255'          => qr/^.{3,255}$/,
        'recordtype'       => [qw(A AAAA AFSDB CERT CNAME DNSKEY DS HINFO KEY LOC MX NAPTR NS NSET PTR RP RRSIG SOA SPF SRV SSHFP TXT URL)],
        'ip'               => qr/^(((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?$)|^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?$)/,
        'nsType'           => [qw(MASTER SLAVE)],
        'renewalmode'      => [qw(AUTORENEW AUTODELETE AUTOEXPIRE)],
        'date'             => qr/^(19|20)\d\d[- \.](0[1-9]|1[012])[- \.](0[1-9]|[12][0-9]|3[01])$/,
        'period'           => [qw(1M 1Y 2Y 3Y 4Y 5Y 6Y 7Y 7Y 9Y 10Y)],
        'nslist'           => '',
        'role'             => [qw(ORG PERSON ROLE)],
        'country'     => [qw()],                                                                         # TODO iso3166 country code
        'phone'       => qr/^\+[0-9]{1,3}\.[0-9-]+$/,
        'text10'      => /^.{2,10}$/,
        'region'      => [qw(DEFAULT EUROPE ASIA AFRICA OCEANIA AMERICAS GENERIC ALL)],
        'target'      => qr/^[a-z 0-9\-]{3,}$/,
        'extdata'     => '',
        'caLegalType' => [qw(CCO CCT RES GOV EDU ASS HOP PRT TDM TRD PLT LAM TRS ABO INB LGR OMK MA)],
        'boolean'     => [qw(0 1)],
        'int'         => qr/^[\d]{1,32}$/,
        'base64'      => qr/^.{3,}$/,
        'hostname' =>
qr/^(((([^\*\ \_\!\"\$\%\/\(\)\=\?\'\^\§\#\+\;\:\,\|\\x5D\\x5B\\x7D\\x7B\\xAB\\xBB\\xAF\\x5C\\xA6\\xAA\\xAE\\xBE\\xD7\\xF7\\x08\\x3C\\x3E\\x7E\\x60])+)\.)*([^\*\ \_\!\"\$\%\/\(\)\=\\'\^\§\#\+\;\:\,\|\\x5D\\x5B\\x7D\\x7B\\xAB\\xBB\\xAF\\x5C\\xA6\\xAA\\xAE\\xBE\\xD7\\xF7\\x08\\x3C\\x3E\\x7E\\x60]){1,252})\.[a-zA-Z##0-9-]{2,63}(\.[a-zA-Z]{2,3})?$/,
        'float' => qr/^(\b[0-9]+\.([0-9]+\b)?|[0-9]+\b)$|^$/,
        'ip_url' =>
qr/^(((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?$)|^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?$)|^(http|ftp|https):\/\/[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&:\~\+#]*[\w\-\@?^=%&\~\+#])?$|^$/,
        'vatno'             => qr/(^$)|^([a-zA-Z]){2}[a-zA-Z0-9]{5,12}$/,
        'sex'               => [qw(F M)],
        'language'          => [qw(EN DE)],
        'faxphone'          => qr/^$|^\+[0-9]{1,4}\.[0-9-]+$/,
        'username'          => qr/^[a-zA-Z0-9\@\.\_-]{5,32}?$/,
        'text064'           => qr/^.{0,64}$/,
        'paymentType'       => [qw(PAYPAL BANKTRANSFER)],
        'extdatatrade'      => '',
        'extdatatransfer'   => '',
        'text'              => qr/^.{1,10000}$/s,
        'seidno'            => qr/^[0-9]{6,8}-[0-9]{4}$/,
        'contactdomain'     => '',
        'contact'           => '',
        'extdatadomain'     => '',
        'extdatapplication' => '',
        'transfermode'      => [qw(DEFAULT AUTOAPPROVE AUTODENY)],
    );
    return \%data_types;
}

has 'return_codes' => (
    'is'      => 'ro',
    'isa'     => 'HashRef',
    'lazy'    => 1,
    'builder' => '_init_return_codes',
);

sub _init_return_codes {
    my $self = shift;

    my %ret_codes = (
        '1000' => 'Command completed successfully',
        '1001' => 'Command completed successfully; action pending',
        '1300' => 'Command completed successfully; no messages',
        '1301' => 'Command completed successfully; ack to dequeue',
        '1500' => 'Command completed successfully; ending session',
        '2000' => 'Unknown command',
        '2001' => 'Command syntax error',
        '2002' => 'Command use error',
        '2003' => 'Required parameter missing',
        '2004' => 'Parameter value syntax range error',
        '2005' => 'Parameter value syntax error',
        '2100' => 'Unimplemented protocol version',
        '2101' => 'Unimplemented command',
        '2102' => 'Unimplemented option',
        '2103' => 'Unimplemented extension',
        '2104' => 'Billing failure',
        '2105' => 'Object is not eligible for renewal',
        '2106' => 'Object is not eligible for transfer',
        '2200' => 'Authentication error',
        '2201' => 'Authorization error',
        '2202' => 'Invalid authorization information',
        '2300' => 'Object pending transfer',
        '2301' => 'Object not pending transfer',
        '2302' => 'Object exists',
        '2303' => 'Object does not exist',
        '2304' => 'Object status prohibits operation',
        '2305' => 'Object association prohibits operation',
        '2306' => 'Parameter value policy error',
        '2307' => 'Unimplemented object service',
        '2308' => 'Data management policy violation',
        '2400' => 'Command failed',
        '2500' => 'Command failed; server closing connection',
        '2501' => 'Authentication error; server closing connection',
        '2502' => 'Session limit exceeded; server closing connection',
    );

    return \%ret_codes;
}

sub _validate {
    my $self = shift;
    my $type = shift;
    my $date = shift;

    if ( !$self->data_types()->{$type} ) {

        # don't know how to validate ...
        return;
    }

    if ( ref( $self->data_types()->{$type} ) eq 'ARRAY' ) {
        if ( grep { $date =~ m/^$_$/ } @{ $self->data_types()->{$type} } ) {
            return 1;
        }
        else {
            return;
        }
    }
    elsif ( $date =~ m/$self->data_types()->{$type}/ ) {
        return 1;
    }
    else {
        return;
    }
}

sub _validate_all {
    my $self = shift;
    my $ref  = shift;
    my $data = shift;
    
    #foreach my $key (keys %{$data}) {
    #    if(!$self->_validate())
    #}
    # TODO validate all args
}

sub DEMOLISH {
    my $self = shift;

    if ( $self->{'client'} ) {
        $self->client()->call('account.logout');
    }

    return 1;
}

sub _init_cookies {
    my $self = shift;

    my $Cookies = HTTP::Cookies::->new( ignore_discard => 1, );

    return $Cookies;
}

sub _init_client {
    my $self = shift;

    my $Client = XMLRPC::Lite->proxy( $self->base_url() );
    $Client->transport()->cookie_jar( $self->cookies() );
    if ( $Client->transport()->can('ssl_opts') ) {
        $Client->transport()->ssl_opts( verify_hostname => 0, );
    }

    my $resp = $Client->call(
        'account.login',
        {
            'user' => $self->username(),
            'pass' => $self->password(),
            'lang' => 'en',
        }
    );
    
    #print "Login: ".Dumper($resp->result())."\n";

    return $Client;
}

# Action 1.3 - account.info
sub account_info {
    my $self = shift;

    my $resp = $self->client()->call('account.info');
    # TODO bad documentation, see what is returned and process it
    
    print "Account-Info: ".Dumper($resp->result())."\n";

    return $resp->result();
}

# Action 2.1 - accounting.accountBalance
sub accounting_balance {
    my $self = shift;

    my $resp = $self->client()->call('accounting.accountBalance')->result();

    return $resp;
}

# Action 2.2 - accounting.log - log of transactions
# dateFrom - ts (YYYY-MM-DDThh:mm:ss+TZ:TZ)
# dateTo - ts
sub accounting_log {
    my $self = shift;
    my $opt = shift;

    # TODO handle from and to

    my $resp = $self->client()->call('accounting.log')->result();
    return;
}

# Action 2.3 - accounting.lockedFunds - log of reservation of deposit
# dateFrom - ts
# dateTo - ts
# page - int
# pagelimit - int
sub accounting_lockedfunds {
    my $self = shift;
    my $from = shift;
    my $to   = shift;

    my $resp = $self->client()->call(
        'accounting.lockedFunds',
        {
            'dateFrom'  => $from,
            'dateTo'    => $to,
            'page'      => 1,
            'pagelimit' => 10_000,
        }
    )->result();

    return $resp;
}

# Action 2.4 - accounting.getInvoice - generate pdf of the invoice
# invoiceId - text64 - req!
sub accounting_getinvoice {
    my $self       = shift;
    my $invoice_id = shift;

    if ( !$self->_validate( 'text64', $invoice_id ) ) {
        return;
    }

    my $resp = $self->client()->call( 'accounting.getInvoice', { 'invoiceId' => $invoice_id, } )->result();

    return $resp;
}

# Action 2.5 - accounting.listInvoices - list available invoices
sub accounting_listinvoices {
    my $self = shift;

    my $resp = $self->client()->call('accounting.listInvoices')->result();

    return $resp;
}

# Action 2.6 - accounting.refund - request a refund of your unneede funds
# type - payment type
# amount - float
# ...
sub accounting_refund {
    my $self   = shift;
    my $type   = shift;
    my $amount = shift;

    if ( !$self->_validate( 'paymentType', $type ) ) {
        return;
    }

    if ( !$self->_validate( 'float', $amount ) ) {
        return;
    }

    # TODO add opt. parameters

    my $resp = $self->client()->call(
        'accounting.refund',
        {
            'type'   => $type,
            'amount' => $amount,
        }
    )->result();

    return $resp;
}

# Action 3.1 - application.check - check availability of domains
# domain - fqdn - req!
sub application_check {
    my $self   = shift;
    my $domain = shift;

    if ( !$self->_validate( 'text64', $domain ) ) {
        return;
    }

    my $resp = $self->client()->call( 'application.domain', { 'domain' => $domain, } )->result();

    return $resp;
}

# Action 3.2 - application.create - preregister a domain
# ...
sub application_create {
    my $self       = shift;
    my $domain     = shift;
    my $registrant = shift;
    my $admin      = shift;
    my $tech       = shift;
    my $billing    = shift;
    my $ns         = shift;

    # TODO support optional fields

    return unless $self->_validate( 'text64', $domain );
    return unless $self->_validate( 'int',    $registrant );

    # TODO validate the other fields

    my $resp = $self->client()->call(
        'application.create',
        {
            'domain'     => $domain,
            'registrant' => $registrant,
            'admin'      => $admin,
            'tech'       => $tech,
            'billing'    => $billing,
            'ns'         => $ns,
        }
    )->result();

    return $resp;
}

# Action 3.3 - application.update - update preregister
# ...
sub application_update {
    my $self = shift;
    my $roid = shift;
    my $opt  = shift;

    return unless $self->_validate( 'int', $roid );

    my %args = (
        'price'      => 'float',
        'registrant' => 'int',
        'admin'      => 'int',
        'tech'       => 'int',
        'billing'    => 'int',
        'ns'         => 'nslist',
        'type'       => 'text64',
        'extData'    => 'extdataapplication',
    );

    my $arg_ref = { 'roId' => $roid, };

    foreach my $key ( keys %args ) {
        next unless defined $opt->{$key};
        my $type = $args{$key};
        return unless $self->_validate( $type, $opt->{$key} );
        $arg_ref->{$key} = $opt->{$key};
    }

    my $resp = $self->client()->call( 'application.update', $arg_ref );

    return $resp;
}

# Action 3.4 - application.info - get domain details
# roId - int - req!
# wide - int - opt
sub application_info {
    my $self = shift;
    my $roid = shift;
    my $wide = shift;

    return unless $self->_validate( 'int', $roid );

    my $arg_ref = { 'roId' => $roid, };
    $arg_ref->{'wide'} = $wide if defined($wide);

    my $resp = $self->client()->call( 'application.info', $arg_ref );

    return $resp;
}

# Action 3.5 - application.list - list domain applications
# domain - text
# wide - int
# order - DOMAINASC
# page - int
# pagelimit - int
sub application_list {
    my $self = shift;
    my $opt  = shift;

    my %args = (
        'domain'    => 'array_text64',
        'wide'      => 'int',
        'order'     => 'applicationorder',
        'page'      => 'int',
        'pagelimit' => 'int',
    );
    my $arg_ref = {};

    foreach my $key ( keys %args ) {
        next unless defined $opt->{$key};
        my $type = $args{$key};
        return unless $self->_validate( $type, $opt->{$key} );
        $arg_ref->{$key} = $opt->{$key};
    }

    my $resp = $self->client()->call( 'application.list', $arg_ref );

    return $resp;
}

# Action 3.6 - application.delete - delete a preapplication
# roId - int - req!
sub application_delete {
    my $self = shift;
    my $roid = shift;

    return unless $self->_validate( 'int', $roid );

    my $resp = $self->client()->call( 'application.delete', { 'roId' => $roid, } );

    return $resp;
}

# Action 4.1 - contact.create - create a new contact handle
# Required:
# type - role
# name - text
# street - address
# city - city
# pc - postcal code
# cc - iso3166
# voice - telephone
# email - email
# Optional:
# org - organization
# street2
# street3
# sp - state province
# fax
# remarks
# protection
# sex
# language
# nationalityCc - iso3166
# companyNumber - num
# formationDate - date
# IdCardPassportNumber
# IdCardPassport...
# birthDate - date
# birthPc - postcode birth country
# birthCity - city of birth
# birthCc - country of birth iso3166
sub contact_create {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('contact.create',$params);
    
    return $resp->result();
}

# Action 4.2 - contact.update - update a contact handle
# required:
# id - contact id
# optional:
# name
# org
# street
# street2
# city
# pc
# voice
# fax
# email
# remarks
# protection
# Action 4.3 - contact.info - return contact details
# ...
# Action 4.4 - contact.list - list available contacts
# ...
sub contact_list {
    my $self = shift;

    my $resp = $self->client()->call(
        'contact.list',
        {
            'page'      => 1,
            'pagelimit' => 10_000,
        }
    );

    return $resp->result();
}

# Action 4.5 - contact.log - history of changes to a handle
# id - int
sub contact_log {
    my $self = shift;
    my $id   = shift;

    my $resp = $self->client()->call( 'contact.log', { 'id' => $id, } );

    return $resp->result();
}

# Action 4.6 - contact.delete - delete a contact handle
# id - int - req!
# testing - bool
# Action 5.1 - domain.check - check availability of domains
# domain - array of fqdn
# sld - text (second level domain)
# tld - text (tld)
# region - region
# wide - int
sub domain_check {
    my $self = shift;
    my $opts = shift;

    my $param = shift;

    foreach my $key (qw(domain sld tld region wide)) {

        # TODO validate
        $param->{$key} = $opts->{$param};
    }

    my $resp = $self->client()->call( 'domain.check', $param );

    return $resp->result();
}

# Action 5.2 - domain.create - register a new domain
# ...
sub domain_create {
    my $self = shift;
    my $opts = shift;

    my $param = {};

    foreach my $key (qw(domain registrant admin tech billing ns)) {

        # TODO validate params
        $param->{$key} = $opts->{$key};
    }

    my $resp = $self->client()->call( 'domain.create', $param );

    return $resp->result();
}

# Action 5.3 - domain.update - update domain data
# ...
sub domain_update {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('domain.update',$params);
    
    return $resp->result();
}
# Action 5.4 - domain.transfer - transfer a domain
# ...
sub domain_transfer {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('domain.transfer',$params);
    
    return $resp->result();
}
# Action 5.5 - domain.transferOut - allow or deny outgoing transfers
# domain - text - req!
# answer - answer - req!
# testing - bool
sub domain_transferout {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('domain.transferout',$params);
    
    return $resp->result();
}
# Action 5.6 - domain.trade - registrant change
# ...
sub domain_trade {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('domain.trade',$params);
    
    return $resp->result();
}
# Action 5.7 - domain.renew - extend registration period
sub domain_renew {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('domain.renew',$params);
    
    return $resp->result();
}
# Action 5.8 - domain.push -
sub domain_push {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('domain.push',$params);
    
    return $resp->result();
}
# Action 5.9 - domain.delete
sub domain_delete {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    #my $resp = $self->client()->call('domain.delete',$params);
    
    #return $resp->result();
    return;
}
# Action 5.10 - domain.restore
sub domain_restore {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('domain.restore',$params);
    
    return $resp->result();
}
# Action 5.11 - domain.info - get domain details
sub domain_info {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('',$params);
    
    return $resp->result();
}
# Action 5.12 - domain.list - list registered domains
sub domain_list {
    my $self = shift;

    my $resp = $self->client()->call(
        'domain.list',
        {
            'page'      => 1,
            'pagelimit' => 1000,
        }
    );

    my $domains = {};
    
    print "Domain-List: ".Dumper($resp->result())."\n";
    
    foreach my $domain ( @{ $resp->result()->{'resData'}->{'domain'} } ) {
        my $key = $domain->{'domain'};
        foreach my $prop ( keys %{$domain} ) {
            $domains->{$key}->{ 'inwx::' . $prop } = $domain->{$prop};
        }
    }

    # TODO parse known fields into default namespace, e.g. inwx::crDate -> create_ts (unix ts)

    return $domains;
}

# Action 5.13 - domain.log - list log entries of domain operations
sub domain_log {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('domain.log',$params);
    
    return $resp->result();
}
# Action 5.14 - domain.getPrices - get domain prices
sub domain_getprices {
    my $self = shift;

    my $resp = $self->client()->call('domain.getPrices');

    my $prices = {};

    foreach my $entry ( @{ $resp->result()->{'resData'}->{'price'} } ) {
        my $key = $entry->{'tld'};
        foreach my $prop ( keys %{$entry} ) {
            $prices->{$key}->{ 'inwx::' . $prop } = $entry->{$prop};
        }
    }

    # TODO parse known fields into default namespace, e.g. inwx::crDate -> create_ts (unix ts)

    return $prices;
}

# Action 5.15 - domain.getRules - get domain rules
sub domain_getrules {
    my $self = shift;

    my $resp = $self->client()->call('domain.getRules');

    return $resp->result();
}

# Action 5.16 - domain.whois - get the whois record of any domain
sub domain_whois {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('domain.whois',$params);
    
    return $resp->result();
}
# Action 5.17 - domain.stats
sub domain_stats {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('domain.stats',$params);
    
    return $resp->result();
}
# Action 6.x - not implemented (glue records)
# Action 7.x - not implemented (hosting package)
# Action 8.1 - message.ack - ack that a message was read
sub message_ack {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('message.ack',$params);
    
    return $resp->result();
}
# Action 8.2 - message.poll - get first message
sub message_poll {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('message.poll',$params);
    
    return $resp->result();
}
# Action 9.1 - nameserver.check -
sub nameserver_check {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserver.check',$params);
    
    return $resp->result();
}
# Action 9.2 - nameserver.create -
sub nameserver_create {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserver.create',$params);
    
    return $resp->result();
}
# Action 9.3 - nameserver.createRecord -
sub nameserver_createrecord {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserver.createRecord',$params);
    
    return $resp->result();
}
# Action 9.4 - nameserver.update -
sub nameserver_update {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserver.update',$params);
    
    return $resp->result();
}
# Action 9.5 - nameserver.updateRecord -
sub nameserver_updaterecord {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserver.updateRecord',$params);
    
    return $resp->result();
}
# Action 9.6 - nameserver.delete -
sub nameserver_delete {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserver.delete',$params);
    
    return $resp->result();
}
# Action 9.7 - nameserver.deleteRecord -
sub nameserver_deleterecord {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserver.deleteRecord',$params);
    
    return $resp->result();
}
# Action 9.8 - nameserver.info -
sub nameserver_info {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserver.info',$params);
    
    return $resp->result();
}
# Action 9.9 - nameserver.list -
sub nameserver_list {
    my $self = shift;

    my $resp = $self->client()->call('nameserver.list');

    return $resp->result();
}

# Action 10.1 - nameserverset.create -
sub nameserverset_create {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserverset.create',$params);
    
    return $resp->result();
}
# Action 10.2 - nameserverset.update -
sub nameserverset_update {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserverset.update',$params);
    
    return $resp->result();
}
# Action 10.3 - nameserverset.delete -
sub nameserverset_delete {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserverset.delete',$params);
    
    return $resp->result();
}
# Action 10.4 - nameserverset.info -
sub nameserverset_info {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserverset.info',$params);
    
    return $resp->result();
}
# Action 10.5 - nameserverset.list -
sub nameserverset_list {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('nameserverset.list',$params);
    
    return $resp->result();
}
# Action 11.1 - pdf.get -
sub pdf_get {
    my $self = shift;
    my $opts = shift;
    
    my $params = {};
    
    foreach my $key (qw()) {
        # TODO validate params
        $params->{$key} = $opts->{$key};
    }
    
    my $resp = $self->client()->call('pdf.get',$params);
    
    return $resp->result();
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Domain::Robot::INWX;
    use Data::Dumper;
    
    my $r = Domain::Robot::INWX::->new(
      'username' => 'user',
      'password' => 'pass',
      'base_url' => 'https://api.domrobot.com/xmlrpc/',
    );
    
    print Dumper($r->account_info());
    print Dumper($r->accounting_balance());
    print Dumper($r->domain_list());
        
=cut
