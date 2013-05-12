# define: nginx::resource::vhost
#
# This definition creates a virtual host
#
# Parameters:
#   [*vhost*]               - Treat this as namevar - Makes it possible to declare this define through hiera with generated vhost
#                             name for locations.
#   [*ensure*]              - Enables or disables the specified vhost (present|absent)
#   [*listen_ip*]           - Default IP Address for NGINX to listen with this vHost on. Defaults to all interfaces (*)
#   [*listen_port*]         - Default IP Port for NGINX to listen with this vHost on. Defaults to TCP 80
#   [*listen_options*]      - Extra options for listen directive like 'default' to catchall. Undef by default.
#   [*ipv6_enable*]         - BOOL value to enable/disable IPv6 support (false|true). Module will check to see if IPv6
#                             support exists on your system before enabling.
#   [*ipv6_listen_ip*]      - Default IPv6 Address for NGINX to listen with this vHost on. Defaults to all interfaces (::)
#   [*ipv6_listen_port*]    - Default IPv6 Port for NGINX to listen with this vHost on. Defaults to TCP 80
#   [*ipv6_listen_options*] - Extra options for listen directive like 'default' to catchall. Template will allways add ipv6only=on.
#                             While issue jfryman/puppet-nginx#30 is discussed, default value is 'default'.
#   [*index_files*]         - Default index files for NGINX to read when traversing a directory
#   [*proxy*]               - Proxy server(s) for the root location to connect to.  Accepts a single value, can be used in
#                             conjunction with nginx::resource::upstream
#   [*proxy_read_timeout*]  - Override the default the proxy read timeout value of 90 seconds
#   [*ssl*]                 - Indicates whether to setup SSL bindings for this vhost.
#   [*ssl_cert*]            - Pre-generated SSL Certificate file to reference for SSL Support. This is not generated by this module.
#   [*ssl_key*]             - Pre-generated SSL Key file to reference for SSL Support. This is not generated by this module.
#   [*ssl_port*]            - Default IP Port for NGINX to listen with this SSL vHost on. Defaults to TCP 443
#   [*ssl_protocols*]       - Array of ssl_protocols for this vhost. Default is to use the value from nginx::params.
#   [*ssl_cihers*]          - String ssl_ciphers for this vhost. Default is to use the value from nginx::params.
#   [*server_name*]         - List of vhostnames for which this vhost will respond. Default [$vhost].
#   [*run_host*]          - List of hosts to realize this vhost on if created as a virtual/exported resource.
#   [*www_root*]            - Specifies the location on disk for files to be read from. Cannot be set in conjunction with $proxy
#   [*rewrite_www_to_non_www*]  - Adds a server directive and rewrite rule to rewrite www.domain.com to domain.com in order to avoid
#                             duplicate content (SEO);
#   [*location_cfg_prepend*] - The location_cfg_prepend value for the default (/) location.
#   [*location_cfg_append*]  - The location_cfg_append value for the default (/) location.
#   [*cfg_http*]             - Freeform config lines added before the vhost entries in the http section that includes conf.d/*.conf.
#   [*cfg_vhost*]            - Freeform config lines added inside the vhost entry, if both ssl and non added in both.
#   [*try_files*]           - Specifies the locations for files to be checked as an array. Cannot be used in conjuction with $proxy.
#   [*order*]               - Prepended to vhost name in file name to manipulate vhost load order. Defaults to 100.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  nginx::resource::vhost { 'test2.local':
#    ensure   => present,
#    www_root => '/var/www/nginx-default',
#    ssl      => 'true',
#    ssl_cert => '/tmp/server.crt',
#    ssl_key  => '/tmp/server.pem',
#  }
define nginx::resource::vhost(
  $vhost                  = $name,
  $ensure                 = present,
  $listen_ip              = '*',
  $listen_port            = '80',
  $listen_options         = undef,
  $ipv6_enable            = false,
  $ipv6_listen_ip         = '::',
  $ipv6_listen_port       = '80',
  $ipv6_listen_options    = 'default',
  $ssl                    = false,
  $ssl_cert               = undef,
  $ssl_key                = undef,
  $ssl_port               = '443',
  $ssl_protocols_list     = undef,
  $ssl_ciphers_list       = undef,
  $proxy                  = undef,
  $proxy_read_timeout     = undef,
  $index_files            = ['index.html', 'index.htm'],
  $server_name            = [$vhost],
  $run_host               = [$::fqdn],
  $www_root               = undef,
  $rewrite_www_to_non_www = false,
  $location_cfg_prepend   = undef,
  $location_cfg_append    = undef,
  $cfg_http               = undef,
  $cfg_vhost              = undef,
  $try_files              = undef,
  $order                  = '100'
) {
  require nginx::params
  require concat::setup

  # Tagging stuff
  if $ensure != absent {
    tag($::nginx::params::tag_prefix)
    tag_array(regsubst($run_host,'^',"${::nginx::params::tag_prefix}::"))
  }

  $target = "${::nginx::params::nx_conf_dir}/conf.d/vhost_${order}_${vhost}.conf"

  # Add IPv6 Logic Check - Nginx service will not start if ipv6 is enabled
  # and support does not exist for it in the kernel.
  if ($ipv6_enable == 'true') and ($ipaddress6)  {
    warning('nginx: IPv6 support is not enabled or configured properly')
  }

  # Check to see if SSL Certificates are properly defined.
  if ($ssl == 'true') {
    if ($ssl_cert == undef) or ($ssl_key == undef) {
      fail('nginx: SSL certificate/key (ssl_cert/ssl_cert) and/or SSL Private must be defined and exist on the target system(s)')
    }
  }

  if ($ssl == 'true') and ($ssl_port == $listen_port) {
    $ssl_only = 'true'
  }

  concat { $target:
    owner => $::nginx::params::nx_daemon_user,
    group => $::nginx::params::nx_daemon_group,
    mode => '0644',
    notify  => Class['nginx::service'],
  }

  Concat::Fragment {
    ensure => $ensure,
    target => $target,
  }

  concat::fragment { "${target}-pre_header":
    content => template('nginx/vhost/_cfg_http.erb'),
    order => '001',
  }

  # Create the base configuration file reference.
  unless ($ssl_only) {
    concat::fragment { "${target}-header":
      content => template('nginx/vhost/vhost_header.erb'),
      order => '010',
    }
  }
  
  # Create the default location reference for the vHost
  nginx::resource::location {"${vhost}-default":
    vhost              => $vhost,
    run_host           => $run_host,
    ssl                => $ssl,
    ssl_only           => $ssl_only,
    location           => '/',
    proxy              => $proxy,
    proxy_read_timeout => $proxy_read_timeout,
    try_files          => $try_files,
    notify             => Class['nginx::service'],
    index_files        => $index_files,
  }

  # Support location_cfg_prepend and location_cfg_append on default location created by vhost
  if $location_cfg_prepend {
    Nginx::Resource::Location["${vhost}-default"] {
      location_cfg_prepend => $location_cfg_prepend
    }
  }
  if $location_cfg_append {
    Nginx::Resource::Location["${vhost}-default"] {
      location_cfg_append => $location_cfg_append
    }
  }
  # Create a proper file close stub.
  unless ($ssl_only) {
    concat::fragment { "${target}-footer":
      content => template('nginx/vhost/vhost_footer.erb'),
      order => '699',
    }
  }

  $ssl_protocols = $ssl_protocols_list ? {
    undef => $::nginx::params::nx_ssl_protocols,
    default => $ssl_protocols,
  }
  validate_array($ssl_protocols)

  $ssl_ciphers = flatten([
      $ssl_protocols,
      $ssl_ciphers_list ? {
        undef => $::nginx::params::nx_ssl_ciphers,
        default => $ssl_ciphers_list
      }
  ])
  validate_array($ssl_ciphers)

  # Create SSL File Stubs if SSL is enabled
  if ($ssl == 'true') {
    concat::fragment { "${target}-ssl-header":
      content => template('nginx/vhost/vhost_ssl_header.erb'),
      order => '700',
    }
    concat::fragment { "${target}-ssl-footer":
      content => template('nginx/vhost/vhost_footer.erb'),
      order => '999',
    }
  }
}
