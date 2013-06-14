class puppetclient::config (
    $server,
    $startmode,
    $cronminutes,
    $splay = undef,
    $data = {},
    $configfile = '/etc/puppet/puppet.conf',
) {
  $default = {
    'main' => {
      'logdir' => '/var/log/puppet',
      'vardir' => '/var/lib/puppet',
      'ssldir' => '/var/lib/puppet/ssl',
      'rundir' => '/var/run/puppet',
      'factpath' => '$vardir/lib/facter',
      'templatedir' => '$confdir/templates',
      'usecacheonfailure' => 'false',
    },
    'agent' => {
      'pluginsync' => 'true',
      'report' => 'true',
      'server' => $server,
    },
    'master' => {
      'ssl_client_header' => 'SSL_CLIENT_S_DN',
      'ssl_client_verify_header' => 'SSL_CLIENT_VERIFY',
      'modulepath' => '$confdir/environments/$environment/modules',
      'manifest' => '$confdir/environments/$environment/manifests/site.pp',
      'certname' => $server,
      'reports' => 'tagmail,log,store',
    }
  }

  # Live would be so easy if there was a deep_merge function
  # $config = deep_merge($default, $data)
  # Instead we have to check each section for the right type and merge them seperately
  # https://projects.puppetlabs.com/issues/20200

  if ! has_key($data, 'main') {
    $data[main] = {}
  }

  if ! has_key($data, 'master') {
    $data[master] = {}
  }

  if ! has_key($data, 'agent') {
    $data[agent] = {}
  }

  $config = {
    'main' => merge($default[main], $data[main]),
    'master' => merge($default[master], $data[master]),
    'agent' => merge($default[agent], $data[agent]),
  }

  file { $configfile:
    content => template('puppetclient/puppet.conf.erb')
  }

  file { '/usr/bin/waitrandom':
    source => 'puppet:///modules/puppetclient/waitrandom',
    mode   => '0755',
  }

  if $startmode {
    # We can NOT set ensure => stopped at the moment, because that
    # also immediately kills the onetime agent started from cron
    $service_ensure = $startmode ? {
      'auto'   => 'running',
      'cron'   => undef,
      'manual' => undef,
      default  => undef,
    }

    $service_enable = $startmode ? {
      'auto'   => true,
      'cron'   => false,
      'manual' => false,
      default  => undef,
    }

    if $::osfamily == 'Debian' {
      augeas { 'puppetclient::defaults_puppet':
        changes => $service_enable ? {
          true  => [ 'set /files/etc/default/puppet/START yes' ],
          false => [ 'set /files/etc/default/puppet/START no' ],
          undef => [],
        },
      }
    }

    service { 'puppet':
      ensure    => $service_ensure,
      enable    => $service_enable,
      hasstatus => true,
    }

    file { '/etc/cron.d/puppetclient':
      ensure  => $startmode ? {
        'cron'  => present,
        default => absent,
      },
      content => template('puppetclient/puppetclient.cron.erb')
    }
  }
}

