package Aggregate::Command::CTN;

=head1 NAME
Aggregate::Command::CTN;
=cut
#pragmas
use strict;
use warnings;

#modules
use Common::Lock;
use Common::MySQL;
use Aggregate -command;


sub abstract {
	return "aggregate CTN data from hourly to daily";
}

sub usage_desc {
	return "%c CTN %o";
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
	my $lock = '.'.$opt->{db}.'CTN';
	Common::Lock::get_lock($lock) or Common::Lock::bail($lock);
	do_CTN($dbh,'TRACE_CTN','TRACE_CTN_D','DATE(eventTime)',2,'event');
}



sub do_CTN {
	my ($dbh,$from_table,$to_table,$date_group_expr,$interval,$event_col) = @_;
	print "Aggregating CTN from $from_table to $to_table ($interval days)...\n";
	my @cols = (qw/NETWORK Name OMC_ID/,$event_col,$date_group_expr, qw/primarycell targetcell detectedcell newprimarycell preprimarycell targetcell_gsmcellinfo_bcch targetcell_gsmcellinfo_cellid initialaccess_initaccesscell/);
	my @baseIx = @cols[0..4];
	my @nameIx = qw/NETWORK Name OMC_ID eventName eventTime/;
	my @groupIx = @cols[5..$#cols];
	my $evRef = $dbh->selectcol_arrayref('select distinct '.$event_col.' from '.$from_table.' where eventTime > DATE_SUB(now(), interval '.$interval.' day)');
	my $sth1 = $dbh->prepare('select '.join(',',@cols).' from '.$from_table.' where '.$event_col.'=? and eventTime > DATE_SUB(now(), interval '.$interval.' day)');
	for my $ev (@$evRef) {
		print "Retrieving data for $ev event from $from_table..\n";
		$sth1->execute($ev);
		my $rows = []; # cache for batches of rows
		my (%d,%result);
		while( my $row = ( shift(@$rows) || shift(@{$rows=$sth1->fetchall_arrayref(undef,10_000)||[]}) )  ) { # get row from cache, or reload cache:
		 	@d{@cols} = @$row;
		 	if ($d{'Name'} =~ /RNC/) {
		 		($d{'Name'}) = ($d{'Name'} =~ /RNC\W(.*?)$/);
		 	}
		 	my @addIx = grep defined $d{$_}, @groupIx;
		 	my $id = join(',',@nameIx,@addIx).'='.join(',',@d{@baseIx,@addIx});
		 	$result{$id}++;    
		}
		print "Populating $to_table with $ev event data...\n";
		foreach my $id (keys %result) {
			my ($cols,$vals) = split('=',$id);
			my @cols = (split(',',$cols),'eventCount');
			my @vals = (split(',',$vals),$result{$id});
			my $replace = 'replace into '.$to_table.' ('.join(',',map('`'.$_.'`',@cols)).') values ('.join(',',map('\''.$_.'\'',@vals)).');';
			$dbh->do($replace) || die $replace,"\n";
			
		}
	}
}



1;