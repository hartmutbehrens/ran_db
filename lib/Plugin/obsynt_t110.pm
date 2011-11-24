package Plugin::obsynt_t110;

=head1 NAME
Parse::Plugin::obsynt_t110
=cut
#Moudle::Pluggable package names should not class with App::Cmd commands
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
	my ($self,$header) = @_;
	my $rv = 0;
	$rv = 1 if ( (exists $header->{'Type_of_measurement'}) && ($header->{'Type_of_measurement'} =~ /rt110/i ) );
	return $rv;
}

sub add_classifiers {
	my ($self,$opt,$header) = @_;
	$opt->{type} = 't110';
	
	my $release = defined $header->{'BSS_release'} ? $header->{'BSS_release'} : 'unknown';
	my $classify = 'classify_'.$release;
	if ($self->can($classify)) {
		push @{$opt->{classifiers}}, $_ for $self->$classify;
	}
	else {
		warn "No classifier has been defined in the t110 plugin for the obsynt file with release version \"$release\". A generic one will be used.\n";
		push @{$opt->{classifiers}}, $_ for $self->generic();
	}
}

sub classify_11 {
	return ('T110_TRX_H,TRXID','T110_SECTOR_H,MC01,MC02','T110_LINK_H,LINK_ID','T110_BSC_H,MC19,MC35','T110_MSC_H,MSC_NAME,MSC_SBL,MC1101'); 
}

sub classify_10 {
	return ('T110_TRX_H,TRXID','T110_SECTOR_H,MC01,MC02','T110_LINK_H,LINK_ID','T110_BSC_H,MC19,MC35','T110_MSC_H,MSC_NAME,MSC_SBL,MC1101'); 
}

sub classifiy_9 {
	return ('T110_TRX_H,TRXID','T110_SECTOR_H,MC01,MC02','T110_LINK_H,LINK_ID','T110_BSC_H,MC19,MC35'); 
}

sub generic {
	return ('T110_TRX_H,TRXID','T110_SECTOR_H,MC01,MC02','T110_LINK_H,LINK_ID','T110_BSC_H,MC19,MC35');
}

sub add_remaps {
	my ($self,$opt,$header) = @_;
	push @{$opt->{remap}}, $_ for ('T110_TRX_H,BTS_INDEX,BTS_ID','T110_TRX_H,BTS_SECTOR,SECTOR','T110_TRX_H,CELL_CI,CI','T110_TRX_H,CELL_LAC,LAC','T110_TRX_H,TRXID,TRX','T110_SECTOR_H,BTS_INDEX,BTS_ID','T110_SECTOR_H,BTS_SECTOR,SECTOR','T110_SECTOR_H,CELL_CI,CI','T110_SECTOR_H,CELL_LAC,LAC'); 
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