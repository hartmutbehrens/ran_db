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
	[ "log|l=s", 	"Log directory", { hidden => 1, default => '../aggregationlog'}],
	[ "time|t=s",	"level of aggregation that should be run (specified in aggregation template)", { required => 1, hidden => 1, one_of => \@which}],
	[ "limit|l=s",	"optionally increase/decrease amount of days to use in aggregation operation"],
	[ "step|s=s",	"only perform operations from specified step in aggregation template"],
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
				$todo{$_}{$counter}{$how} = 1 for ($1..$2);
			}
			else {
				$todo{$_}{$counter}{$how} = 1 for split(',',$step);	#allow for syntax like daily:1,2,3 - in case same ocunter name exists in multiple tables
			}
		}
	}
	return \%todo;
}

sub aggregate {
	my ($dbh,$template,$opt) = @_;
	my $today = Common::Date::today();
	my $config = Common::XML::read_xml($template);
	my @required = qw/from to identifier groupfrom groupto limit/;
	my $todo = instructions($config->{aggregate}->{fields}->{field},$opt);
	
	for my $step (sort {$a <=> $b} keys %{$config->{aggregate}->{$opt->{time}}->{step}}) {
		my $sconfig = $config->{aggregate}->{$opt->{time}}->{step}->{$step};
		if (config_bad($sconfig,\@required)) {
			warn "Skipped step $step because the instructions in the template are not complete.\n";
			next;	
		}
		my $num = scalar keys %{$todo->{$step}};
		
		my $dates = get_dates($dbh,$sconfig->{from},$sconfig->{groupfrom},$sconfig->{limit});
		print "$sconfig->{from} has data for @$dates\n";
		
		for my $day (@$dates) {
			print "Starting aggregation step $step: from $sconfig->{from} to $sconfig->{to} ($num counters) for $day\n";
			my $elements = get_elements($dbh,$sconfig->{from},$sconfig->{identifier},$sconfig->{groupfrom},$day);
			for my $id (@$elements) {
				print "element: @$id \n";
			}	
		}
		
		
	}
}

sub get_dates {
	my ($dbh,$table,$group_col,$limit) = @_;
	my @group;
	my $sth = $dbh->prepare("select distinct $group_col from $table order by $group_col desc limit $limit");
	$sth->execute();
	while (my @row = $sth->fetchrow_array) {
		push(@group,$row[0]);
	}
	return \@group;
}

sub get_elements {
	my ($dbh,$table,$identifier,$groupcol,$day) = @_;
	my $rows = []; # cache for batches of rows
	my @elements;
	# get row from cache, or reload cache:
	my $sth = $dbh->prepare("select distinct $identifier from $table where $groupcol = ?");
	$sth->execute($day);
	while( my $row = ( shift(@$rows) || shift(@{$rows=$sth->fetchall_arrayref(undef,10_000)||[]}) ) ) {
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

sub get_items {
	my ($dbh,$table,$col) = @_;
	my $sth = $dbh->prepare('select distinct '.$col.' from '.$table);
	$sth->execute;
	
} 


sub do_aggregation {
	my ($dbh,$template,$opt) = @_;
	my $atime = $opt->{time};
	my $uplimit = $opt->{limit};
	my $config = Common::XML::read_xml($template);
	my %todo = ();
	my %need = ();
	my %have = ();
	my %seen = ();
	my %cmap = ();
	
	foreach my $col (keys %{$config->{'aggregate'}->{'fields'}->{'field'}}) {
		my @op = split(';',$config->{'aggregate'}->{'fields'}->{'field'}->{$col}->{'do'});
		my $how = defined($config->{'aggregate'}->{'fields'}->{'field'}->{$col}->{$atime}) ? $config->{'aggregate'}->{'fields'}->{'field'}->{$col}->{$atime} : $config->{'aggregate'}->{'fields'}->{'field'}->{$col}->{'how'};
		foreach my $op (@op) {
			my ($type,$which) = split(':',$op);
			next unless ($type eq $atime);
			if ($which =~ /(\d+)-(\d+)/) {
				for ($1..$2) {
					$todo{$how}{$_}{$col} = 1;
				}
			}
			else {
				my @t = split(',',$which);
				for (@t) {
					$todo{$how}{$_}{$col} = 1;
				}
			}
		}
	}
	#print Dumper(\%todo);
	#exit;
	if (%todo) {
		foreach my $how (keys %todo) {
		#foreach my $how (qw/sum/) {
			foreach my $step (sort {$a<=>$b} keys %{$todo{$how}}) {
			if ( (exists $opt->{step}) && ($step != $opt->{step}) ) {
				warn "Skipping operations for step $step because command line option --step with value \"$opt->{step}\" was provided.\n";
				next;
			}
			#foreach my $step (7..8) {
				
				next unless exists $config->{'aggregate'}->{$atime}->{'step'}->{$step};
				my ($from,$to,$groupFrom,$groupTo,$limitTo,$limitFrom,$limit) = @{$config->{'aggregate'}->{$atime}->{'step'}->{$step}}{qw/from to groupfrom groupto limitto limitfrom limit/};
				if ($uplimit) {
					warn "User selected limit of \"$uplimit\" will override limit of \"$limit\" defined in template.\n";
					$limit = $uplimit;
				}
				$groupTo = $groupFrom if (lc($groupTo) eq 'groupfrom');
				my @dates = ();
				print "Checking latest dates in $from ..";
				my $dates = 'select distinct '.$limitFrom.' from '.$from.' order by '.$limitFrom.' desc limit '.$limit;
				my $sth = $dbh->prepare($dates);
				$sth->execute();
				while (my @row = $sth->fetchrow_array) {
					#print "$row[0]..";
					push(@dates,$row[0]);
				}
				#if (defined $args{s}) {
				#	my $ix = int $args{s};
				#	@dates = $dates[$ix];
				#}
				print "found: @dates\n";
				foreach my $day (@dates) {
					#see which data needs to be aggregated
					print "Aggregating $from to $to for $day.\n";
					my @cols = sort keys %{$todo{$how}{$step}};
					if ($how =~ /[\+|\-|\*|\/]/) {
						@{$cmap{$from}}{@cols} = map($how,@cols);
					}
					else {
						@{$cmap{$from}}{@cols} = map($how.'(`'.$_.'`)',@cols);
					}
					@{$cmap{$to}}{@cols} = map('`'.$_.'`',@cols);
					print Dumper(\%cmap);
					exit;
					my @grpT = split(',',$groupTo);
					my @grpF = split(',',$groupFrom);
					unless ($#grpT == $#grpF) {
						die "Aggregation from $from to $to not possible because number of grouping elements specified in $template are not equal(groupfrom has ".($#grpT+1)." elements, groupto has ".($#grpF+1).").\n";
						next;
					}
					
					my %d = ();
					my $need = 'select '.join(',',@{$cmap{$from}}{@cols}).','.$groupFrom.' from '.$from.' where '.$limitFrom.'=? group by '.$groupFrom;
					#my $have = 'select '.join(',',@{$cmap{$to}}{@cols}).','.$groupTo.' from '.$to.' where '.$limitTo.'=? group by '.$groupTo;
					unless (exists $seen{$to}{$day}) {
						my $have = 'select '.$groupTo.' from '.$to.' where '.$limitTo.'=? group by '.$groupTo;
						$sth = $dbh->prepare($have);
						$sth->execute($day);
						
						while (my @row = $sth->fetchrow_array) {
							@d{@grpT} = @row;
							$have{$to}{join(',',map(defined($_)?$_:'',@d{@grpT}))} = 1;
						}
						%d = ();
					}
					
					#check what is available and aggregate items as required
					print $need,"\n";
					#$sth = $dbh->prepare($need);
					#$sth->execute($day);
					#while (my @row = $sth->fetchrow_array) {
					#	@d{@cols,@grpT} = map(defined($_)?$_:0,@row);
					#	my $idx = join(',',@d{@grpT});
					#	if (exists($have{$to}{$idx})) {
					#		my $update = 'update '.$to.' set '.join(',',map('`'.$_.'`='.($d{$_} || 0),@cols)).' where '.join(' and ',map($_.'=\''.$d{$_}.'\'',@grpT));
							#print "update: $update\n";
							#$dbh->do($update) || die $update;
					#		$seen{$to}{$day} = 1;
							#print "$update\n";
					#	}
					#	else {
					#		my $replace = 'replace into '.$to.' ('.join(',',map('`'.$_.'`',@grpT,@cols)).') values ('.join(',',map('\''.$_.'\'',@d{@grpT,@cols})).')';
							#print "replace: $replace\n";
							#$dbh->do($replace) || die $replace;
							#print "$replace\n";
					#	}
					#}
					%cmap = ();
				}
			}
		}
	}
	else {
		print "There is nothing to do for \"$atime\" aggregation - perhaps no aggregation operation was specified in $template?\n";
	}
}

1;
