package Common::XML;

=head1 NAME
Common::XML;
=cut

#pragmas
use strict;
use warnings;
#modules
use XML::LibXML;
use XML::Simple;

# read xml and return hash ref containing  info
sub read_xml {
	my $file = shift;
	my $config = XMLin($file,forcearray => 1);
	return $config;
}

sub get_text_contents {
	my ($node,$strip) = @_;
	return if (! $node);
	
	my $contents = undef;
	if ($node->hasChildNodes) {
		for my $child ($node->childNodes) {
			if ($child->nodeName =~ /text/) {
				$contents = $child->to_literal();
				chomp($contents);
			}
		}
	}
	else {
		$contents = $node->to_literal();
	}
	
	if ($strip) {
		$contents =~ s/^\s+//;
		$contents =~ s/\s+$//;
	}
	return $contents;
}

1;
