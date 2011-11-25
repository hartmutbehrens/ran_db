package Plugin::Load::CouchDB::obsynt_gpm;

=head1 NAME
Parse::Plugin::obsynt_gpm
=cut
#pragmas
use strict;
use warnings;


sub abstract {
	return '(internal - cannot be used from command line)';
}

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub recognize {
	my ($self,$dir,$file) = @_;
	my $rv = 0;
	open my $in ,'<', $dir.'/'.$file || die "Could not open $dir/$file for reading: $!\n";
	chomp(my $fline = <$in>);
	close $in;
	
	my @cols = split('\W+',$fline);
	my $id = classify(\@cols);
	if ($id) {
		$rv = 1;
		print "$file could be classified and id cols are $id";
	}
	else {
		print "$file could not be classified\n";
	}
	return $rv;
}

#index,columns/additional,optional,columns,unique,to,file
sub classifiers {
	return ('BEARER,TP,MFS,OMC_ID,SDATE/P33','PVC,BEARER,TP,MFS,OMC_ID,SDATE/P4','BSS,GSL,TP,MFS,OMC_ID,SDATE','CI,LAC,FABRIC,MFS,OMC_ID,SDATE','BSS,BTS,FABRIC,MFS,OMC_ID,SDATE/P472','BSS,FABRIC,MFS,OMC_ID,SDATE/P384');
}


sub classify {
	my ($fields) = @_;
	for (classifiers()) {
		#my ($table,@cols) = split('\W+',$_);
		my ($id_cols,$additional) = split('/',$_);
		my @cols = split('\W+',$id_cols);
		push @cols, split('\W+',$additional) if $additional;
		return $id_cols if has_all_cols($fields,\@cols);
	}
	return undef;
}

sub has_all_cols {
	my ($fields,$unique_cols) = @_;
	my %fields = map {$_ => 1} @$fields;
	my $rv = 1;
	for (@$unique_cols) {
		my $has = exists $fields{$_} ? 1 : 0;
		$rv *= $has; 
	}
	return $rv;
}

1;