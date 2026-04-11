project('com.prateekmedia.clipboardmanager',
        ['vala', 'c'],
        version: '2.1.0',
        meson_version: '>=0.40.0',
        license: 'GPL3')

am_cflags = [
    '-w',
    '-Wno-incompatible-pointer-types',
    '-Wno-implicit-function-declaration',
]

add_global_arguments(am_cflags, language: 'c')

# Global path variable
prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
datadir = join_paths(prefix, get_option('datadir'))

LOCALE_DIR = join_paths(prefix, get_option('localedir'))

VAPI_DIR = join_paths(meson.source_root(), 
                      'vapi')

install_data('schema/com.prateekmedia.clipboardmanager.gschema.xml',
   install_dir: '/usr/share/glib-2.0/schemas'
)


PIXMAPS_DIR = join_paths(datadir, 'pixmaps')

LIB_INSTALL_DIR = join_paths(prefix, libdir, 'budgie-desktop', 'plugins', meson.project_name())

message('Installing applet...')

subdir('src')
subdir('po')
subdir('icons')

meson.add_install_script('meson_post_install')
