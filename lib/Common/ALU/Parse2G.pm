package Common::ALU::Parse2G;

=head1 NAME
Common::ALU::Parse2G;
=cut

#pragmas
use strict;
use warnings;

#read PM header records to figure out version, date, time, etc
sub alu_pm_info {
	my $file = shift;
	my %info;
	my @b6ver = (37..56);		#see OMC - BSS MIB Specification
	my @b7ver = (71..86);		
	my @b8ver = (91..103);	
	my @b9ver = (111..113,120..122,130..132,140,150,151,152);
	my @b10ver = (162..178);
	my @b11ver = (227,236);
	my %classifier = ();
	@classifier{@b6ver} = map('b6',0..$#b6ver);
	@classifier{@b7ver} = map('b7',0..$#b7ver);
	@classifier{@b8ver} = map('b8',0..$#b8ver);
	@classifier{@b9ver} = map('b9',0..$#b9ver);
	@classifier{@b10ver} = map('b10',0..$#b10ver);
	@classifier{@b11ver} = map('b11',0..$#b11ver);
	open my $in ,"<","$file" or die "Cannot open $file for reading: $!\n";
	binmode($in);
	local $/ = \256; # read 256 bytes at a time
	my ($bssver,$bscrel,$moc,$moi,$mtype,$stime,$etime,$filler) = (undef,undef,undef,undef,undef,undef,undef,undef);
	while ($_ = <$in>) {
		my ($len, $seq, $rtype, $ftype) = unpack("v2C2",$_);
		if ($ftype != 3) {
			print "Error: This file is not a valid binary Alcatel PM file!\n";
			close $in;
			last;
		}
		if ($rtype == 12) {
			#the header record changed from b10 to b11 (GRRR !), so now we first have to check which one we have by checking for a FILLER (FF) 10 bytes into the header
			my (undef,$has_filler) = unpack("a9C",$_);
			if ($has_filler == 255) {
				(undef, $bssver, $bscrel,$filler,$moc,$moi,undef,$mtype,undef,$stime,$etime) = unpack("a6vC2v2a16va6a16a16",$_);
			}
			else {
				(undef, $bssver, $bscrel,$moc,$moi,undef,$mtype,undef,$stime,$etime) = unpack("a6C2v2a16va6a16a16",$_);	
			}
			last;
			close $in;
		}
		else {
			warn "$file has a type $rtype record header, which the parser does not understand. It only understands type 12 header records (performance files).\n";
			close $in;
			last;
		}
	}
	 
	my $rv = defined($classifier{$bssver}) ? $classifier{$bssver} : 'BSSver'.$bssver;
	
	my @cols = qw/SEC MIN HOUR DAY MONTH YEAR/;
	
	my (%sdate,%edate,%asdate,%aedate);
	
	(undef,@sdate{@cols}) = unpack("a2a2a2a2a2a2a4",$stime);
	(undef,@edate{@cols}) = unpack("a2a2a2a2a2a2a4",$etime);
	
	my $sdate = join('-',@sdate{qw/YEAR MONTH DAY/});
	my $edate = join('-',@edate{qw/YEAR MONTH DAY/});
	$stime = join(':',@sdate{qw/HOUR MIN SEC/});
	$etime = join(':',@edate{qw/HOUR MIN SEC/});
	my ($bscId,$bscName) = ($file =~ /.*?PMRES.*?\..*?\.(\d+)\.(.*?)\./);
	#maybe too much of date and time s**t here...
	@info{qw/VERSION BSC_ID BSC_NAME STARTTIME STARTDATE ENDTIME ENDDATE SDATE/} = ($rv,$bscId,$bscName,$stime,$sdate,$etime,$edate,$sdate.' '.$stime);
	return \%info;
}

sub decode_t180 {
	my $infile = shift;
	my %pm = ();
	my %counters = ();
	
	my ($table,$bts,$sector) = ('T180_ADJ_H',undef,undef);	#arrggh, hardcoded for now..to fix
	open INFILE,"$infile" or die "Cannot open $infile: $!\n";
	binmode(INFILE);
	local $/ = \256; # read 256 bytes at a time
	print "Parsing: $infile\n";
	while ($_ = <INFILE>) {
		my ($len, $seq, $rtype, $ftype) = unpack("v2C2",$_);
		if ($ftype != 3) {
			warn "Error: Skipping $infile because it is not a valid Alcatel binary PM file!";
			return 0;
		} #end $ftype
		if ($rtype == 3) {
			my $bytecounter = 6;
			while ($bytecounter < 256) {
				my %vals = ();
				my (undef, $btype, $blen) = unpack("a$bytecounter v2",$_);
				last if ($btype == 65535);
				#print "Byte counter : $bytecounter, BlockType: $btype, BlockLen: $blen\n";
				
				if ($btype == 1800) {
					#these are the target cell details
					(undef, undef, undef, $bts,$sector) = unpack("a".$bytecounter."v2C2",$_);
					$bytecounter += 6;	# skip 4 (btype and blen) + index
				}
				elsif ($btype == 1810) {
					$bytecounter += (4+4);	# skip 4 (btype and blen) + 4 (MCC_MNC,FILLER)
					#source cell details and HO count
					my (undef,$lac,$ci,@ho) = unpack("a$bytecounter v2C12",$_);
					my ($c400,$c401,$c402) = (calc_val('yes',@ho[0..3]),calc_val('yes',@ho[4..7]),calc_val('yes',@ho[8..11]));
					#unless (($ho[0] == 255) && ($ho[$#ho] == 255)) {
					if (($c400 < 1000000) && ($c401 < 1000000) && ($c402 < 1000000)) {			#exclude some of the ridiculous values reported in T180 statistics
						my $idx = join(',',qw/LAC CI BTS_ID SECTOR/).'='.join(',',$lac,$ci,$bts,$sector);
						@{$pm{$table}{$idx}}{qw/C400 C401 C402/} = ($c400,$c401,$c402);
						@{$counters{$table}}{qw/C400 C401 C402/} = (1,1,1);
					}
					$bytecounter += 16; # 16 = 2 bytes LAC + 2 bytes CI + 4 bytes for each C400,C401,C402
				}
				else {
					$bytecounter = 256;
					last;
				}
			} 
		} #end $rtype
	}
	close INFILE;
	return (\%pm,\%counters);	
}

#given a binary PM file, parse it according to $layout xml file
sub decode_binary {
	my ($infile,$layout) = @_;
	my %pm = ();
	my %counters = ();
	my %tmplt = (
		'1' => 'C',
		'2' => 'n',
		'4' => 'N',
		);
	open INFILE,"$infile" or die "Cannot open $infile: $!\n";
	binmode(INFILE);
	local $/ = \256; # read 256 bytes at a time
	print "Parsing: $infile\n";
	while ($_ = <INFILE>) {
		my ($len, $seq, $rtype, $ftype) = unpack("v2C2",$_);
		if ($ftype != 3) {
			warn "Error: Skipping $infile because it is not a valid Alcatel binary PM file!";
			return 0;
		} #end $ftype
		if ($rtype == 3) {
			my $bytecounter = 6;
			while ($bytecounter < 256) {
				my %vals = ();
				my (undef, $btype, $blen) = unpack("a$bytecounter v2",$_);
				last if ($btype == 65535);
				#print "Byte counter : $bytecounter, BlockType: $btype, BlockLen: $blen\n";
				
				if (exists($layout->{'blocktype'}->{$btype})) {
					my ($table,$ix,$idxLen) = @{$layout->{'blocktype'}->{$btype}}{qw/loadtable index indexlength/};
					#my @ix_cols = split(',',$ix);
					my $ordering = defined($layout->{'alcatelOrdering'}) ? lc($layout->{'alcatelOrdering'}) : 'yes';
					my $bit_op = defined $layout->{'blocktype'}->{$btype}->{'bit-op'} ? $layout->{'blocktype'}->{$btype}->{'bit-op'} : undef;
					my (undef, undef, undef, @ix) = unpack("a".$bytecounter."v2C".$idxLen,$_);	
					if (defined $bit_op) {
						my $val = calc_val($ordering,@ix);
						@ix = ();
						push @ix, $val;
						for (split(',',$bit_op)) {
							my ($col,$lsb,$msb) = ($_ =~ /(.*?)=LSB(\d+)\/MSB(\d+)/);
							$ix = join(',',$ix,$col);
							push @ix, extract_val($val,$lsb,$msb);
						}
					}
					
					$bytecounter += (4+$idxLen);	# skip 4 (btype and blen) + index
					
					my $idx = $ix eq 'none' ? 'none=none' : join(',',split(',',$ix)).'='.join(',',@ix);
					#print "$table $idx\n";
					my @counters = keys %{$layout->{'blocktype'}->{$btype}->{'counter'}};
					my @repeats = keys %{$layout->{'blocktype'}->{$btype}->{'canrepeat'}};
					if (@counters) {		#decode counters
						foreach my $counter (@counters) {
							next if ($counter eq 'FILLER');
							my ($len,$offset,$vector,$usize,$dim) = @{$layout->{'blocktype'}->{$btype}->{'counter'}->{$counter}}{qw/length offset vector unitsize dimensions/};
							$usize = 1 if not defined($usize);
							$vector = 'no' if not defined($vector);
							my $readPos = $bytecounter + $offset;
							my (undef,@ary) = unpack("a".$readPos.$tmplt{$usize}.$len,$_);
							unless (($ary[0] == 255) && ($ary[$#ary] == 255)) {
								if ($vector eq 'no') {
									$pm{$table}{$idx}{$counter} = calc_val($ordering,@ary); #values in Alcatel PM file are always LSB,MSB,LSB,MSB...etc. (except for PMRES-31)
									$counters{$table}{$counter} = 1;
								}
								else {
									my @dim = defined $dim ? split(',',$dim) : [1];
									my $ix_ref = defined $dim ? index_rms_vector($#ary,$counter,\@dim) : index_rms_vector($#ary,$counter);
									@{$pm{$table}{$idx}}{@{$ix_ref}} = @ary;
									@{$counters{$table}}{@{$ix_ref}} = @ary; 
									$pm{$table}{$idx}{$counter} = join(',',@ary); 
									$counters{$table}{$counter} = 1;
								}
							}
						}
					}
					if (@repeats) {		#decode blocks of data that are repeated
						foreach my $rpt (@repeats) {
							my ($bytesRead,$bytesSeen) = (0,0);
							while ($bytesRead < $blen) {
								my @rcounters = keys %{$layout->{'blocktype'}->{$btype}->{'canrepeat'}->{$rpt}->{'counter'}};
								my %vals = ();
								foreach my $rCounter (@rcounters) {
									my ($len,$offset,$vector,$usize,$dim) = @{$layout->{'blocktype'}->{$btype}->{'canrepeat'}->{$rpt}->{'counter'}->{$rCounter}}{qw/length offset vector unitsize dimensions/};
									$usize = 1 if not defined($usize);
									$vector = 'no' if not defined($vector);
									my $readPos = $bytesRead + $bytecounter + $offset;
									my (undef,@ary) = unpack("a".$readPos.$tmplt{$usize}.$len,$_);
									unless (($ary[0] == 255) && ($ary[$#ary] == 255)) {
										if ($vector eq 'no') {
											$vals{$rCounter} = calc_val($ordering,@ary);
										}
										else {
											my @dim = defined $dim ? split(',',$dim) : qw/1/;
											my $ix_ref = defined $dim ? index_rms_vector($#ary,$rCounter,\@dim) : index_rms_vector($#ary,$rCounter);
											$vals{$rCounter} = join(',',@ary);
											@vals{@{$ix_ref}} = @ary;
										}
										#$vals{$rCounter} = ($vector eq 'no') ? calc_val($ordering,@ary): join(',',@ary);
									}
									$bytesSeen += ($len*$usize);
								}
								if (%vals) {
									if (defined($layout->{'blocktype'}->{$btype}->{'canrepeat'}->{$rpt}->{'subindex'})) {
										my @si = split(',',$layout->{'blocktype'}->{$btype}->{'canrepeat'}->{$rpt}->{'subindex'});
										#print "IX $ix and @ix, SI @si and @vals{@si}\n";
										my $nidx = join(',',split(',',$ix),@si).'='.join(',',@ix,@vals{@si});
										delete @vals{@si};
										@{$pm{$table}{$nidx}}{keys %vals} = values %vals;
										@{$counters{$table}}{keys %vals} = values %vals;
									}
									else {
										@{$pm{$table}{$idx}}{keys %vals} = values %vals;
										@{$counters{$table}}{keys %vals} = values %vals;
									}
								}
								$bytesRead += $bytesSeen;
								last if ($bytesRead+$bytesSeen) > $blen;
								$bytesSeen = 0;
							}
						}
					}
					$bytecounter += ($blen - $idxLen);	# point at next block... (-index length because btsix,sector are part of block length count, but already added +6 earlier)
				}
				else {
					last;		#skip unknown blocks
				}
			} 
		} #end $rtype
	}
	close INFILE;
	return (\%pm,\%counters);
}

sub index_rms_vector {
	my ($pos_len,$counter,$dim_ref) = @_;
	$dim_ref = [1] unless defined $dim_ref;
	my %count = map {$_ => 1} @{$dim_ref};
	my @ix;
	
	for my $pos (0..$pos_len) {
		my @digits = map($count{$_},reverse @{$dim_ref});
		$digits[0] = sprintf("%02d",$digits[0])  unless $counter =~ /^TAB\_/;
		push @ix,join('_',$counter,@digits);
		for (0..$#{$dim_ref}) {
			if ($_ > 0) {
				if ($count{$dim_ref->[$_-1]} > $dim_ref->[$_-1]) {
					$count{$dim_ref->[$_-1]} = 1;
					$count{$dim_ref->[$_]}++;
				} 
			}
			else {
				$count{$dim_ref->[$_]}++;	
			}
		}
	}
	return \@ix;
}


sub extract_val {
	my ($num,$lsb,$msb) = @_;
	my $mask = 0;
	$mask += 2**$_ for ($lsb..$msb);
	my $rv = ($num & $mask) >> $lsb;
	return $rv;
}

sub calc_val {
	my ($alc_ordering,@val) = @_;
	my $len = $#val+1;
	my %revExponent = (
		'1'	=> [0],
		'2'	=> [0,1],
		'3'	=> [2,0,1],
		'4'	=> [2,3,0,1],
		'6'	=> [4,5,2,3,0,1],
	);
	my %exponent = (
		'1' => [0],
		'2' => [1,0],
		'3' => [2,1,0],
		'4' => [3,2,1,0],
		'6' => [5,4,3,2,1,0],
	);
	my $rv = 0;
	for my $i (0..($len-1)) {
		if ($alc_ordering eq 'yes') {
			$rv += $val[$i]*256**(${$revExponent{$len}}[$i]);
		}
		else {
			$rv += $val[$i]*256**(${$exponent{$len}}[$i]);
		}
	}
	return $rv;
}

1;
