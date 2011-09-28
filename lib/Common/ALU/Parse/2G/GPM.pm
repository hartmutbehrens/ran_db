package Common::ALU::Parse::2G::GPM;

=head1 NAME
Common::ALU::Parse::2G::GPM;
=cut

#pragmas
use strict;
use warnings;
#modules
use Compress::Zlib;
use Data::Dumper;
use Regexp::Grammars;
use Time::Local qw(timelocal timelocal_nocheck);

sub alu_gpm_info {
	my ($href) = @_;
	my @cols = qw/HOUR MIN SEC YEAR MONTH DAY/;
	my %sdate = ();
	my %edate = ();
	my %bssver = (
		'4' => 'b8',
		'5' => 'b9',
		'6' => 'b10',
		'7' => 'b11');
		
	my ($stime,$sdate) = @{$href}{qw/STARTTIME DATE/};
	@sdate{@cols} = (split(':',$stime),split('-',$sdate));
	
	$sdate{'MONTH'}--;
	@edate{qw/SEC MIN HOUR DAY MONTH YEAR/} = localtime(timelocal_nocheck(@sdate{qw/SEC MIN HOUR DAY MONTH YEAR/}) + 3600);
	for (@cols) {
		$edate{$_} = sprintf("%02d",$edate{$_});
	}
	$edate{'MONTH'}++;
	$edate{'YEAR'} += 1900;
	@{$href}{qw/ENDTIME ENDDATE/} = (join(':',@edate{qw/HOUR MIN SEC/}),join('-',@edate{qw/YEAR MONTH DAY/}));
	$href->{'STARTDATE'} = $href->{'DATE'};
	$href->{'SDATE'} = $href->{'DATE'}.' '.$stime;
	$href->{'VERSION'} = $bssver{$href->{'ITFVERSION'}};
	delete $href->{'DATE'};
}

sub get_parser {
	my $parser = qr{
		<GPM>
		
		<rule: GPM> <[Element]>
		<rule: Element> <heading> | <data>
		<rule: heading> <literal>\s\{
		<rule: data> <key=literal>\s<value=literal> 
		<rule: literal>  [^][\$&%#_{}~^\s]+
	}x;
	return $parser;
}


sub parse {
	my ($file,$templatedir) = @_;
	print "Parsing : $file\n";
	my $rv = 0;
	my %pm = ();
	my %counters = ();
	my %info = ();
	my @gz = ();
	my $gz = gzopen($file, "rb") or die "Cannot open $file: $!\n";
	while ($gz->gzreadline($_) > 0) {
		chomp;
		push(@gz,$_);
	}
	$gz->gzclose();
	my $contents = join(';',@gz);
	my $parser = get_parser();
	if ($contents =~ /$parser/) {
		print Dumper(\%/);
	}
#	for (qw/STARTTIME MFS DATE ITFVERSION/) {
#		($info{$_}) = ($contents =~ /$_\s(.*?);/);
#	}
#	alu_gpm_info(\%info);
#	my $layout_file = $templatedir.'/layout.gpm.'.lc($info{'VERSION'}).'.xml';
#	unless ((-f $layout_file) && (-s $layout_file)) {
#			print "The file $file with version $info{VERSION} cannot be decoded because no layout file could be found (looking for $layout_file) !\n";
#			return $rv;
#		}
#	my $pmLayout = Common::XML::read_xml($layout_file);
#	my @blocks = keys %{$pmLayout->{'blocktype'}};
#	
#	foreach my $item (split(/\}/,$contents)) {
#		next if $item eq ';'; 
#		my ($block,$vals) = ($item =~ /(\w+)\s\{(.*)/);
#		next unless defined $block;
#		next if $block eq '';
#		next unless (grep{/$block/i} @blocks);
#		my ($table,$ix) = @{$pmLayout->{'blocktype'}->{uc($block)}}{qw/loadtable index/};
#		my @ix = split(',',$ix);
#		my %d = ();
#		while ($vals =~ /(\w+)\s(\w+)/g) {
#			$d{$1} = $2;
#			$counters{$table}{$1} = 1;
#		}
#		my $idx = $ix.'='.join(',',@d{@ix});
#		delete @d{@ix};
#		delete @{$counters{$table}}{@ix};
#		
#		@{$pm{$table}{$idx}}{keys %d} = values %d;
#	}
#	return(\%pm,\%counters,\%info);
}

1;
