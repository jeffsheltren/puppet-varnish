# == Class varnish::config
#
# This class is called from varnish
#
class varnish::config {

  case $::osfamily {
    'RedHat', 'Amazon': {
      case $::varnish::varnish_version {
        '3.0': {
          $sysconfig_template = "varnish/el${::operatingsystemmajrelease}/varnish-3.sysconfig.erb"
        }
        default: {
          $sysconfig_template = "varnish/el${::operatingsystemmajrelease}/varnish-4.sysconfig.erb"
        }
      }
    }

    'Debian': {
      case $::varnish::varnish_version {
        '3.0': {
          $sysconfig_template = 'varnish/debian/varnish-3.default.erb'
        }
        '4.0': {
          $sysconfig_template = 'varnish/debian/varnish-4.default.erb'
        }
        default: {
          fail("Varnish version ${::varnish::varnish_version} not supported on ${::operatingsystem} (${::lsbdistdescription}, ${::lsbdistcodename})")
        }
      }
    }

    default: {
      fail("Varnish version ${::varnish::varnish_version} not supported on ${::operatingsystem} (${::lsbdistdescription}, ${::lsbdistcodename})")
    }
  }

  file { $varnish::params::sysconfig:
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($sysconfig_template),
  }

  # For EL7, copy out updated systemd file which includes $VARNISH_EXTRA_LISTEN option to listen on multiple interfaces.
  if ($::osfamily == "RedHat") && ($::operatingsystemmajrelease == 7) {
    file { '/etc/systemd/system/varnish.service':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("varnish/el${::operatingsystemmajrelease}/varnish-4-systemd.erb"),
      notify  => Exec['varnish-systemd-daemon-reload'],
    }

    exec { 'varnish-systemd-daemon-reload':
      command     => '/bin/systemctl daemon-reload',
      refreshonly => true,
      notify      => Service[$varnish::params::service_name],
    }
  }

}
