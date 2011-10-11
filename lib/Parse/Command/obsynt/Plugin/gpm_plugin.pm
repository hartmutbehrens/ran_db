package Parse::Command::obsynt::Plugin::gpm_plugin;

=head1 NAME
Parse::Command::obsynt::Plugin::gpm_plugin
=cut
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
	$rv = 1 if ( (exists $header->{'MFS_version'}) && (exists $header->{'MFS_subversion'}) );
	return $rv;
}

sub add_classifiers {
	my ($self,$opt,$header) = @_;
	$opt->{type} = 'gpm';
	
	my $release = defined $header->{'MFS_version'} ? $header->{'MFS_version'} : 'unknown';
	my $classify = 'classify_'.$release;
	if ($self->can($classify)) {
		push @{$opt->{classifiers}}, $_ for $self->$classify;
	}
	else {
		warn "No classifier has been defined in the $opt->{type} plugin for the obsynt file with release version \"$release\". A generic one will be used.\n";
		push @{$opt->{classifiers}}, $_ for $self->generic();
	}
}

sub classify_7 {
	return ('GPM_BEARERCHANNEL_H,BEARER,P33','GPM_PVC_H,PVC,P23','GPM_LAPD_H,GSL,P2A','GPM_CELL_H,CI,LAC,P38B','GPM_BTS_H,BTS_NB_EXTRA_ABIS_TS,P472','GPM_BSC_H,BSS,FABRIC,P392A,P392B','GPM_GBIP_H,SGSNIPENDPOINT,SGSN_IP_ADDRESS'); 
}

sub generic {
	return ('GPM_BEARERCHANNEL_H,BEARER,P33','GPM_PVC_H,PVC,P23','GPM_LAPD_H,GSL,P2A','GPM_CELL_H,CI,LAC,P38B','GPM_BTS_H,BTS_NB_EXTRA_ABIS_TS,P472','GPM_BSC_H,BSS,FABRIC,P392A,P392B');
}

sub add_remaps {
	my ($self,$opt,$header) = @_;
	#push @{$opt->{remap}}, $_ for ('T110_TRX_H,BTS_INDEX,BTS_ID','T110_TRX_H,BTS_SECTOR,SECTOR','T110_TRX_H,CELL_CI,CI','T110_TRX_H,CELL_LAC,LAC','T110_TRX_H,TRXID,TRX','T110_SECTOR_H,BTS_INDEX,BTS_ID','T110_SECTOR_H,BTS_SECTOR,SECTOR','T110_SECTOR_H,CELL_CI,CI','T110_SECTOR_H,CELL_LAC,LAC'); 
}

sub process_header {
	my ($self,$header) = @_;
	my $sdt = $header->{'Measurement_begin_date_and_time'};
	my $edt = $header->{'Measurement_end_date_and_time'};
	@$header{qw/STARTDATE STARTTIME/} = split(' ',$sdt);
	@$header{qw/ENDDATE ENDTIME/} = split(' ',$edt);
	$header->{'SDATE'} = $sdt;
	$header->{'MFS'} = $header->{'Number_of_the_MFS'};
}

1;