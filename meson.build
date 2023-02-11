project('httparsed', 'd',
    version: '1.3.0'
)

httparsed_build_versions = []

httparsed_src = ['source/httparsed.d']

httparsed_lib = static_library(
    'httparsed',
    httparsed_src,
    include_directories: include_directories('source'),
    d_module_versions: httparsed_build_versions
)

httparsed_dep = declare_dependency(
    include_directories: include_directories('source'),
    link_with: httparsed_lib
)

bc_link_args = []
if meson.get_compiler('d').get_id() == 'llvm'
    bc_link_args += '-link-defaultlib-shared=false'
endif

test_exe = executable(
    'httparsed-test',
    httparsed_src,
    include_directories: include_directories('source'),
    d_args: ['-betterC', '-unittest'],
    d_module_versions: ['CI_MAIN'],
    link_args: bc_link_args
)
test('bctest', test_exe)
