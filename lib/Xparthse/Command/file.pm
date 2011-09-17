package Xparthse::Command::file;

=head1 NAME
Xparthse::Command::file;
=cut
#pragmas
use strict;
use warnings;
#modules
use Xparthse -command;
use Common::XML;
use XML::LibXML;


sub abstract {
	return 'parse xml file against an xpath and write result to output';
}

sub usage_desc {
	return "%c file %o [ filename(s) ]";
}

sub opt_spec {
	return (
	[ "xpath|x=s",	"xpath argument", { required => 1}],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;	
	$self->usage_error("At least one file name is required") unless @$args;
	for (@$args) {
		die "The file $_ does not exist!\n" unless -e $_;	
	}
}

sub execute {
	my ($self, $opt, $args) = @_;
	
	my $parser = XML::LibXML->new();
	for (@$args) {
		my $doc = $parser->parse_file($_);
		for ( $doc->findnodes($opt->{xpath}) ) {
			my $value = Common::XML::get_text_contents($_);
			print $value,"\n" if defined $value;
		}	
	}
}


1;