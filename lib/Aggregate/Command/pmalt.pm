package Aggregate::Command::pmalt;

=head1 NAME
Aggregate::Command::pmalt;
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
	return "aggregate various pm tables using an xml defined aggregation template (alternative)";
}

sub usage_desc {
	return "%c pmalt %o [ template ]";
}

sub opt_spec {
	my @which = (
		["hourly", "hourly aggregation"],
		["daily", "daily aggregation"],
		["weekly", "daily aggregation"],
	);
	return (
	[ "user|u=s",	"database user", { required => 1 }],
	[ "pass|x=s",	"database password", { required => 1 }],
	[ "host|h=s",	"database host IP address", { required => 1 }],
	[ "db|d=s",	"database name", { required => 1 }],
	[ "port|P=s",	"database port", { hidden => 1, default => 3306 }],
	[ "log|l=s", 	"log directory", { hidden => 1, default => '../aggregationlog'}],
	[ "time|t=s",	"level of aggregation that should be run (specified in aggregation template)", { required => 1, hidden => 1, one_of => \@which}],
	[ "limit|l=s",	"optionally increase/decrease amount of days to use in aggregation operation"],
	[ "step|s=s",	"only perform operations from specified step in aggregation template"],
	[ "skip",	"skip aggregation steps that have already been completed according to log files"],
	[ "driver=s",	"database driver (default mysql)", { default => "mysql" }],
	[ "debug",	"generate debug output"],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;	
	$self->usage_error("At least one aggregation template file name is required") unless @$args;
	make_path($opt->{log}, { verbose => 1 });
	for (@$args) {
		die "The file $_ does not exist!\n" unless -e $_;	
	}
}

sub execute {
	my ($self, $opt, $args) = @_;
	my $conn = Common::MySQL::get_connection(@{$opt}{qw/user pass host port db driver/});
	die "Could not get a database connection\n" unless defined $conn;
	my $dbh = $conn->dbh;
	for my $template (@$args) {
		my $lock = $template;
		$lock =~ s/\W//g;
		Common::Lock::get_lock('.'.$lock) or Common::Lock::bail('.'.$lock);
		aggregate($dbh,$template,$opt);
	}
}

#retrieve instructions from xml on hoe to aggregate counters: e.g. sum, avg, min, max
sub instructions {
	my ($config,$opt) = @_;
	my %todo;
	
	for my $counter (keys %$config) {
		if (config_bad($config->{$counter},['how','do'])) {
			warn "Skipping aggregation for counter $counter because the instructions in the template are not complete.\n";
			next;
		}
		 
		my $how = $config->{$counter}->{how};
		foreach my $do ( split(';',$config->{$counter}->{do}) ) {
			my ($time,$step) = split(':',$do);	#e.g. daily:1
			next unless $time eq $opt->{time};
			if ($step =~ /(\d+)-(\d+)/) {	#allow for syntax like daily:1-3
				$todo{$_}{$counter} = $how for ($1..$2);
			}
			else {
				$todo{$_}{$counter} = $how for split(',',$step);	#allow for syntax like daily:1,2,3 - in case same ocunter name exists in multiple tables
			}
		}
	}
	return \%todo;
}

sub aggregate {
	my ($dbh,$template,$opt) = @_;
	
	my $today = Common::Date::today();
	my $config = Common::XML::read_xml($template);
	my $todo = instructions($config->{aggregate}->{fields}->{field},$opt);

	unless (exists $config->{aggregate}->{$opt->{time}}) {
		warn "No instructions found in template for $opt->{time} aggregation. \n";
		return;
	}
	
	for my $step (sort {$a <=> $b} keys %{$config->{aggregate}->{$opt->{time}}->{step}}) {
		if ( ( defined $opt->{step} ) && ($step != $opt->{step}) ) {
			warn "Skipping step $step because command line option \"--step $opt->{step}\" was provided.\n";
			next;	
		}
		 
		my $sconfig = $config->{aggregate}->{$opt->{time}}->{step}->{$step};
		if (config_bad($sconfig,['from','to','identifier','groupfrom','groupto','limit'])) {
			warn "Skipped step $step because the instructions in the template are not complete.\n";
			next;	
		}
		my $count = 0;
		for my $day (get_dates($dbh,$sconfig,$opt)) {
			$count++;
			my $items = get_ids($dbh,$sconfig,$day);
			my ($num,$num_id) = (scalar keys %{$todo->{$step}},$#{$items} + 1);
			
			
			my ($success,$id) = (0,join('.',$day,$step,$sconfig->{from},$sconfig->{to},$num_id));
			$id =~ s/\:/_/g;		#windows does not like ':' in a filename
			if ( (defined $opt->{skip}) && aggregation_done($opt,$id)) {
				warn "Skipping aggregation step $step: from $sconfig->{from} to $sconfig->{to} for $day because it is already done according to log files in $opt->{log} and --skip command line option was provided.\n";
				next;
			}
			else {
				print "Starting aggregation step $step: from $sconfig->{from} to $sconfig->{to} ($num counters, $num_id identifiers) for $day\n";	
			}
			my ($select,$cols) = make_select_sql($sconfig,$todo->{$step},$dbh);
			my $sth = $dbh->prepare($select);
			for my $id (@$items) {
				print "@$id $day\n" if $opt->{debug};
				$sth->execute(@$id,$day);
				my @row = $sth->fetchrow_array;
				$success++ if update_db( $dbh, $sconfig, [split(',',$sconfig->{identifier}),@$cols,$sconfig->{groupto}], [@$id,@row,$day] );
			}
			log_done($opt,$id) if ($success == $num_id); 	
		}
		warn "No data found in table $sconfig->{from} for aggregation step $step\n" if $count == 0;
	}
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


sub update_db {
	my ($dbh,$sconfig,$cols,$vals) = @_;
	#print $cols,"\n";
	my @values = map( defined $_ ? $_ : 'NULL', @$vals);
	my $replace = 'replace into '.$sconfig->{to}.' ('.join(',',map('`'.$_.'`',@$cols)).') values ('.join(',',map($_ eq 'NULL' ? 'NULL' :  '\''.$_.'\'',@values)).')';
	if ($dbh->do($replace)) {
		return 1;
	}
	else {
		die $replace;
		return 0;
	} 
}


sub make_select_sql {
	my ($sconfig,$todo,$dbh) = @_;
	my (@what,%from,%to,@cols);
	Common::MySQL::get_table_definition($dbh,$sconfig->{from},\%from);
	Common::MySQL::get_table_definition($dbh,$sconfig->{to},\%to);
	my $where = join(' and ',map("$_ = ?", split(',',$sconfig->{identifier}),$sconfig->{groupfrom} ) );
	for my $counter (keys %$todo) {
		if ( (exists $from{$counter}) && (exists $to{$counter}) ) {
			my $how = $todo->{$counter};	#sum, min, max, avg or explicit definition eg counter1/counter2
			my $what = ($how =~ /[\+|\-|\*|\/]/) ? $how : $how.'(`'.$counter.'`)'; 
			push @what, $what;
			push @cols, $counter;	
		}
		else {
			warn "Counter $counter will be skipped from aggregation because it is not present in either $sconfig->{from} or $sconfig->{to}.\n";
		}
	}
	my $sql = "select ".join(',',@what)." from $sconfig->{from} where $where";
	return ($sql,\@cols);
}

sub get_dates {
	my ($dbh,$sconfig,$opt) = @_;
	my @group;
	my $limit = defined $opt->{limit} ? $opt->{limit} : $sconfig->{limit};
	warn "Overriding limit with command line specified --limit value of \"$opt->{limit}\".\n" if defined $opt->{limit};
	
	my $sth = $dbh->prepare("select distinct $sconfig->{groupfrom} from $sconfig->{from} order by $sconfig->{groupfrom} desc limit $limit");
	$sth->execute();
	while (my @row = $sth->fetchrow_array) {
		push(@group,$row[0]);
	}
	return @group;
}

sub get_ids {
	my ($dbh,$sconfig,$groupval) = @_;
	my $rows = []; # cache for batches of rows
	my @elements;
	# get row from cache, or reload cache:
	my $sth = $dbh->prepare("select distinct $sconfig->{identifier} from $sconfig->{from} where $sconfig->{groupfrom} = ?");
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
