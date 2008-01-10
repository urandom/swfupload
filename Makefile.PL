use inc::Module::Install;

name			'IWL-SWFUpload';
license         'perl';
all_from		'lib/IWL/SWFUpload.pm';

requires		'IWL' => 0.52;

install_share;

auto_install;

WriteAll;
