# define: nginx::resource::location
#
# This definition creates a new location entry within a virtual host
#
# Parameters:
#   [*ensure*]               - Enables or disables the specified location (present|absent)
#   [*vhost*]                - Defines the default vHost for this location entry to include with
#   [*vhost_order*]          - See order option in nginx::resource::vhost defaults to 100.
#   [*location*]             - Specifies the URI associated with this location entry
#   [*run_host*]             - List of hosts to realize this location on if created as a virtual/exported resource.
#   [*www_root*]             - Specifies the location on disk for files to be read from. Cannot be set in conjunction with $proxy
#   [*index_files*]          - Default index files for NGINX to read when traversing a directory
#   [*proxy*]                - Proxy server(s) for a location to connect to. Accepts a single value, can be used in conjunction
#                              with nginx::resource::upstream
#   [*proxy_read_timeout*]   - Override the default the proxy read timeout value of 90 seconds
#   [*ssl*]                  - Indicates whether to setup SSL bindings for this location.
#   [*ssl_only*]	     - Required if the SSL and normal vHost have the same port.
#   [*location_alias*]       - Path to be used as basis for serving requests for this location
#   [*stub_status*]          - If true it will point configure module stub_status to provide nginx stats on location
#   [*location_cfg_prepend*] - It expects a hash with custom directives to put before anything else inside location
#   [*location_cfg_append*]  - It expects a hash with custom directives to put after everything else inside location   
#   [*try_files*]            - An array of file locations to try
#   [*option*]               - Reserved for future use
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  nginx::resource::location { 'test2.local-bob':
#    ensure   => present,
#    www_root => '/var/www/bob',
#    location => '/bob',
#    vhost    => 'test2.local',
#  }
#  
#  Custom config example to limit location on localhost,
#  create a hash with any extra custom config you want.
#  $my_config = {
#    'access_log' => 'off',
#    'allow'      => '127.0.0.1',
#    'deny'       => 'all'
#  }
#  nginx::resource::location { 'test2.local-bob':
#    ensure              => present,
#    www_root            => '/var/www/bob',
#    location            => '/bob',
#    vhost               => 'test2.local',
#    location_cfg_append => $my_config,
#  }

define nginx::resource::location(
  $ensure               = present,
  $vhost                = undef,
  $vhost_order          = '100',
  $run_host             = [$::fqdn],
  $www_root             = undef,
  $index_files          = ['index.html', 'index.htm', 'index.php'],
  $proxy                = undef,
  $proxy_read_timeout   = undef,
  $ssl                  = false,
  $ssl_only		= false,
  $location_alias       = undef,
  $option               = undef,
  $stub_status          = undef,
  $location_cfg_prepend = undef,
  $location_cfg_append  = undef,
  $try_files            = undef,
  $location
) {
  require nginx::params
  require concat::setup

  # Tagging stuff
  if $ensure != absent { tag($::nginx::params::tag_prefix) }
  tag_array(regsubst($run_host,'^',"${::nginx::params::tag_prefix}::"))

  $target = "${::nginx::params::nx_conf_dir}/conf.d/vhost_${vhost_order}_${vhost}.conf"

  Concat::Fragment {
    ensure => $ensure,
    target => $target,
  }

  # Use proxy template if $proxy is defined, otherwise use directory template.
  if ($proxy != undef) {
    $content_real = template('nginx/vhost/vhost_location_proxy.erb')
  } elsif ($location_alias != undef) {
    $content_real = template('nginx/vhost/vhost_location_alias.erb')
  } elsif ($stub_status != undef) {
    $content_real = template('nginx/vhost/vhost_location_stub_status.erb')
  } else {
    $content_real = template('nginx/vhost/vhost_location_directory.erb')
  }

  ## Check for various error condtiions
  if ($vhost == undef) {
    fail('Cannot create a location reference without attaching to a virtual host')
  }
  if (($www_root == undef) and ($proxy == undef) and ($location_alias == undef) and ($stub_status == undef) and ($try_files == undef )) {
    fail('Cannot create a location reference without a www_root, proxy, location_alias, stub_status, or try_files defined')
  }
  if (($www_root != undef) and ($proxy != undef)) {
    fail('Cannot define both directory and proxy in a virtual host')
  }

  ## Create stubs for vHost File Fragment Pattern
  if ($ssl_only != 'true') {
    concat::fragment { "${target}-${name}":
      content => $content_real,
      order => '500',
    }
  }

  ## Only create SSL Specific locations if $ssl is true.
  if ($ssl == 'true') {
    concat::fragment { "${target}-${name}-ssl":
      content => $content_real,
      order => '800',
    }
  }
}
