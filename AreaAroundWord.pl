use strict;
use warnings;
use utf8;
use constant windowSize => 4;
my %labels;
my @txtFiles = glob("/home/garnt/Documents/n2c2/*.txt");
my @annFiles = glob("/home/garnt/Documents/n2c2/*.ann");

## CHANGE THIS
my $tag = "Frequency";
open (my $OUT,'>:encoding(UTF-8)', "/home/garnt/Documents/locationFiles/FrequencyLocation.xml");
open (my $STATSOUT,'>:encoding(UTF-8)', "/home/garnt/Documents/statsFiles/FrequencyStats.out");
## STOP CHANGING THINGS BEFORE YOU BREAK SOMETHING
for ( my $k = 0 ; $k < scalar(@txtFiles) ; $k++ ) {
	my $slurpedStr;
	open( my $txtFile, '<:encoding(UTF-8)', "$txtFiles[$k]" ) or die();
	open( my $annFile, '<:encoding(UTF-8)', "$annFiles[$k]" )
	  or die();                                        #slurp file data
	my $row = <$txtFile>;
	while ($row) {
		$slurpedStr .= $row;
		$row = <$txtFile>;
	}

	$slurpedStr =~ s/[[:punct:]]/\ /g;
	my @spaceTokens = split /\s+/, $slurpedStr;
	my @anns;    
	#list of strings (word . start . end)

	#slurping the .ann file (kind of) into @anns
	$row = <$annFile>;
	
	while ($row) {
		while ($row =~ m/\d+\ \d+\;\d+\ \d+\t/){
			$row =~ s/\ \d+\;\d+\ /\ /g;
		} 
		
		if ( $row =~ m/\d\t$tag\ \d/ ) {
			$row =~ m/$tag\ \d+\ \d+\t/p;
			my $span = substr ${^MATCH}, length($tag)+1, -1;
			$span =~ m/^\d+/p;
			my $start = ${^MATCH};
			$span =~ m/\d+$/p;
			my $end = ${^MATCH};
			$row =~ m/$span\t.+$/p;
			my $inst = substr ${^MATCH}, 1 + length($span);
			#getting rid of punctuation
			while ( $inst =~ m/^[[:punct:]]/ ) {
				$inst =~ s/^[[:punct:]]//;
				$start++;
			}
			while ( $inst =~ m/[[:punct:]]$/ ) {
				$inst =~ s/[[:punct:]]$//;
				$end--;
			}
			my $instString =$start . " " . $end . " " . $inst;
			push( @anns, $instString );
		}
		$row = <$annFile>;
	}
	foreach my $annStr (@anns) {
		my @ann = split(/\s/,$annStr);
		my $capturedStr="";
		my $before = substr $slurpedStr, 0, $ann[0];
		my $after = substr $slurpedStr, $ann[1]; #geting text before and after using span
		my $windowStr = "\\S*\\s*" x (windowSize / 2);
		if ($before =~ /$windowStr\s*$/p){
			$capturedStr.=${^MATCH};
		}
		$capturedStr.="<captured>";
		my $dictStr="";
		for (my $j=2; $j<scalar(@ann); $j++){
			while ($ann[$j] =~ s/\s/\ /g){}
			$capturedStr.= " ". $ann[$j]. " ";
			$dictStr.=" ".$ann[$j];
		}
		if (not exists $labels{$dictStr}){
			$labels{$dictStr}= 1;
		} else {
			$labels{$dictStr}++;
		}
		$capturedStr.="</captured>";
		if ($after =~ /^\s*$windowStr/p){
			$capturedStr.=${^MATCH};
		}
		print $OUT "<phrase>$capturedStr</phrase>\n\n";
	}
	
}
my $count=0;
my @uniqKeys=keys(%labels);
@uniqKeys = sort( {$labels{$b} <=> $labels{$a}} @uniqKeys);
foreach my $key (@uniqKeys){
	$count+=$labels{$key};
	print $STATSOUT "$labels{$key}:\t$key\n";
}
print($STATSOUT "\nTOTAL: $count");
close($OUT);
close($STATSOUT);