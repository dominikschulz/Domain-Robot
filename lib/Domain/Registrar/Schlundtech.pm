package Domain::Robot::Registrar::Schlundtech;
# ABSTRACT: client for the Schlundtech API
# Note: should work for InternetX, too

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use XML::Simple;
use LWP::UserAgent;

extends 'Domain::Robot::Registrar';

has 'email_contact' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 0,
);

has 'email_robot' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 0,
);

sub _init_base_url {
    return 'https://gateway.schlundtech.de';
}

sub _api_call {
    my $self = shift;
    my $task = shift;
    my $opts = shift || {};

    my $request = {};
    $request->{'auth'}->{'user'}     = $self->username();
    $request->{'auth'}->{'password'} = $self->password();
    $request->{'auth'}->{'context'}  = 10;                  # always 10
    $request->{'language'}           = 'en';                # de or en
    $request->{'task'}               = $task;

    my $xml_str = XMLout($request, RootName => 'request', XMLDecl => 1, NoAttr => 1, );

    my $req = HTTP::Request::->new( POST => $self->base_url(), );
    $req->content_type('text/xml');
    $req->content($xml_str);
    my $res = $self->_ua()->request($req);

    if ( $res->is_success() ) {
        my $result_ref = XMLin( $res->content() );
        return $result_ref;
    }
    else {
        return;
    }
}

# 1.x - no methods
# 2.1 Domain Create - 0101
sub domain_create {
    my $self   = shift;
    my $domain = shift;
    my $ownerc = shift;
    my $nserver1 = shift;
    my $nserver2 = shift;
    my $ip = shift;

    my $task = {};
    $task->{'code'} = '0101';
    $task->{'domain'}->{'confirm_order'} = 1;
    $task->{'domain'}->{'name'} = $domain;
    $task->{'domain'}->{'ownerc'} = $ownerc;
    push(@{$task->{'domain'}->{'nserver'}},{
        'name'  => $nserver1,
    });
    push(@{$task->{'domain'}->{'nserver'}},{
        'name'  => $nserver2,
    });
    $task->{'domain'}->{'zone'}->{'ip'} = $ip;
    $task->{'domain'}->{'zone'}->{'ns_action'} = 'complete';
    
    use Data::Dumper;
    print Dumper($task);
    
    #my $resp = $self->_api_call($task);
    my $resp;
    return $resp;
}

# 2.2 Domain Create Plus - no code/no method, see 2.1
# 2.3 Domain Update - 0102
sub domain_update {
    my $self   = shift;
    my $domain = shift;

    my $task = {};
    $task->{'code'} = '0102';
    $task->{'domain'}->{'name'} = $domain;

    # TODO set options to be updated
    my $resp = $self->_api_call($task);
    
    return $resp;
}

# 2.4 Domain Update Plus - no code/no method, see 2.3
# 2.5 Domain Ownerchange - 0104010
sub domain_trade {
    my $self   = shift;
    my $domain = shift;

    my $task = {};
    $task->{'code'} = '0104010';
    $task->{'domain'}->{'name'} = $domain;

    # TODO disabled
    return;
}

# 2.6 Domain Delete - 0103
sub domain_delete {
    my $self   = shift;
    my $domain = shift;

    my $task = {};
    $task->{'code'} = '0103';
    $task->{'domain'}->{'name'} = $domain;

    # TODO disabled ...
    return;
}

# 2.7 Domain Inquire - 0105
sub domain_info {
    my $self   = shift;
    my $domain = shift;

    my $task = {};
    $task->{'code'}             = '0105';
    $task->{'domain'}->{'name'} = $domain;
    $task->{'key'}              = 'payable';

    my $resp = $self->_api_call($task);
    
    return $resp;
}

sub domain_list {
    my $self = shift;
    my $opts = shift || {};

    my $task = {};
    $task->{'code'}               = '0105';
    $task->{'view'}->{'offset'}   = 0;
    $task->{'view'}->{'limit'}    = 10_000;
    $task->{'view'}->{'children'} = 1;
    $task->{'view'}->{'show_handle_details'} = 'ownerc,adminc,techc,zonec';

    my $resp = $self->_api_call($task);
    
    if($resp->{'result'}->{'status'}->{'type'} eq 'success') {
        return $resp->{'result'}->{'data'}->{'domain'};
    } else {
        return;
    }
}

# 2.8 Domain Status - 0102002
sub domain_status {
    my $self   = shift;
    my $domain = shift;
    my $status = shift; # lock,hold,hold-lock,active

    my $task = {};
    $task->{'code'} = '0102002';
    $task->{'domain'}->{'name'} = $domain;
    $task->{'domain'}->{'registry_status'} = $status;

    my $resp = $self->_api_call($task);

    return $resp;
}

# 3.1 - no method
# 3.2 Cancelation Create - 0103101
sub cancelation_create {
    my $self   = shift;
    my $domain = shift;
    my $type   = shift;

    my $task = {};
    $task->{'code'}                    = '0103101';
    $task->{'cancelation'}->{'domain'} = $domain;
    $task->{'cancelation'}->{'type'}   = $type;

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 3.3 Cancelation Update - 0103102
sub cancelation_update {
    my $self   = shift;
    my $domain = shift;
    my $type   = shift;

    my $task = {};
    $task->{'code'}                    = '0103102';
    $task->{'cancelation'}->{'domain'} = $domain;
    $task->{'cancelation'}->{'type'}   = $type;

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 3.4 Cancelation Delete - 0103103
sub cancelation_delete {
    my $self   = shift;
    my $domain = shift;

    my $task = {};
    $task->{'code'} = '0103103';
    $task->{'cancelation'}->{'domain'} = $domain;

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 3.5 Cancelation Inquire (single) - 0103104
sub cancelation_list {
    my $self = shift;

    my $task = {};
    $task->{'code'} = '0103104';

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 3.6 Cancelation Inquire (multi) - see 3.5
# TODO append this information to domain_list?
# 4.1 Domain Transfer In - 0104
sub domain_transfer {
    my $self   = shift;
    my $domain = shift;

    my $task = {};
    $task->{'code'} = '0104';
    $task->{'domain'}->{'name'} = $domain;

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 4.2 Domain Status - 0102002
# see 2.8
# 4.3 AuthInfo1 Create - 0113001
sub domain_authinfo1create {
    my $self   = shift;
    my $domain = shift;

    my $task = {};
    $task->{'code'} = '0113001';
    $task->{'domain'}->{'name'} = $domain;

    my $resp = $self->_api_call($task);
    return $resp;
}
# 4.4 AuthInfo1 Delete - 0113002
sub domain_authinfo1delete {
    my $self   = shift;
    my $domain = shift;

    my $task = {};
    $task->{'code'} = '0113002';
    $task->{'domain'}->{'name'} = $domain;

    my $resp = $self->_api_call($task);
    return $resp;
}
# 5.1 - no method
# 5.2 Zone Create - 0201
sub nameserver_create {
    my $self = shift;
    my $name = shift;
    my $ip = shift;

    my $task = {};
    $task->{'code'} = '0201';
    $task->{'zone'}->{'name'} = $name;
    $task->{'zone'}->{'ns_action'} = 'complete';
    $task->{'zone'}->{'main'}->{'value'} = $ip;

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 5.3 Zone Update - 0202
sub nameserver_update {
    my $self = shift;

    my $task = {};
    $task->{'code'} = '0202';

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 5.4 Zone Delete - 0203
sub nameserver_delete {
    my $self = shift;

    my $task = {};
    $task->{'code'} = '0203';

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 5.5 Zone Import - 0204
sub nameserver_import {
    my $self = shift;

    my $task = {};
    $task->{'code'} = '0204';

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}
# 5.6 Zone Inquire - 0205
sub nameserver_list {
    my $self = shift;
    my $extended = shift || 0;

    my $task = {};
    $task->{'code'} = '0205';
    $task->{'view'}->{'offset'} = 0;
    $task->{'view'}->{'limit'} = 1000;
    $task->{'view'}->{'children'} = 1;

    my $resp = $self->_api_call($task);
    
    if($extended) {
        foreach my $zone (keys %{$resp->{'result'}->{'data'}->{'zone'}}) {
            my $zone_data = $self->nameserverset_list($zone);
            $resp->{'result'}->{'data'}->{'zone'}->{$zone}->{'zone'} = $zone_data->{'result'}->{'data'}->{'zone'};
        }
    }
    
    if($resp->{'result'}->{'status'}->{'type'} eq 'success') {
        return $resp->{'result'}->{'data'};
    } else {
        # TODO log error
        return;
    }
}

# Action 10.5 - 0205
sub nameserverset_list {
    my $self = shift;
    my $zone = shift;
    
    my $task = {};
    $task->{'code'} = '0205';
    $task->{'zone'}->{'name'} = $zone;
    
    my $resp = $self->_api_call($task);
    return $resp;
}

# 6.1 - no method
# 6.2 Handle Create - 0301
sub contact_create {
    my $self = shift;

    my $task = {};
    $task->{'code'} = '0301';

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 6.3 Handle Update - 0302
sub contact_update {
    my $self = shift;

    my $task = {};
    $task->{'code'} = '0302';

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 6.4 Handle Delete - 0303
sub contact_delete {
    my $self = shift;

    my $task = {};
    $task->{'code'} = '0303';

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 6.5 Handle Inquire - 0304
sub contact_list {
    my $self = shift;

    my $task = {};
    $task->{'code'} = '0304';

    # TODO add opts

    my $resp = $self->_api_call($task);
    return $resp;
}

# 6.6 - no method

# api provides no way of retreiving the pricelist
# you need to manage the pricelist for this provider yourself
sub domain_getprices {
    my $self = shift;

    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
