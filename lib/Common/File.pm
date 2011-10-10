package Common::File;

=head1 NAME
Common::File;
=cut

#pragmas
use strict;
use warnings;

#i am sure there is a CPAN module out there that does this more portably, but cannot find it at the moment
sub split_path {
	my $file_and_path = shift;
	my $splitter = $^O =~ /win/i ? quotemeta('\\') : '/'; 
	my @file = split($splitter,$file_and_path);
	return @file;	
}

1;