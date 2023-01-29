project(
    'namarupa',
    'vala', 'c',
    version: '1.0.3',
    meson_version: '>=0.58'
)

gettext_name = meson.project_name() + '-indicator'
i18n = import('i18n')

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)
add_project_arguments(
    '--vapidir', meson.current_source_dir() / 'vapi',
    language: 'vala'
)
add_project_arguments(
    '-DG_LOG_DOMAIN="com.github.lenemter.wingpanel-indicator-namarupa"',
    language:'c'
)

# Other configs
config_data = configuration_data()
config_data.set_quoted('GETTEXT_PACKAGE', gettext_name)
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('AYATANAINDICATORDIR', dependency('indicator3-0.4').get_variable('indicatordir'))

shared_module(
    meson.project_name(),
    configure_file(input: 'src/Config.vala.in', output: '@BASENAME@', configuration: config_data),
    'src/Indicator.vala',
    'src/IndicatorButton.vala',
    'src/IndicatorFactory.vala',
    'src/Separator.vala',
    'src/TrayIcon.vala',
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('wingpanel'),
        dependency('indicator3-0.4')
    ],
    install: true,
    install_dir : dependency('wingpanel').get_variable('indicatorsdir')
)

subdir('po')
