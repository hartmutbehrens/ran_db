package Modify::Command::tables;

=head1 NAME
Modify::Command::tables;
=cut
#pragmas
use strict;
use warnings;

#modules
use Common::MakeIt;
use Common::MySQL;
use Common::XML;
use MakeIt -command;

sub abstract {
	return "modify database tables from xml templates.";
}

sub usage_desc {
	return "%c tables %o [ filename(s) ]";
}

sub opt_spec {
	return (
	[ "user|u=s",	"database user", { required => 1 }],
	[ "pass|x=s",	"database password", { required => 1 }],
	[ "host|h=s",	"database host IP address", { required => 1 }],
	[ "db|d=s",	"database name in which tables will be created", { required => 1 }],
	[ "port|P=s",	"database port", { hidden => 1, default => 3306 }],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
	$self->usage_error("At least one table template file name is required") unless @$args;
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
		my $mk = Common::XML::read_xml($template);
		modify_table($mk,$dbh);	
	}
}

sub modify_table {
	my ($make,$dbh) = @_;
	foreach my $t (sort keys %{$make->{'table'}}) {
		my @mcols = sort keys %{$make->{'table'}->{$t}->{'field'}};
		my %names = map {exists($make->{'table'}->{$t}->{'field'}->{$_}->{'table-alias'})? $make->{'table'}->{$t}->{'field'}->{$_}->{'table-alias'} : $_ => $_} @mcols;
		my @fields = map(exists($make->{'table'}->{$t}->{'field'}->{$_}->{'table-alias'})? $make->{'table'}->{$t}->{'field'}->{$_}->{'table-alias'} : $_ ,@mcols);
		my %now = ();
		my %idx = ();
		my ($hasTable) = Common::MySQL::get_table_definition($dbh,$t,\%now,\%idx);
	
		if ($hasTable) {
			#first add new fields
			printf "Checking for new fields that should be added to $t ...\n";
			my $previous = undef;
			foreach (@fields) {
				unless (exists($now{$_})) {
					my $name = $names{$_};
					printf "\tAdding field $_ to $t\n";
					if (defined($previous)) {
						my $sql = "ALTER TABLE $t ADD `$_` ".$make->{'table'}->{$t}->{'field'}->{$name}->{'type'}." AFTER `$previous`\n";
						$dbh->do($sql) || die($dbh->errstr.": Query is $sql");
					}
					else {
						my $sql = "ALTER TABLE $t ADD $_ ".$make->{'table'}->{$t}->{'field'}->{$name}->{'type'}." FIRST\n";
						$dbh->do($sql) || die($dbh->errstr.": Query is $sql");
					}
				}
				$previous = $_;
			}
			#now drop fields that were removed
			printf "Checking for existing fields that should be removed from $t ...\n";
			foreach (keys %now) {
				my $name = $names{$_};
				unless (defined($make->{'table'}->{$t}->{'field'}->{$name})) {
					printf "\tRemoving field $_ from $t\n";
					my $sql = "ALTER TABLE $t DROP `$_`\n";
					$dbh->do($sql) || die($dbh->errstr.": Query is $sql");
				}
			}
			printf "Checking indexes of $t...\n";
			foreach my $indx (keys %{$make->{'table'}->{$t}->{'index'}}) {
				my $hasMatch = 0;
				foreach my $ix (keys %idx) {
					my (undef,$unique) = split(';',$ix);
					my $idx = join(',',@{$idx{$ix}});
					my $tblIdx = ${$make->{'table'}->{$t}->{'index'}->{$indx}->{'order'}}[0];
					#print "c: $idx vs $tblIdx : $unique : ${$make->{'table'}->{$t}->{'index'}->{$indx}->{'unique'}}[0]\n";
					$hasMatch = 1 if ((lc(${$make->{'table'}->{$t}->{'index'}->{$indx}->{'unique'}}[0]) eq $unique) && ($tblIdx eq $idx));
				}
				unless ($hasMatch) {
					printf "\tAdding index $indx to $t\n";
					my $unq = lc(${$make->{'table'}->{$t}->{'index'}->{$indx}->{'unique'}}[0]) eq 'yes' ? 'UNIQUE' :'';
					my $sql = "ALTER TABLE $t ADD $unq INDEX $indx (".${$make->{'table'}->{$t}->{'index'}->{$indx}->{'order'}}[0].")";
					$dbh->do($sql) || die($dbh->errstr.": Query is $sql");
				}
			}
		
		}
		else {	#table does not exist, create it !
			printf "Table $t does not exist .. creating it !\n";
			Common::MakeIt::make($make,$dbh,$t);
		}
	}
}


1;
