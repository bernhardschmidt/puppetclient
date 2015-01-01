class puppetclient::install ($upstreamrepository = false) {
  if str2bool($upstreamrepository) {
    if $::osfamily == 'Debian' {
      apt::source { 'puppet':
        location   => 'http://apt.puppetlabs.com/',
        release    => $::lsbdistcodename,
        repos      => 'main dependencies',
        key        => '4BD6EC30',
        key_server => 'hkp://p80.pool.sks-keyservers.net:80'
      }

      # Install libaugeas-ruby which usually depends on the Ruby 1.9 version
      # used by the upstream puppet
      package {'libaugeas-ruby': }

      Apt::Source['puppet'] -> Package['puppet']
    } else {
      warning ("puppetclient::upstreamrepository is not implemented for ${::operatingsystem}")
    }
  }

  package { 'puppet': }
}

