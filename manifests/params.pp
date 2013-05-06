# Class: nginx::params
#
# This module manages NGINX paramaters
#
# Parameters:
#
# These are the default parameters for the nginx class.
#
# Override with hiera.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class nginx::params(
  $nx_temp_dir = '/etc/nginx',
  $nx_run_dir  = '/var/nginx',

  $nx_conf_dir           = '/etc/nginx',
  $nx_confd_purge        = true,
  $nx_worker_processes   = 1,
  $nx_worker_connections = 512,
  $nx_multi_accept       = off,
  $nx_sendfile           = on,
  $nx_keepalive_timeout  = 65,
  $nx_tcp_nodelay        = on,
  $nx_tcp_nopush         = on,
  $nx_gzip               = off,

  $nx_proxy_redirect          = off,
  $nx_proxy_set_header        = [
    'Host $host', 'X-Real-IP $remote_addr',
    'X-Forwarded-For $proxy_add_x_forwarded_for',
    'X-Forwarded-Proto $scheme',
  ],

  $nx_client_body_temp_path   = "${nx_run_dir}/client_body_temp",
  $nx_client_body_buffer_size = '512k',
  $nx_client_max_body_size    = '10m',
  $nx_proxy_temp_path         = "${nx_run_dir}/proxy_temp",
  $nx_proxy_connect_timeout   = '5',
  $nx_proxy_send_timeout      = '300',
  $nx_proxy_read_timeout      = '300',
  $nx_proxy_buffers           = '32 4k',
  $nx_ssl_engine              = undef,
  $nx_ssl_protocols           = [
    'TLSv1.1',
    'TLSv1',
  ],
  $nx_ssl_ciphers             = [
    'ECDHE-RSA-AES256-SHA384',
    'AES256-SHA256',
    'HIGH',
    '!MEDIUM',
    '!LOW',
    '!3DES',
    '!RC5',
    '!RC4',
    '!MD5',
    '!aNULL',
    '!EDH',
  ],
  $nx_logdir = $::kernel ? {
    /(?i-mx:linux|freebsd)/ => '/var/log/nginx',
  },

  $nx_pid = $::kernel ? {
    /(?i-mx:linux|freebsd)/  => '/var/run/nginx.pid',
  },

  $nx_daemon_user = $::operatingsystem ? {
    /(?i-mx:debian|ubuntu)/                                      => 'www-data',
    /(?i-mx:fedora|rhel|redhat|centos|scientific|suse|opensuse)/ => 'nginx',
    /(?i-mx:freebsd)/ => 'www',
  },

  $nx_root_group = $::kernel ? {
    /(?i-mx:linux)/           => 'root',
    /(?i-mx:freebsd|openbsd)/ => 'wheel',
  },

  $nx_daemon_group = $::operatingsystem ? {
    /(?i-mx:debian|ubunt)/ => 'www-data',
    /(?i-mx:fedora|rhel|redhat|centos|scientific|suse|opensuse)/ => 'nginx',
    /(?i-mx:freebsd)/ => 'www',
  },

  # Service restart after Nginx 0.7.53 could also be just "/path/to/nginx/bin -s HUP"
  # Some init scripts do a configtest, some don't. If configtest_enable it's true
  # then service restart will take $nx_service_restart value, forcing configtest.
  $nx_configtest_enable	 = false,
  $nx_service_restart = "/etc/init.d/nginx configtest && /etc/init.d/nginx restart"
) {
}
