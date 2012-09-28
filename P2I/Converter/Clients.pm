use Modern::Perl;
use MooseX::Declare;

class P2I::Converter::Clients extends P2I::Converter {
    use P2I::ISPconfigSOAP;

    use constant DEFAULT_WEB_PHP_OPTIONS  => 'mod,fast-cgi,suphp'; # no,cgi
    use constant DEFAULT_SSH_CHROOT       => 'no'; # jailkit
    use constant DEFAULT_LIMIT_CRON_TYPE  => 'url';

    {
        use Digest::MD5 'md5_hex';
        # TODO pester the  ISPconfig guys to fix this. MD5 hashing is insecure!
        sub password_to_md5 {
            defined(my $pw = shift) or return;  # only try to convert defined passwords
            return md5_hex($pw);
        }
    }

    method convert {
        my %parentmap;

        for my $id ($self->db->list_parents) {
            my %data;
            $self->_map_fields( $self->db->read_client($id), \%data, $self->_field_map );
            next if 'admin' eq $data{username};
            say "SOAP: client_add parent $data{username} ($data{contact_name}):";
            #say "\t$_ => ",($data{$_}//'<undef>') for sort keys %data;
            my $newid = $self->lather('client_add', 1, \%data);
            say "soap done  [newID:$newid]";
            $parentmap{$data{id}} = $newid;
        }

        for my $id ($self->db->list_dependents) {
            my %data;
            my $record = $self->db->read_client($id);
            $self->_map_fields( $record, \%data, $self->_field_map );
            $data{parent_client_id} = $parentmap{$record->id};
            say "SOAP: client_add dependent $data{username} ($data{contact_name})";
            #say "\t$_ => ",($data{$_}//'<undef>') for sort keys %data;
            $self->lather('client_add', 1, \%data);
        }
    }
    
    method _field_map {
        return {
            company_name            => 'cname',
            contact_name            => 'pname',
            customer_no             => undef,
            vat_id                  => undef,
            street                  => 'address',
            zip                     => 'pcode',
            city                    => 'city',
            state                   => 'state',
            country                 => 'country',
            telephone               => 'phone',
            mobile                  => undef,
            fax                     => 'fax',
            email                   => 'email',
            internet                => undef,
            icq                     => undef,
            notes                   => undef,
            default_mailserver      => 1,
            limit_maildomain        => -1,
            limit_mailbox           => -1,
            limit_mailalias         => -1,
            limit_mailaliasdomain   => -1,
            limit_mailforward       => -1,
            limit_mailcatchall      => -1,
            limit_mailrouting       => 0,
            limit_mailfilter        => -1,
            limit_fetchmail         => -1,
            limit_mailquota         => -1,
            limit_spamfilter_wblist => 0,
            limit_spamfilter_user   => 0,
            limit_spamfilter_policy => 1,
            default_webserver       => 1,
            limit_web_ip            => undef,
            limit_web_domain        => -1,
            limit_web_quota         => -1,
            web_php_options         => \(DEFAULT_WEB_PHP_OPTIONS),
            limit_web_subdomain     => -1,
            limit_web_aliasdomain   => -1,
            limit_ftp_user          => -1,
            limit_shell_user        => 0,
            ssh_chroot              => \(DEFAULT_SSH_CHROOT),
            limit_webdav_user       => 0,
            default_dnsserver       => 1,
            limit_dns_zone          => -1,
            limit_dns_slave_zone    => -1,
            limit_dns_record        => -1,
            default_dbserver        => 1,
            limit_database          => -1,
            limit_cron              => 0,
            limit_cron_type         => \(DEFAULT_LIMIT_CRON_TYPE),
            limit_cron_frequency    => 5,
            limit_traffic_quota     => -1,
            limit_client            => 0,
            parent_client_id        => undef,
            username                => 'login',
            password                => \&password_to_md5,
            language                => 'locale',
            usertheme               => undef,
            template_master         => 0,
            template_additional     => undef,
            created_at              => 0,
        };
    }
}
