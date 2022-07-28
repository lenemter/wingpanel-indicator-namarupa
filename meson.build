project(
    'namarupa',
    'vala', 'c',
    version: '1.0.3'
)

i18n = import('i18n')
gettext_name = meson.project_name() + '-indicator'

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

indicator_dir_cmd = run_command('pkg-config', 'indicator3-0.4', '--variable=indicatordir')
if indicator_dir_cmd.returncode() != 0
  message ('Indicator directory not found')
endif

indicator_dir = indicator_dir_cmd.stdout().strip()

# Other configs
conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('AYANATAINDICATORDIR', indicator_dir)
add_global_arguments('-DDATADIR="' + get_option('datadir') + '"', language: 'c')
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

# Arguments for C
c_args = [
  '-include', 'config.h',
  '-w'
]

shared_module(
    meson.project_name(),
    'src/AyatanaIndicator.vala',
    'src/Indicator.vala',
    'src/IndicatorButton.vala',
    'src/IndicatorIface.vala',
    'src/IndicatorFactory.vala',
    'src/IndicatorLoader.vala',
    'src/IndicatorObject.vala',
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('wingpanel'),
        dependency('indicator3-0.4')
    ],
    vala_args: [
        meson.source_root() + '/vapi/config.vapi'
    ],
    install: true,
    install_dir : dependency('wingpanel').get_pkgconfig_variable('indicatorsdir')
)
