use strict;
use warnings;
use lib '/home/garnt/eclipse-workspace/MetaMap-DataStructures-0.03/lib';
use MetaMap::DataStructures;
use utf8;
my $id             = 0;
my %params         = ();
my $datastructures = MetaMap::DataStructures->new( \%params );
my %cuis;
my $input = '';
open OUT, '>', "/home/garnt/Documents/totalCUIS.tsv";
my @txtFiles = glob("/home/garnt/Documents/StrainTags.txt");

for ( my $k = 0 ; $k < @txtFiles ; $k++ ) {
	open( my $txtFile, '<:encoding(UTF-8)', "$txtFiles[$k]" );
	while ( my $currWord = <$txtFile> ) {
		open( my $wrdFile, '>:encoding(UTF-8)', "/home/garnt/Documents/currWord.out");
		print $wrdFile $currWord;
		qx/export PATH\=\"\/home\/garnt\/Programs\/metamap\/2016\/public_mm\/bin\:\$PATH\"\nmetamap -zqi \/home\/garnt\/Documents\/currWord.out \/home\/garnt\/Documents\/currFile.out/;
		
		open( my $in, '<:encoding(UTF-8)',"/home/garnt/Documents/currFile.out" )
		  || die("Couldn't open the input file\n");
		while (<$in>) {

			#build a string until the utterance has been read in
			chomp $_;
			$input .= $_;
			my $citations = $datastructures->getCitations();
			
			if ( $_ eq "\'EOU\'." ) {
				$datastructures->createFromTextWithId( $input, "0.ab." . $id );
				$input = '';
				$id++;
			}
		}

		
	}
	print("hello world");
}
my $citations = $datastructures->getCitations();
		foreach my $key ( keys %{$citations} ) {
			my $citation         = ${$citations}{$key};
			my $conceptsListsRef = $citation->getOrderedConcepts();
			foreach my $conceptListRef ( @{$conceptsListsRef} ) {
				foreach my $concept ( @{$conceptListRef} ) {
					print OUT $concept->{cui} . "\t"
					  . $concept->{text} . "\t"
					  . $concept->{semanticTypes} . "\n";
					if ( not exists $cuis{ $concept->{text} } ) {
						$cuis{ $concept->{text} } =
						  $concept->{cui} . "," . $concept->{semanticTypes};
					}
					else {
						$cuis{ $concept->{text} } .=
						    "\n"
						  . $concept->{cui} . ","
						  . $concept->{semanticTypes};
					}
				}
			}
		}
