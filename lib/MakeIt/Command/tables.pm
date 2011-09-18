package MakeIt::Command::tables;

=head1 NAME
MakeIt::Command::tables;
=cut
#pragmas
use strict;
use warnings;

#modules
use Common::MySQL;
use Common::XML;
use MakeIt -command;

sub abstract {
	return "make database tables from xml templates.";
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
	[ "drop|D",	"Drop any existing tables, if they exist"],
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
		make_table($mk,$dbh,$opt->{drop});	
	}
}

sub make_table {
	my ($mak,$dbh,$drop,$onlythis) = @_;
	my $rv = 0;
	foreach my $t (sort keys %{$mak->{'table'}}) {
		next if (defined($onlythis) && ($t ne $onlythis));
		unless (exists($mak->{'table'}->{$t}->{'field'})) {
			warn "$t make description is not properly formatted as it does not contain any column information. Please add this !\n";
			return $rv;
		}
		unless (exists($mak->{'table'}->{$t}->{'index'})) {
			warn "$t make description is not properly formatted as it does not contain any index information. Please add this !\n";
			return $rv;
		}
		
		print "Creating table $t ...\n";
		my @existing = @{$dbh->selectcol_arrayref("show tables")};
		if (grep {/^$t$/i} @existing) {
			if ($drop) {
				print "Dropping existing table $t (-D command line option was provided)\n";
				$dbh->do("drop table $t") || die($dbh->errstr);	
			}
			else {
				warn "The table $t already exists. Use the -D command line option to drop the existing table and recreate it.\n";
				return 0;
			}
		}
		
		my @cols = sort keys %{$mak->{'table'}->{$t}->{'field'}};
		#my %names = map {$_ => exists($mak->{'table'}->{$t}->{'field'}->{$_}->{'table-alias'})? $mak->{'table'}->{$t}->{'field'}->{$_}->{'table-alias'} : $_ } @cols;
		my %names;
		my %cols = map { $_ => 1} @cols;
		for (@cols) {
			if (exists $mak->{'table'}->{$t}->{'field'}->{$_}->{'table-alias'}) {
				my $alias = $mak->{'table'}->{$t}->{'field'}->{$_}->{'table-alias'};
				delete $cols{$_} if exists $cols{$alias};	#remove duplicates that could result from 'table-alias', see nodeb localcellgroup table template;
				$names{$_} = $alias; 
			}
			else {
				$names{$_} = $_;
			}
		}	
		
		my @idx = sort keys %{$mak->{'table'}->{$t}->{'index'}};
		my %unique = map {$_ => (lc(${$mak->{'table'}->{$t}->{'index'}->{$_}->{'unique'}}[0]) eq 'yes') ? 'UNIQUE ' : ''} @idx;
		my $idx = join(', ',map($unique{$_}.'INDEX '.$_.' ('.${$mak->{'table'}->{$t}->{'index'}->{$_}->{'order'}}[0].')',@idx));
		my $sql = 'create table '.$t.' ('.join(',',map('`'.$names{$_}.'` '.$mak->{'table'}->{$t}->{'field'}->{$_}->{'type'},sort keys %cols)).', '.$idx.')';
		
		my $sth = $dbh->prepare($sql)	;
		$sth->execute();
		$rv = 1;
	}
}


1;
