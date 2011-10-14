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
use Common::XML;
use Aggregate -command;
use Data::Dumper;
use File::Path qw(make_path);

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
	my $dbh;
	my $connected = Common::MySQL::connect(\$dbh,@{$opt}{qw/user pass host port db/});
	unless ($connected) {
		die "Could not connect user \"$opt->{user}\" to database \"$opt->{db}\" on host \"$opt->{host}\". Please check that the provided credentials are correct and that the databse exists!\n";
	}
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
		for my $day (get_dates($dbh,$sconfig)) {
			$count++;
			my $items = get_ids($dbh,$sconfig,$day);
			my $num = scalar keys %{$todo->{$step}};
			print "Starting aggregation step $step: from $sconfig->{from} to $sconfig->{to} ($num counters, ".($#{$items}+1)." identifiers) for $day\n";
			
			my $select = make_select_sql($sconfig,$todo->{$step});
			my $sth = $dbh->prepare($select);
			for my $id (@$items) {
				print "@$id $day\n" if $opt->{debug};
				$sth->execute(@$id,$day);
				my @row = $sth->fetchrow_array;
				update_db( $dbh, $sconfig, [split(',',$sconfig->{identifier}),keys %{$todo->{$step}},$sconfig->{groupto}], [@$id,@row,$day] );
			} 	
		}
		warn "No data found in table $sconfig->{from} for aggregation step $step\n" if $count == 0;
	}
}


sub update_db {
	my ($dbh,$sconfig,$cols,$vals) = @_;
	#print $cols,"\n";
	my @values = map( defined $_ ? $_ : 'NULL', @$vals);
	my $replace = 'replace into '.$sconfig->{to}.' ('.join(',',map('`'.$_.'`',@$cols)).') values ('.join(',',map($_ eq 'NULL' ? 'NULL' :  '\''.$_.'\'',@values)).')';
	$dbh->do($replace) || die $replace;
}


sub make_select_sql {
	my ($sconfig,$todo) = @_;
	my @what;
	my $where = join(' and ',map("$_ = ?", split(',',$sconfig->{identifier}),$sconfig->{groupfrom} ) );
	for my $counter (keys %$todo) {
		my $what = ($todo->{$counter} =~ /[\+|\-|\*|\/]/) ? $todo->{$counter} : $todo->{$counter}.'(`'.$counter.'`)';
		push @what, $what;
	}
	my $sql = "select ".join(',',@what)." from $sconfig->{from} where $where";
	return $sql;
}

sub get_dates {
	my ($dbh,$sconfig) = @_;
	my @group;
	my $sth = $dbh->prepare("select distinct $sconfig->{groupfrom} from $sconfig->{from} order by $sconfig->{groupfrom} desc limit $sconfig->{limit}");
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
