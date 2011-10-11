package Parse::Command::obsynt::Plugin::t110;

=head1 NAME
Parse::Command::obsynt::Plugin::t110
=cut
#pragmas
use strict;
use warnings;
#modules
use Data::Dumper;
use Parse -command;

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
	my ($self,$opt) = @_;
	$opt->{type} = 't110';
	push @{$opt->{classifiers}}, $_ for ('T110_TRX_H,TRXID','T110_SECTOR_H,MC01,MC02','T110_LINK_H,LINK_ID','T110_BSC_H,MC19,MC35','T110_MSC_H,MSC_NAME,MSC_SBL,MC1101'); 
}

sub add_remaps {
	my ($self,$opt) = @_;
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