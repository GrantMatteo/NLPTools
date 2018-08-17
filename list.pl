my @annFiles = glob("/home/garnt/Documents/TAC/*.ann");
open( my $dictOut, '>:encoding(UTF-8)',
	"/home/garnt/Documents/Species/annList.txt" );  
for ( my $k = 0 ; $k < scalar(@annFiles) ; $k++ ) {
	#print $dictOut $annFiles[$k]. "\n";
	open( my $annFile, '<:encoding(UTF-8)', "$annFiles[$k]" )
	  or die(); 
	$row = <$annFile>;
	while ($row) {
		if ( $row =~ m/\d\tSpecies\ \d/ ) {
			$row =~ m/\t\S+$/p;
			my $inst = substr ${^MATCH}, 1;
			$row =~ m/Species\ \d+\ \d+\t/p;
			my $span = substr ${^MATCH}, 8, -1;
			$span =~ m/^\d+/p;
			my $start = ${^MATCH};
			$span =~ m/\d+$/p;
			my $end = ${^MATCH};
			
			#getting rid of punctuation
			while ( $inst =~ m/^[[:punct:]]/ ) {
				$inst =~ s/^[[:punct:]]//;
				$start++;
			}
			while ( $inst =~ m/[[:punct:]]$/ ) {
				$inst =~ s/[[:punct:]]$//;
				$end--;
			}
			my $instString = $inst . " " . $start . " " . $end;
			print $dictOut $instString. "\n";
		}
		$row = <$annFile>;
	}
}