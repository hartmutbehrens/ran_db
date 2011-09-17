package Common::XML;

=head1 NAME
Common::XML;
=cut

#pragmas
use strict;
use warnings;
#modules
use XML::LibXML;

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
