class puppetclient (
    $upstreamrepository = false,
    $server = undef,
    $startmode = undef,
    $cronminutes = [fqdn_rand(29),fqdn_rand(29)+30],   # Run every 30 minutes
    $splay = undef,
) {
  class { 'puppetclient::install':
    upstreamrepository => $upstreamrepository
  }

  class { 'puppetclient::config':
    server      => $server,
    startmode   => $startmode,
    cronminutes => $cronminutes,
    splay       => $splay,
  }
}
