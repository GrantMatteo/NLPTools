use strict;
use warnings;
use utf8;
#TAC XML Compare (Compare.pl)
#Author: Grant Matteo
#Input 2 Folderpaths to the folders containing the directories of your TAC dataset and generated files (please have two folders with a 1:1 ratio of ANN files with the same names)
#a regex matching your desired tags EX: "Species" or "(Species)|(Sex)" CAPITALIZATION MATTERS
#and the output file
#             <CHANGE THESE LINES>
my $originalFilePath  = "/home/garnt/Documents/TAC";
my $generatedFilePath = "/home/garnt/Documents/Outputs";
my $tag               = "DoseUnits";
open my $out, '>:encoding(UTF-8)', "/home/garnt/Documents/output.txt";
#            </CHANGE THESE LINES>



#directory of the original TAC dataset
my @ANN_Originals = glob( $originalFilePath . "/*.ann" );

#directory of the generated ann files
my @ANN_Generated = glob( $generatedFilePath . "/*.ann" );

#for keeping track of overall f1, precision, and recall
my $totalTruePos;
my $totalFalsePos;
my $totalFalseNeg;

for ( my $k = 0 ; $k < @ANN_Originals ; $k++ ) {

	open( my $originalFile, '<:encoding(UTF-8)', "$ANN_Originals[$k]" )
	  or die("couldn't open file");
	open( my $generatedFile, '<:encoding(UTF-8)', "$ANN_Generated[$k]" )
	  or die("Couldn't open file");

	#read in values from user-generated files
	my @annsGenned;    #list of strings (word . start . end)

	#slurping the .ann file (kind of)
	my $row = <$generatedFile>;
	while ($row) {
		if ( $row =~ m/\d\t$tag\ \d/ ) {
			$row =~ m/$tag\ \d+\ \d+\t/p;
			my $span = substr ${^MATCH}, length($tag)+1, -1;
			$span =~ m/^\d+/p;
			my $start = ${^MATCH};
			$span =~ m/\d+$/p;
			my $end = ${^MATCH};
			$row =~ m/$span\t.+$/p;
			my $inst = substr ${^MATCH}, 1+length($span);

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
			push( @annsGenned, $instString );
		}
		$row = <$generatedFile>;
	}

	#read in values from original files
	my @annsOrig;    #list of strings (word . start . end)

	#slurping the .ann file (kind of)
	$row = <$originalFile>;
	while ($row) {
		if ( $row =~ m/\d\t$tag\ \d/ ) {
			
			$row =~ m/$tag\ \d+\ \d+\t/p;
			my $span = substr ${^MATCH}, length($tag)+1, -1;
			$span =~ m/^\d+/p;
			my $start = ${^MATCH};
			$span =~ m/\d+$/p;
			my $end = ${^MATCH};
			$row =~ m/$span\t.+$/p;
			my $inst = substr ${^MATCH}, 1+length($span);

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
			push( @annsOrig, $instString );
		}
		$row = <$originalFile>;
	}
	my @truePositives;

	#check the values
	for ( my $i = 0 ; $i < scalar(@annsGenned) ; $i++ ) {
		for ( my $j = 0 ; $j < scalar(@annsOrig) ; $j++ ) {

			if ( $annsOrig[$j] eq $annsGenned[$i] ) {

# if everything matches, add it to truePositives, cut the various values out of the arrays

				push( @truePositives, $annsOrig[$j] );

				splice( @annsGenned, $i, 1 );
				splice( @annsOrig,   $j, 1 );
				$j -= 1;
				$i -=1;

			}

		}

	}

#after the loop is finished, True Positives --@truePositives False Positives -- @spansGenerated
#                            False Negatives --@spansOriginal
#print out all values
	print($out  "$ANN_Generated[$k]");
	print($out  "\n\nTrue Positives: " . scalar(@truePositives) . "\n\n" );
	for ( my $i = 0 ; $i < scalar(@truePositives) ; $i++ ) {
		print $out $truePositives[$i] . "\n";

	}
	print($out  "\n\n\nFalse Positives: " . scalar(@annsGenned) . "\n\n" );
	for ( my $i = 0 ; $i < scalar(@annsGenned) ; $i++ ) {
		print $out "$annsGenned[$i]\n";
	}
	print($out  "\n\n\nFalse Negatives:" . scalar(@annsOrig) . "\n\n" );
	for ( my $i = 0 ; $i < scalar(@annsOrig) ; $i++ ) {
		print $out "$annsOrig[$i]\n";
	}
	print $out "\n";
	my $precision=0;
	my $recall=0;
	if ( scalar(@truePositives) + scalar(@annsGenned) ) {
		$precision =
		  scalar(@truePositives) /
		  ( scalar(@truePositives) + scalar(@annsGenned) );
	}
	print($out "\nPrecision: $precision");
	
	if ( scalar(@truePositives) + scalar(@annsOrig) ) {
		$recall =
		  scalar(@truePositives) /
		  ( scalar(@truePositives) + scalar(@annsOrig) );
		
	}
	print $out ("\nRecall: $recall");
	if ( $precision + $recall ) {
		my $f1 = 2 * $precision * $recall / ( $precision + $recall );
		print($out "\nf1: $f1\n\n\n\n");
	}
	else {
		print $out "\n\n\n\n";
	}

	$totalTruePos  += scalar(@truePositives);
	$totalFalsePos += scalar(@annsGenned);
	$totalFalseNeg += scalar(@annsOrig);
}
print $out "\n\n\n------------FINAL CALCULATIONS------------\n\n";

my $precision = $totalTruePos / ( $totalTruePos + $totalFalsePos );
my $recall    = $totalTruePos / ( $totalTruePos + $totalFalseNeg );
my $f1 = 2 * $precision * $recall / ( $precision + $recall );
print($out 
"Total True Positives: $totalTruePos\nTotal False Negatives: $totalFalseNeg\nTotal False Positives: $totalFalsePos"
);
print($out "\n\nPrecision: $precision\nRecall: $recall\nf1: $f1\n\n\n");
close(STDOUT);
