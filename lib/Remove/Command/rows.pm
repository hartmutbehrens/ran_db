package Remove::Command::rows;

=head1 NAME
Remove::Command::rows
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::Date;
use Common::Lock;
use Common::MySQL;
use Common::XML;
use Aggregate -command;
use Data::Dumper;
use File::Path qw(make_path);
use Time::Local qw(timelocal);

sub abstract {
	return "delete rows from a table using an xml template";
}

sub usage_desc {
	return "%c rows %o [ template ]";
}

sub opt_spec {
	my @which = (
		["hourly", "delete hourly data"],
		["daily", "delete daily data"],
		["weekly", "delete weekly data"],
	);
	return (
	[ "user|u=s",	"database user", { required => 1 }],
	[ "pass|x=s",	"database password", { required => 1 }],
	[ "host|h=s",	"database host IP address", { required => 1 }],
	[ "db|d=s",	"database name", { required => 1 }],
	[ "port|P=s",	"database port", { hidden => 1, default => 3306 }],
	[ "log|l=s", 	"log directory", { hidden => 1, default => '../deletelog'}],
	[ "time|t=s",	"level of deletion that should be run (specified in template)", { required => 1, hidden => 1, one_of => \@which}],
	[ "keep|k=s",	"override keep attribute in template file with custom value"],
	[ "step|s=s",	"only perform operations from specified step in the template"],
	[ "debug",	"generate debug output"],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;	
	$self->usage_error("At least one template file name is required") unless @$args;
	make_path($opt->{log}, { verbose => 1 });
	for (@$args) {
		die "The file $_ does not exist!\n" unless -e $_;
		my $config = Common::XML::read_xml($_);
		die "No config section found for $opt->{time} level in file $_ " unless exists $config->{delete}->{$opt->{time}};
	}
	
}

sub execute {
	my ($self, $opt, $args) = @_;
	my $dbh;
	my $connected = Common::MySQL::connect(\$dbh,@{$opt}{qw/user pass host port db/});
	unless ($connected) {
		die "Could not connect user \"$opt->{user}\" to database \"$opt->{db}\" on host \"$opt->{host}\". Please check that the provided credentials are correct and that the databse exists!\n";
	}
	for my $template (@$args) {
		my $lock = $template;
		$lock =~ s/\W//g;
		Common::Lock::get_lock('.'.$lock) or Common::Lock::bail('.'.$lock);
		my @tables = delete_rows($dbh,$template,$opt);
		optimize($dbh,\@tables);
	}
}

sub optimize {
	my ($dbh,$tables) = @_;
	foreach my $table(@$tables) {
		$dbh->do("optimize table $table");
	}
}


sub delete_rows {
	my ($dbh,$template,$opt) = @_;
	
	my $today = Common::Date::today();
	my $config = Common::XML::read_xml($template);
	
	my %tables;
	for my $step (sort {$a <=> $b} keys %{$config->{delete}->{$opt->{time}}->{step}}) {
		if ( ( defined $opt->{step} ) && ($step != $opt->{step}) ) {
			warn "Skipping step $step because command line option \"--step $opt->{step}\" was provided.\n";
			next;	
		}
		 
		my $sconfig = $config->{delete}->{$opt->{time}}->{step}->{$step};
		if (config_bad($sconfig,['from','identifier','using','keep'])) {
			warn "Skipped step $step because the instructions in the template are not complete.\n";
			next;	
		}
		my $count = 0;
		for my $day (get_dates($dbh,$sconfig,$opt)) {
			$count++;
			my $items = get_ids($dbh,$sconfig,$day);
			my $num_id = $#{$items} + 1;
			
			my $id = join('.',$day,$step,$sconfig->{from},$num_id);
			$id =~ s/\:/_/g;		#windows does not like ':' in a filename
			if ( (defined $opt->{skip}) && aggregation_done($opt,$id)) {
				warn "Skipping deletion step $step: from $sconfig->{from} for $day because it is already done according to log files in $opt->{log} and --skip command line option was provided.\n";
				next;
			}
			else {
				print "Starting deletion step $step: from $sconfig->{from}($num_id identifiers) for $day\n";	
			}
			my $dsql = make_delete_sql($sconfig,$dbh);
			my $sth = $dbh->prepare($dsql);
			for my $id (@$items) {
				print "@$id $day\n" if $opt->{debug};
				my $deld = $sth->execute(@$id,$day); 
			}
			log_done($opt,$id); 
			$tables{$sconfig->{from}}++;	
		}
		warn "No data matching the specified criteria was found in table $sconfig->{from} to delete\n" if $count == 0;
	}
	return keys %tables;
}

sub aggregation_done {
	my ($opt,$id) = @_;
	my $rv = -e $opt->{log}.'/'.$id ? 1 : 0;
	return $rv;
}

sub log_done {
	my ($opt,$name) = @_;
	open my $log ,'>>', $opt->{log}.'/'.$name;
	print $log join(' ', localtime(time)),"\n";
	close $log;
}



sub make_delete_sql {
	my ($sconfig,$todo,$dbh) = @_;
	my $where = join(' and ',map("$_ = ?", split(',',$sconfig->{identifier}),$sconfig->{using} ) );
	my $sql = "delete from $sconfig->{from} where $where";
	return $sql;
}

sub get_dates {
	my ($dbh,$sconfig,$opt) = @_;
	my (@group,$i);
	my $keep = $opt->{keep} // $sconfig->{keep};
	die "value for \"keep\" attribute not specified.\n" unless defined $keep;
	
	my $sth = $dbh->prepare("select distinct $sconfig->{using} from $sconfig->{from} order by $sconfig->{using} desc");
	$sth->execute();
	while (my @row = $sth->fetchrow_array) {
		$i++;
		push(@group,$row[0]) if $i > $keep;
	}
	return @group;
}

sub get_ids {
	my ($dbh,$sconfig,$groupval) = @_;
	my $rows = []; # cache for batches of rows
	my @elements;
	# get row from cache, or reload cache:
	my $sth = $dbh->prepare("select distinct $sconfig->{identifier} from $sconfig->{from} where $sconfig->{using} = ?");
	$sth->execute($groupval);
	while( my $row = ( shift(@$rows) || shift(@{$rows=$sth->fetchall_arrayref(undef,10000)||[]}) ) ) {
		push @elements, $row;
	}
	return \@elements;
}

sub config_bad {
	my ($config,$cols) = @_;
	my $rv = 0;
	for (@$cols) {
		$rv = 1 unless exists $config->{$_};
	}
	return $rv;
}

1;
