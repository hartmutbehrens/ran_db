use strict;
use warnings;
use inc::Module::Install;
 
# Define metadata
name			'ran_db';
abstract		'Collection of scripts to manage retrieval, parsing, loading of config and PM files from RAN management systems.';
author			'Hartmut Behrens <hartmut.behrens@gmail.com>';
version			'0.01';			
license			'Alcatel-Lucent';
repository		'git://github.com/hartmutbehrens/ran_db.git';
 
# Specific dependencies
requires       'App::Cmd'  => 0;
requires       'Archive::Zip'  => 0;
requires       'Archive::Tar'  => 0;
requires       'Compress::Zlib'  => 0;
requires       'DBI'  => 0;
requires       'DBD::mysql'  => 0;
requires       'Fcntl'  => 0;
requires       'File::Path'  => 0;
requires       'IO::Uncompress::Gunzip'  => 0;
requires       'Memoize'  => 0;
requires	   'Module::Pluggable'  => 0;
requires       'Net::FTP'  => 0;
requires       'Time::Local'  => 0;
requires       'XML::Bare'  => 0;
requires       'XML::LibXML'  => 0;
requires       'XML::Simple'  => 0;

no_index       'directory'   => 'templates';
no_index       'directory'   => 'etc';

install_script 'bin/rdb-aggregate';
install_script 'bin/rdb-fetch';
install_script 'bin/rdb-load';
install_script 'bin/rdb-make';
install_script 'bin/rdb-modify';
install_script 'bin/rdb-parse';
install_script 'bin/rdb-report';
install_script 'bin/rdb-xparthse';
 
WriteAll;