package Parse::Plugin::obsynt_t18;

=head1 NAME
Parse::Plugin::obsynt_t18
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
	$rv = 1 if ( (exists $header->{'Type_of_measurement'}) && ($header->{'Type_of_measurement'} =~ /rt18_a/i ) );
	return $rv;
}

sub add_classifiers {
	my ($self,$opt,$header) = @_;
	$opt->{type} = 't18';
	
	my $release = defined $header->{'BSS_release'} ? $header->{'BSS_release'} : 'unknown';
	my $classify = 'classify_'.$release;
	if ($self->can($classify)) {
		push @{$opt->{classifiers}}, $_ for $self->$classify;
	}
	else {
		warn "No classifier has been defined in the t18 plugin for the obsynt file with release version \"$release\". A generic one will be used.\n";
		push @{$opt->{classifiers}}, $_ for $self->generic();
	}
}

sub classify_11 {
	return ('T18_N7_H,C180A','T18_ACHANNEL_H,LINK_ID,C750'); 
}

sub classify_10 {
	return ('T18_N7_H,C180A','T18_ACHANNEL_H,LINK_ID,C750'); 
}

sub classifiy_9 {
	return ('T18_N7_H,C180A','T18_ACHANNEL_H,LINK_ID,C750'); 
}

sub generic {
	return ('T18_N7_H,C180A','T18_ACHANNEL_H,LINK_ID,C750');
}

sub add_remaps {
	my ($self,$opt,$header) = @_;
	push @{$opt->{remap}}, $_ for ('T18_ACHANNEL_H,LINK_ID,LINK'); 
}

sub parse_section {
	my ($self,$table,$cols,$data) = @_;
	add_pcm_ts($cols,$data) if $table eq 'T18_ACHANNEL_H';
}

sub add_pcm_ts {
	my ($cols,$data) = @_;
	push @$cols, qw/TS PCM/;
	my %d;
	for my $vals (@$data) {
		@d{@$cols} = @$vals;
		my $ts = extract_val($d{'LINK'},0,4);
		my $pcm = extract_val($d{'LINK'},5,31);
		push @$vals,$ts,$pcm;
	}
}

sub extract_val {
	my ($num,$lsb,$msb) = @_;
	my $mask = 0;
	$mask += 2**$_ for ($lsb..$msb);
	my $rv = ($num & $mask) >> $lsb;
	return $rv;
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