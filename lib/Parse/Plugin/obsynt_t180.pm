package Parse::Plugin::obsynt_t180;

=head1 NAME
Parse::Plugin::obsynt_t180
=cut
#Moudle::Pluggable package names should not class with App::Cmd commands
#pragmas
use strict;
use warnings;
#modules
use Parse -command;

sub abstract {
	return '(internal - cannot be used from command line)';
}

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub recognize {
	my ($self,$header) = @_;
	my $rv = 0;
	$rv = 1 if ( (exists $header->{'Type_of_measurement'}) && ($header->{'Type_of_measurement'} =~ /rt180/i ) );
	return $rv;
}

sub add_classifiers {
	my ($self,$opt,$header) = @_;
	$opt->{type} = 't180';
	
	my $release = defined $header->{'BSS_release'} ? $header->{'BSS_release'} : 'unknown';
	my $classify = 'classify_'.$release;
	if ($self->can($classify)) {
		push @{$opt->{classifiers}}, $_ for $self->$classify;
	}
	else {
		warn "No classifier has been defined in the $opt->{type} plugin for the obsynt file with release version \"$release\". A generic one will be used.\n";
		push @{$opt->{classifiers}}, $_ for $self->generic();
	}
}

sub classify_11 {
	return ('T180_ADJ_H,C400,C401,C402'); 
}

sub classify_10 {
	return ('T180_ADJ_H,C400,C401,C402'); 
}

sub classifiy_9 {
	return ('T180_ADJ_H,C400,C401,C402'); 
}

sub generic {
	return ('T180_ADJ_H,C400,C401,C402');
}

sub add_remaps {
	my ($self,$opt,$header) = @_;
	push @{$opt->{remap}}, $_ for ('T180_ADJ_H,CELL_CI_ADJ,TARGET_CI','T180_ADJ_H,CELL_LAC_ADJ,TARGET_LAC','T180_ADJ_H,CELL_CI,CI','T180_ADJ_H,CELL_LAC,LAC'); 
}

sub process_header {
	my ($self,$header) = @_;
	my $sdt = $header->{'Measurement_begin_date_and_time'};
	my $edt = $header->{'Measurement_end_date_and_time'};
	@$header{qw/STARTDATE STARTTIME/} = split(' ',$sdt);
	@$header{qw/ENDDATE ENDTIME/} = split(' ',$edt);
	$header->{'SDATE'} = $sdt;
	$header->{'BSC_NAME'} = $header->{'Name_of_BSC'};
	($header->{'BSC_ID'}) = ($header->{'Input_file_name'} =~ /.*?PMRES.*?\..*?\.(\d+)\..*?/);
}

1;