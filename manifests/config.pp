# Class: nginx::config
#
# This module manages NGINX bootstrap and configuration
#
# Parameters:
#
# There are no default parameters for this class.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class nginx::config inherits nginx::params {
  require concat::setup

  File {
    owner => 'root',
    group => $::nginx::params::nx_root_group,
    mode  => '0644',
  }

  Concat {
    owner => 'root',
    group => $::nginx::params::nx_root_group,
    mode  => '0644',
    notify => Service['nginx'],
  }

  Concat::Fragment {
    ensure => present,
  }

  file { "${::nginx::params::nx_conf_dir}":
    ensure => directory,
  }

  file { "${::nginx::params::nx_conf_dir}/conf.d":
    ensure => directory,
  }
  if $::nginx::params::nx_confd_purge == true {
    File["${::nginx::params::nx_conf_dir}/conf.d"] {
      ignore => "vhost_autogen.conf",
      purge => true,
      recurse => true,
    }
  }

  file { "${::nginx::params::nx_run_dir}":
    ensure => directory,
  }

  file { "${::nginx::params::nx_client_body_temp_path}":
    ensure => directory,
    owner  => $::nginx::params::nx_daemon_user,
    group  => $::nginx::params::nx_daemon_group,
  }

  file {"${::nginx::params::nx_proxy_temp_path}":
    ensure => directory,
    owner  => $::nginx::params::nx_daemon_user,
    group  => $::nginx::params::nx_daemon_group,
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure => absent,
  }

  $toplevel_configs = [
    "${::nginx::params::nx_conf_dir}/nginx.conf",
    "${::nginx::params::nx_conf_dir}/conf.d/proxy.conf",
    "${::nginx::params::nx_conf_dir}/conf.d/upstream.conf",
  ]

  concat { $toplevel_configs:; }

  concat::fragment {
    "${::nginx::params::nx_conf_dir}/nginx.conf-from_config":
      target => "${::nginx::params::nx_conf_dir}/nginx.conf",
      content => template('nginx/conf.d/nginx.conf.erb'),
      order => '001',
    ;
    "${::nginx::params::nx_conf_dir}/conf.d/proxy.conf-from_config":
      target => "${::nginx::params::nx_conf_dir}/conf.d/proxy.conf",
      content => template('nginx/conf.d/proxy.conf.erb'),
      order => '001',
    ;
    "${::nginx::params::nx_conf_dir}/conf.d/upstream.conf-from_config":
      target => "${::nginx::params::nx_conf_dir}/conf.d/upstream.conf",
      content => "# upstream.conf\n",
      order => '001',
    ;
  }

  ## Realize all locally defined nginx resources
  Nginx::Resource::Upstream <| tag == $tag_prefix |>
  Nginx::Resource::Vhost <| tag == $tag_prefix |>
  Nginx::Resource::Location <| tag == $tag_prefix |>
  ## Realize all exported nginx resources defined to run on us
  Nginx::Resource::Upstream <<| tag == $tag_prefix and tag == $run_tag |>>
  Nginx::Resource::Vhost <<| tag == $tag_prefix and tag == $run_tag |>>
  Nginx::Resource::Location <<| tag == $tag_prefix and tag == $run_tag |>>
}
