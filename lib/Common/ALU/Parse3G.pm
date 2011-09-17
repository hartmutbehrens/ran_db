package Common::ALU::Parse3G;

=head1 NAME
Common::ALU::Parse3G;
=cut

#pragmas
use strict;
use warnings;
#modules
use Common::Date;
use File::Path qw(make_path);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use XML::Bare;

sub make_counter_mapping {
	my $table_xml = shift;
	my $bare = new XML::Bare( file => $table_xml );
  	my $xml = $bare->parse();
  	my %table_map;
  	my %counter_map;
  	
  	foreach my $table (@{$xml->{tables}->{table}}) {
  		next unless exists $table->{loadedfromcsv} && $table->{loadedfromcsv}->{value} eq 'yes';
  		my ($name,$gran,$index) = map($_->{value} , map($table->{$_} , qw/name granularity idx/) );
   
  		my @cols = map($_->{value} , map($_->{name},@{$table->{field}}) );
  		@{$counter_map{$gran}{$index}}{@cols} = @cols;
  		@{$table_map{$gran}{$index}}{@cols} = map($name,@cols);
		
		#get the alias, if it exists
		foreach my $field (@{$table->{field}}) {
			next unless exists $field->{'table-alias'};
			my $original = $field->{name}->{value};
			my $alias = $field->{'table-alias'}->{value};
			$counter_map{$gran}{$index}{$original} = $alias;
		}  		
  	}
  	
  	return (\%table_map,\%counter_map); 	
}

sub iterate {
	my $wref = shift;
	return $wref if ref $wref eq 'HASH';
	return @{$wref} if ref $wref eq 'ARRAY';
}

sub parse_3GPM {
	my ($f,$templatedir,$pmtype) = @_;
	print "Parsing: $f\n";
	my %info = ();
	my %pm = ();
	my %counters = ();
	 
	my $tmp_dir = '../tmp/';
	make_path($tmp_dir, { verbose => 1 }) unless -e $tmp_dir;
	
	my @file = split('/',$f);
	my $outfile = $file[$#file].'.xml';
	gunzip $f => $tmp_dir.$outfile unless -e $outfile;
	
	my $bare = new XML::Bare( file => $tmp_dir.$outfile );
	my $xml = $bare->parse();
	
	my $version = $xml->{mdc}->{md}->{neid}->{nesw}->{value};
	my $rnc = $xml->{mdc}->{md}->{neid}->{neun}->{value};
	$info{NAME} = $rnc;
	
	print "3G PM version: ",$version,"\n";
	#create the mapping of counter name to mysql column name - necessary because MySQL has a limit on the length of the column name and some VS counter names break the limit
  	my $table_file = $templatedir.'/table.'.$pmtype.'.'.$version.'.xml';
  	unless ((-f $table_file) && (-s $table_file)) {
		print "The file $f with version $version cannot be decoded because no table file could be found (looking for $table_file) !\n";
		return 0;
	}
  	my ($table_map,$counter_map) = make_counter_mapping($table_file);
	
	foreach my $mi( iterate($xml->{mdc}->{md}->{mi}) )  {
		my @keys = keys %{$mi};
		my $gran = $mi->{gp}->{value};
		next if $gran == 900;
		my ($sdate,$stime,$edate,$etime) = Common::Date::make_date_time($mi->{mts}->{value},$gran);
		@info{qw/STARTDATE STARTTIME ENDDATE ENDTIME NETWORK SDATETIME GRANULARITY/} = ($sdate,$stime,$edate,$etime,'ZA',$sdate.' '.$stime,$gran);
		my @counters = map($_->{value},@{$mi->{mt}});
		
		foreach my $mv ( iterate($mi->{mv}) ) {
			my $moid = $mv->{moid}->{value};
			my (@idx) = split(/=|,/,$moid);
			my ($idx,$val) = (join(',',map($idx[$_],grep {!($_%2)} (0..$#idx))),join(',',map($idx[$_],grep {($_%2)} (0..$#idx))));
			my @values = map($_->{value},@{$mv->{r}});
			
			foreach my $counter (@counters) {
				my $value = shift @values;
				if (exists $counter_map->{$gran}->{$idx}->{$counter}) {
					
					my $table = $table_map->{$gran}->{$idx}->{$counter};
					my $mapped_name = $counter_map->{$gran}->{$idx}->{$counter};
					 
					$pm{$table}{$idx.'='.$val}{$mapped_name} = $value;
					$counters{$table}{$mapped_name} = 1;
				}
				else {
					#counter does not exist in mapping file. mapping file needs to be updated.
				}
			}
		}
	}
	return(\%pm,\%counters,\%info);
	unlink $tmp_dir.$outfile;	
}


1;
