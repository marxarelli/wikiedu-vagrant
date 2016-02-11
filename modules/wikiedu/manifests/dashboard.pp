class wikiedu::dashboard(
    $source,
    $revision,
) {
    $dir = '/vagrant/WikiEduDashboard'

    vcsrepo { $dir:
        ensure   => present,
        provider => git,
        source   => $source,
        revision => $revision,
        user     => 'vagrant',
    }

    bundler::install { $dir:
        require => Vcsrepo[$dir],
    }

    npm::install { $dir:
        require => Vcsrepo[$dir],
    }

    bower::install { $dir:
        require => Vcsrepo[$dir],
    }

    file { "${dir}/config/database.yml":
        source  => 'puppet:///modules/wikiedu/database.yml',
        owner   => 'vagrant',
        group   => 'vagrant',
        replace => false,
        require => Vcsrepo[$dir],
    }

    file { "${dir}/config/application.yml":
        source  => "${dir}/config/application.example.yml",
        replace => false,
        require => Vcsrepo[$dir],
    }

    mysql::database { ['dashboard', 'dashboard_test']:
        require => [
            File["${dir}/config/database.yml"],
            File["${dir}/config/application.yml"],
        ]
    }

    bundler::command { 'exec rake db:migrate':
        directory => $dir,
        unless    => "exec rake db:migrate:status | awk '\$1 == \"down\" { exit 1 }'",
        require   => [
            Bundler::Install[$dir],
            Npm::Install[$dir],
            Mysql::Database['dashboard'],
        ]
    }

    # Make sure the zeus socket is created outside the vboxsf mount
    file { '/etc/environment':
        content => 'ZEUSSOCK=/tmp/zeus.sock',
    }
}
