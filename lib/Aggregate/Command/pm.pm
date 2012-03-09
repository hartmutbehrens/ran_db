package Aggregate::Command::pm;

=head1 NAME
Aggregate::Command::pm;
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::Lock;
use Common::XML;
use Aggregate -command;

sub abstract {
	return "aggregate various pm tables using an xml defined aggregation template";
}

sub usage_desc {
	return "%c pm %o [ template ]";
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
	[ "time|t=s",	"time level of aggregation that should be run", { required => 1, hidden => 1, one_of => \@which}],
	[ "limit|l=s",	"optionally increase/decrease amount of days to use in aggregation operation"],
	[ "driver=s",	"database driver (default mysql)", { default => "mysql" }],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;	
	$self->usage_error("At least one aggregation template file name is required") unless @$args;
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
		do_aggregation($dbh,$template,$opt->{time},$opt->{limit});
	}
}

sub do_aggregation {
	my ($dbh,$template,$atime,$uplimit) = @_;
	
	my ($config) = Common::XML::read_xml($template);
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
	
	if (%todo) {
		foreach my $how (keys %todo) {
		#foreach my $how (qw/sum/) {
			foreach my $step (sort {$a<=>$b} keys %{$todo{$how}}) {
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
					$sth = $dbh->prepare($need);
					$sth->execute($day);
					while (my @row = $sth->fetchrow_array) {
						@d{@cols,@grpT} = map(defined($_)?$_:0,@row);
						my $idx = join(',',@d{@grpT});
						if (exists($have{$to}{$idx})) {
							my $update = 'update '.$to.' set '.join(',',map('`'.$_.'`='.($d{$_} || 0),@cols)).' where '.join(' and ',map($_.'=\''.$d{$_}.'\'',@grpT));
							#print "update: $update\n";
							$dbh->do($update) || die $update;
							$seen{$to}{$day} = 1;
							#print "$update\n";
						}
						else {
							my $replace = 'replace into '.$to.' ('.join(',',map('`'.$_.'`',@grpT,@cols)).') values ('.join(',',map('\''.$_.'\'',@d{@grpT,@cols})).')';
							#print "replace: $replace\n";
							$dbh->do($replace) || die $replace;
							#print "$replace\n";
						}
					}
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
