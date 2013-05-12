# define: nginx::resource::upstream
#
# This definition creates a new upstream proxy entry for NGINX
#
# Parameters:
#   [*ensure*]      - Enables or disables the specified location (present|absent)
#   [*run_host*]    - List of hosts to realize this upstream backend on if created as a virtual/exported resource.
#   [*members*]     - Array of member URIs for NGINX to connect to. Must follow valid NGINX syntax.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  nginx::resource::upstream { 'proxypass':
#    ensure  => present,
#    members => [
#      'localhost:3000',
#      'localhost:3001',
#      'localhost:3002',
#    ],
#  }
define nginx::resource::upstream (
  $ensure = present,
  $run_host = [$::fqdn],
  $members
) {
  require nginx::params
  require concat::setup

  # Tagging stuff
  if $ensure != absent {
    tag($::nginx::params::tag_prefix)
  }
  tag_array(regsubst($run_host,'^','nginx::run::'))

  $target = "${::nginx::params::nx_conf_dir}/conf.d/upstream.conf"

  concat::fragment { "${target}-${name}-upstream":
    target => $target,
    content => template('nginx/conf.d/upstream.erb'),
    notify => Class['nginx::service'],
    order => '100',
  }
}
