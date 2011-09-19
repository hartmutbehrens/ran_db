package Common::XML;

=head1 NAME
Common::XML;
=cut

#pragmas
use strict;
use warnings;
#modules
use Memoize;
use XML::LibXML;
use XML::Simple;
#cache slow functions
memoize('get_items_text');
memoize('get_node_text');
memoize('get_value');

# read xml and return hash ref containing  info
sub read_xml {
	my $file = shift;
	my $config = XMLin($file,forcearray => 1);
	return $config;
}

sub find_node {
	my ($node, $xpath) = @_;
	if (! defined($node) || ! defined($xpath)) {
		return undef;
	}
	
	my $match = ($node->findnodes($xpath))[0];
	return defined($match) ? $match : undef;
}

sub get_value {
	my ($node,$xpath) = @_;
	my $match = find_node($node,$xpath);
	my $value = defined($match) ? get_text_contents($match) : undef;
	return $value;
}

sub get_node_text {
	my ($node,$xpath) = @_;
	my @matches = $node->findnodes($xpath);
	return undef if (! @matches);
	my @names = map($_->nodeName(),@matches);
	return @names;
}

sub get_items_text {
	my ($node,$xpath) = @_;
	my @matches = $node->findnodes($xpath);
	return undef if (! @matches);
	my @text = map(get_text_contents($_),@matches);
	return @text;
}

sub get_text_contents {
	my ($node,$strip) = @_;
	return if (! $node);
	my $contents;
	my %cTag;

	return if (! $node);
	if ($node->hasChildNodes) {
		$contents = undef;
		for my $child ($node->childNodes) {
			if ($child->nodeName =~ /text/) {
				$contents = $child->to_literal();
				chomp($contents);
			}
			else {
				$cTag{$child->nodeName()}++;
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
	return defined $contents ? $contents : \%cTag;

}

1;
