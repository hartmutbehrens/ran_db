package  Aggregate::Command::rnl;

=head1 NAME
Aggregate::Command::rnl;
=cut
#pragmas
use strict;
use warnings;

#modules
use Common::Lock;
use Common::MySQL;
use Aggregate -command;

sub abstract {
	return "aggregate rnl (2G config snapshot) data";
}

sub usage_desc {
	return "%c rnl %o";
}

sub opt_spec {
	return (
	[ "user|u=s",	"database user", { required => 1 }],
	[ "pass|x=s",	"database password", { required => 1 }],
	[ "host|h=s",	"database host IP address", { required => 1 }],
	[ "db|d=s",	"database name", { required => 1 }],
	[ "port|P=s",	"database port", { hidden => 1, default => 3306 }],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;	
}

sub execute {
	my ($self, $opt, $args) = @_;
	my $dbh;
	my $count = 0;
	my $connected = Common::MySQL::connect(\$dbh,@{$opt}{qw/user pass host port db/});
	unless ($connected) {
		die "Could not connect user \"$opt->{user}\" to database \"$opt->{db}\" on host \"$opt->{host}\". Please check that the provided credentials are correct and that the databse exists!\n";
	}
	my $lock = '.'.$opt->{db}.'rnl';
	Common::Lock::get_lock($lock) or Common::Lock::bail($lock);
	aggregate_rnl($dbh);
}

#"aggregate" rnl info - mostly just fill in LAC,CI, etc into the table...
sub aggregate_rnl {
	my $dbh = shift;
	#cell,bsc updates
	$dbh->do("lock tables Cell LOW_PRIORITY write, RnlAlcatelBSC LOW_PRIORITY write");
	my @cols1 = qw/CellGlobalIdentity CellInstanceIdentifier OMC_ID IMPORTDATE/;
	my $sth1 = $dbh->prepare("select ".join(',',@cols1)." from Cell where CI is null");
	my $sth2 = $dbh->prepare("update Cell set CI=?,LAC=? where CellInstanceIdentifier=? and OMC_ID=? and IMPORTDATE=?");
	my %d = ();
	my %e = ();
	my %cell = ();
	$sth1->execute();
	print "Updating Cell,RnlAlcatelBSC columns..\n";
	while (my @row = $sth1->fetchrow_array) {
		@d{@cols1} = @row;
		my ($lac,$ci) = ($d{'CellGlobalIdentity'} =~ /lac\s(\d+).*?ci\s(\d+)/);
		next unless defined $ci;
		$sth2->execute($ci,$lac,@d{qw/CellInstanceIdentifier OMC_ID IMPORTDATE/});
	}
	my @cols2 = qw/RnlSupportingSector CellInstanceIdentifier OMC_ID IMPORTDATE/;
	my $sth3 = $dbh->prepare("select ".join(',',@cols2)." from Cell where BSC_ID is null and BTS_ID is null and SECTOR is null");
	my $sth4 = $dbh->prepare("update Cell set BSC_ID=?,BTS_ID=?,SECTOR=?,BSC_NAME=? where CellInstanceIdentifier=? and OMC_ID=? and IMPORTDATE=?");
	my $sth99 = $dbh->prepare("select UserLabel from RnlAlcatelBSC where RnlAlcatelBSCInstanceIdentifier=? and OMC_ID = ?");
	$sth3->execute();
	while (my @row = $sth3->fetchrow_array) {
		@d{@cols2} = @row;
		my ($bsc,$bts,$sector) = ($d{'RnlSupportingSector'} =~ /bsc\s(\d+).*?btsRdn\s(\d+).*?sectorRdn\s(\d+)/);
		$sth99->execute($bsc,$d{'OMC_ID'});
		my ($bscName) = $sth99->fetchrow_array;
		$bscName =~ s/\"//g;
		$sth4->execute($bsc,$bts,$sector,$bscName,@d{qw/CellInstanceIdentifier OMC_ID IMPORTDATE/});
	}
	$dbh->do("unlock tables");		
	#external OMC Cell updates
	print "Updating External OMC Cell columns..\n";
	my @cols0 = qw/CellGlobalIdentity ExternalOmcCellInstanceIdentifier OMC_ID IMPORTDATE/;
	my $sth8 = $dbh->prepare("select ".join(',',@cols0)." from ExternalOmcCell where CI is null");
	my $sth9 = $dbh->prepare("update ExternalOmcCell set CI=?,LAC=? where ExternalOmcCellInstanceIdentifier=? and OMC_ID=? and IMPORTDATE=?");
	$sth8->execute();
	while (my @row = $sth8->fetchrow_array) {
		@d{@cols0} = @row;
		my ($lac,$ci) = ($d{'CellGlobalIdentity'} =~ /lac\s(\d+).*?ci\s(\d+)/);
		$sth9->execute($ci,$lac,@d{qw/ExternalOmcCellInstanceIdentifier OMC_ID IMPORTDATE/});
	}
	#HoControl
	print "Updating HOControl columns..\n";
	my @cols6 = qw/HoControlInstanceIdentifier OMC_ID/;
	my @cols7 = qw/CI LAC/;
	my $sth11 = $dbh->prepare("select ".join(',',@cols6)." from HoControl where CI is null");
	my $sth12 = $dbh->prepare("select ".join(',',@cols7)." from Cell where CellInstanceIdentifier=? and OMC_ID=? limit 1");
	my $sth13 = $dbh->prepare("update HoControl set CI=?,LAC=? where HoControlInstanceIdentifier=? and OMC_ID=?");
	$sth11->execute();
	
	while (my @row = $sth11->fetchrow_array) {
		@d{@cols6} = @row;
		$sth12->execute(@d{@cols6});
		my ($ci,$lac) = $sth12->fetchrow_array;
		$sth13->execute($ci,$lac,@d{@cols6});
	}
	#Power Control
	print "Updating PowerControl columns..\n";
	my @cols8 = qw/RnlPowerControlInstanceIdentifier OMC_ID/;
	my $sth14 = $dbh->prepare("select ".join(',',@cols8)." from RnlPowerControl where CI is null");
	my $sth15 = $dbh->prepare("update RnlPowerControl set CI=?,LAC=? where RnlPowerControlInstanceIdentifier=? and OMC_ID=?");
	$sth14->execute();
	
	while (my @row = $sth14->fetchrow_array) {
		@d{@cols8} = @row;
		$sth12->execute(@d{@cols8});
		my ($ci,$lac) = $sth12->fetchrow_array;
		$sth15->execute($ci,$lac,@d{@cols8});
	}
	#BasebandTransceiver
	print "Updating RnlBasebandTransceiver columns..\n";
	my @cols9 = qw/RnlBasebandTransceiverInstanceIdentifier OMC_ID/;
	my $sth16 = $dbh->prepare("select ".join(',',@cols9)." from RnlBasebandTransceiver where CI is null");
	my $sth17 = $dbh->prepare("update RnlBasebandTransceiver set CI=?,LAC=? where RnlBasebandTransceiverInstanceIdentifier=? and OMC_ID=?");
	$sth16->execute();
	while (my @row = $sth16->fetchrow_array) {
		@d{@cols9} = @row;
		#{ cell { applicationID "A1353RA_84e729e2", cellRef 237}, bbtRdn 1}
		my ($id) = ($d{'RnlBasebandTransceiverInstanceIdentifier'} =~ /cell\s(\{.*?\})/);
		$sth12->execute($id,$d{'OMC_ID'});
		my ($ci,$lac) = $sth12->fetchrow_array;
		$sth17->execute($ci,$lac,@d{@cols9});
	}
	
	#adjacency updates
	print "Updating Adjacency columns..\n";
	my @cols3 = qw/AdjacencyInstanceIdentifier OMC_ID IMPORTDATE/;
	my @cols4 = qw/CI LAC CellInstanceIdentifier OMC_ID BCCHFrequency UserLabel/;
	my @cols5 = qw/CI LAC ExternalOmcCellInstanceIdentifier OMC_ID BCCHFrequency UserLabel/;
	my $sth5 = $dbh->prepare("select ".join(',',@cols3)." from Adjacency where CI is null");
	my $sth6 = $dbh->prepare("select ".join(',',@cols4)." from Cell");
	my $sth10 = $dbh->prepare("select ".join(',',@cols5)." from ExternalOmcCell");
	my $sth7 = $dbh->prepare("update Adjacency set CI=?,LAC=?,CELLNAME=?,BCCH=?,CI_TGT=?,LAC_TGT=?,CELLNAME_TGT=?,BCCH_TGT=? where AdjacencyInstanceIdentifier=? and OMC_ID=? and IMPORTDATE=?");
	
	$sth6->execute();
	while (my @row = $sth6->fetchrow_array) {
		@d{@cols4} = @row;
		@{$cell{$d{'CellInstanceIdentifier'}}}{@cols4} = @row;
	}
	$sth10->execute();
	while (my @row = $sth10->fetchrow_array) {
		@d{@cols5} = @row;
		@{$cell{$d{'ExternalOmcCellInstanceIdentifier'}}}{@cols5} = @row;
	}
	$sth5->execute();
	while (my @row = $sth5->fetchrow_array) {
		@d{@cols3} = @row;
		my ($cid,$tid) = ($d{'AdjacencyInstanceIdentifier'} =~ /cell\s(\{.*?\}).*?targetCell\s(\{.*?\})/);
		next if not exists($cell{$cid});
		next if not exists($cell{$tid});
		$sth7->execute(@{$cell{$cid}}{qw/CI LAC UserLabel BCCHFrequency/},@{$cell{$tid}}{qw/CI LAC UserLabel BCCHFrequency/},@d{qw/AdjacencyInstanceIdentifier OMC_ID IMPORTDATE/});	
	}
	
	#NbrTCHinner update
	my %def = ();
	Common::MySQL::get_table_definition($dbh,'Cell',\%def);
	if (exists $def{'NbrTCHinner'}) {
		print "Updating NbrTCHinner in Cell table..\n";
		my $sth18 = $dbh->prepare('select max(IMPORTDATE) from RnlBasebandTransceiver');
		$sth18->execute;
		my ($date) = $sth18->fetchrow_array;
		my @cols6 = qw/LAC CI NbrTCH RnlCellType/;
		my @cols7 = qw/ListOfRadioChannels ZONE_TYPE/;
		my $sth19 = $dbh->prepare('select '.join(',',@cols6).' from Cell where IMPORTDATE = ?');
		$sth19->execute($date);
		my $sth20 = $dbh->prepare('select '.join(',',@cols7).' from RnlBasebandTransceiver where CI = ? and LAC = ? and IMPORTDATE = ?');
		my $sth21 = $dbh->prepare('update Cell set NbrTCHinner=? where CI=? and LAC=? and IMPORTDATE=?');
		while (my @row = $sth19->fetchrow_array) {
			@d{@cols6} = @row;
			my $inner_total = 0;
			if ($d{'RnlCellType'} eq 'concentric') {
				$sth20->execute(@d{qw/CI LAC/},$date);
				while (my @b_row = $sth20->fetchrow_array) {
					@e{@cols7} = @b_row;
					my $tch_inner = 0;
					if ($e{'ZONE_TYPE'} eq 'inner') {
						$tch_inner = () = $e{'ListOfRadioChannels'} =~ /tCH/g;
						$inner_total += $tch_inner;
					} 
				}	
			}
			$sth21->execute($inner_total,@d{qw/CI LAC/},$date);
		}
	}
	
}

1;
