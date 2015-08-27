#!/usr/in/perl -w

# Dekker Lab
# Bryan R. Lajoie
# http://my5C.umassmed.edu
# my5C.help@umassmed.edu
# https://github.com/blajoie/crane-nature-2015

use English;
use warnings;
use strict;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);
use POSIX qw(ceil floor);
use List::Util qw[min max];
use Cwd 'abs_path';
use Cwd;

use cworld::crane_nature2015 qw(:all);

sub check_options {
	my $opts = shift;

	my ($inputMatrix,$verbose,$insulationSquareSize,$insulationDeltaSpan,$insulationMode,$noiseThreshold,$boundaryMarginOfError,$ignoreZero);
	
	if( exists($opts->{ inputMatrix }) ) {
		$inputMatrix = $opts->{ inputMatrix };
	} else {
		print "\nERROR: Option inputMatrix|i is required.\n";
		help();
	}
	
	if( defined($opts->{ verbose }) ) {
		$verbose = $opts->{ verbose };
	} else {
		$verbose = 0;
	}
	
	if( exists($opts->{ insulationSquareSize }) ) {
		$insulationSquareSize = $opts->{ insulationSquareSize };
	} else {
		$insulationSquareSize=500000;
	}
	
	if( exists($opts->{ insulationDeltaSpan }) ) {
		$insulationDeltaSpan = $opts->{ insulationDeltaSpan };
	} else {
		$insulationDeltaSpan=($insulationSquareSize/2);
	}
	
	if( exists($opts->{ insulationMode }) ) {
		$insulationMode = $opts->{ insulationMode };
	} else {
		$insulationMode="mean";
	}
	
	if( exists($opts->{ noiseThreshold }) ) {
		$noiseThreshold = $opts->{ noiseThreshold };
	} else {
		$noiseThreshold=0.1;
	}
	
	if( exists($opts->{ boundaryMarginOfError }) ) {
		$boundaryMarginOfError = $opts->{ boundaryMarginOfError };
	} else {
		$boundaryMarginOfError=0;
	}
	
	if( exists($opts->{ ignoreZero }) ) {
		$ignoreZero = 1;
	} else {
		$ignoreZero = 0;
	}

	return($inputMatrix,$verbose,$insulationSquareSize,$insulationDeltaSpan,$insulationMode,$noiseThreshold,$boundaryMarginOfError,$ignoreZero);
}

sub calculateInsulation($$$$$$$$) {
	my $matrixObject=shift;
	my $matrix=shift;
	my $insulationFileName=shift;
	my $insulationSquareSize=shift;
	my $insulationMode=shift;
	my $ignoreZero=shift;
	my $toolsDirectory=shift;
	my $verbose=shift;
	
	my $inc2header=$matrixObject->{ inc2header };
	my $header2inc=$matrixObject->{ header2inc };
	my $numHeaders=$matrixObject->{ numYHeaders };
	my $headerSizing=$matrixObject->{ headerSizing };
	my $headerSpacing=$matrixObject->{ headerSpacing };
	
	my %matrixInsulation=();
	my @insulationSignals=();
	
	for(my $y=$insulationSquareSize;$y<($numHeaders-$insulationSquareSize);$y++) {
		my $yHead=$inc2header->{ y }->{$y};
		
		#do not include the diagonal
		my $startY=($y-$insulationSquareSize);
		my $endY=$y;
		my $startX=$y+1;
		my $endX=($y+$insulationSquareSize)+1;
			
		my $skipFlag=0;
		my @boxData=();
		
		my $expectedDataCount=(($endY-$startY)*($endX-$startX));
		my $nullCount=0;
		
		for(my $y2=$startY;$y2<$endY;$y2++) {
			my $yHead=$inc2header->{ y }->{$y2};
			for(my $x2=$startX;$x2<$endX;$x2++) {	
				my $xHead=$inc2header->{ x }->{$x2};
				
				my $inten=$matrixObject->{ missingValue };
				$inten=$matrix->{$y2}->{$x2} if(exists($matrix->{$y2}->{$x2}));
				
				$nullCount++ if($inten == -7337);
				$skipFlag = 1 if($inten == -7337);
				next if($inten == -7337);
				
				next if(($inten == 0) and ($ignoreZero == 1));
				
				push(@boxData,$inten);
			}
		}
		
		my $boxDataSize=scalar @boxData;
		
		print STDERR "\twarning - not enough usable data points!\tskipping $yHead...\n" if($nullCount > ($expectedDataCount/2));
		next if($nullCount > ($expectedDataCount/2));
		
		next if(($skipFlag == 1) and ($insulationMode eq "sum"));
		next if($boxDataSize == 0);
		
		my $boxDataStats=listStats(\@boxData);
		my $boxDataAggregate="NA";
		$boxDataAggregate=$boxDataStats->{ $insulationMode } if(exists($boxDataStats->{ $insulationMode }));
		my $boxDataZeroPercent=$boxDataStats->{ zeroPC };
		
		# store result in hash header->insulation
		$matrixInsulation{$yHead}=$boxDataAggregate;
		push(@insulationSignals,$boxDataAggregate);
	}
	
	# mean center the insulation data
	
	my $tmpStats=listStats(\@insulationSignals);
	my $meanInsulationScore=$tmpStats->{ mean };
	print "\tmean centering data ($meanInsulationScore)\n" if($verbose);
	
	my @normalizedInsulationSignals=();
	for(my $y=$insulationSquareSize;$y<($numHeaders-$insulationSquareSize);$y++) {
		my $yHead=$inc2header->{ y }->{$y};
		
		next if(!exists($matrixInsulation{$yHead}));
		
		my $insulationScore=$matrixInsulation{$yHead};
		
		#mean center the insulation scores
		my $normalizedInsulationScore = "NA";
		$normalizedInsulationScore = ($insulationScore-$meanInsulationScore);
		$normalizedInsulationScore = (log($insulationScore/$meanInsulationScore)/log(2)) if(($meanInsulationScore != 0) and ($insulationScore != 0));
		
		$matrixInsulation{$yHead}=$normalizedInsulationScore;
		push(@normalizedInsulationSignals,$normalizedInsulationScore);	
	}
	
	my $tmpNormalizedStats=listStats(\@normalizedInsulationSignals);
	my $meanNormalizedInsulationScore=$tmpNormalizedStats->{ mean };
	print "\tnormalized data mean ($meanNormalizedInsulationScore)\n" if($verbose);
	
	return(\%matrixInsulation);
	
}

sub outputInsulation($$$$$) {
	my $matrixObject=shift;
	my $matrixInsulation=shift;
	my $matrixDelta=shift;
	my $matrixDeltaSquare=shift;	
	my $insulationFileName=shift;
	
	my $inc2header=$matrixObject->{ inc2header };
	my $header2inc=$matrixObject->{ header2inc };
	my $numHeaders=$matrixObject->{ numYHeaders };
	my $headerSizing=$matrixObject->{ headerSizing };
	my $headerSpacing=$matrixObject->{ headerSpacing };
	
	# main insulation file
	open(OUT,">".$insulationFileName);
	print OUT "header\tstart\tend\tmidpoint\tbinStart\tbinEnd\tbinMidpoint\tinsulationScore\tdelta\tdeltaSquare\n";
	
	# bed graph file of insulation data
	open(BEDGRAPH,">".$insulationFileName.".bedGraph");
	print BEDGRAPH "track type=bedGraph name='".$insulationFileName."' description='".$insulationFileName." - insutation score' visibility=full autoScale=off viewLimits=0:2 color=0,0,0 altColor=100,100,100\n";
	
	my $lastChromosome="NA";
	for(my $y=0;$y<$numHeaders;$y++) {
		# dump insulation data to file
		my $yHead=$inc2header->{ y }->{$y};
		
		my $insulation="NA";
		$insulation=$matrixInsulation->{$yHead} if(exists($matrixInsulation->{$yHead}));
		
		my $delta="NA";
		$delta=$matrixDelta->{$yHead} if(exists($matrixDelta->{$yHead}));
		
		my $deltaSquare="NA";
		$deltaSquare=$matrixDeltaSquare->{$yHead} if(exists($matrixDeltaSquare->{$yHead}));
		
		my $yHeadObject=getPrimerNameInfo($yHead);
		my $yHeadChromosome=$yHeadObject->{ chromosome };
		my $yHeadStart=$yHeadObject->{ start };
		my $yHeadEnd=$yHeadObject->{ end };
		my $yHeadMidpoint=(($yHeadStart+$yHeadEnd)/2);
		
		my $binStart = round($yHeadStart/$headerSpacing);
		my $binEnd = round($yHeadEnd/$headerSpacing);
		my $binMidpoint=(($binStart+$binEnd)/2);
		
		print OUT "$yHead\t$yHeadStart\t$yHeadEnd\t$yHeadMidpoint\t$binStart\t$binEnd\t$binMidpoint\t$insulation\t$delta\t$deltaSquare\n";
		
		print BEDGRAPH "$yHeadChromosome\t$yHeadStart\t$yHeadEnd\t$insulation\n";
		$lastChromosome=$yHeadChromosome;
	}
	
	close(OUT);
	close(BEDGRAPH);
	
}

sub outputInsulationBoundaries($$$) {
	my $matrixObject=shift;
	my $tadBoundaries=shift;
	my $insulationFileName=shift;
	
	my $inc2header=$matrixObject->{ inc2header };
	my $header2inc=$matrixObject->{ header2inc };
	my $numHeaders=$matrixObject->{ numYHeaders };
	my $headerSizing=$matrixObject->{ headerSizing };
	my $headerSpacing=$matrixObject->{ headerSpacing };

	open(OUT,">".$insulationFileName);
	print OUT "header\tstart\tend\tbinStart\tbinEnd\tbinMidpoint\theader\tinsulationScore\n";
	
	open(BED,">".$insulationFileName.".bed");
	
	print BED "track name='".$insulationFileName."' description='called tad boundaries' useScore=1\n";
	
	for(my $y=0;$y<$numHeaders;$y++) {
		# dump insulation data to file
		my $yHead=$inc2header->{ y }->{$y};
	
		next if(!exists($tadBoundaries->{$yHead}->{ header }));
		
		my $boundaryHeader=$tadBoundaries->{$yHead}->{ header };
		next if($boundaryHeader eq "NA");
		
		my $boundaryStrength=$tadBoundaries->{$yHead}->{ strength };
		
		my $boundaryObject=getPrimerNameInfo($boundaryHeader);
		my $boundaryChromosome=$boundaryObject->{ chromosome };
		my $boundaryStart=$boundaryObject->{ start };
		my $boundaryEnd=$boundaryObject->{ end };
		print BED "$boundaryChromosome\t$boundaryStart\t$boundaryEnd\t$yHead\t$boundaryStrength\n";

		my $binStart = round($boundaryStart/$headerSpacing);
		my $binEnd = round($boundaryEnd/$headerSpacing);
		my $binMidpoint=(($binStart+$binEnd)/2);
		
		print OUT "$boundaryHeader\t$boundaryStart\t$boundaryEnd\t$binStart\t$binEnd\t$binMidpoint\t$yHead\t$boundaryStrength\n";
		
	}
	
	close(OUT);
	close(BED);
}

sub detectInsulationBoundaries($$$$$$) {
	my $matrixObject=shift;
	my $matrixInsulation=shift;
	my $insulationSquareSize=shift;
	my $insulationDeltaBinSize=shift;
	my $noiseThreshold=shift;
	my $boundaryMarginOfError=shift;
	
	my $inc2header=$matrixObject->{ inc2header };
	my $header2inc=$matrixObject->{ header2inc };
	my $numHeaders=$matrixObject->{ numYHeaders };
	my $headerSizing=$matrixObject->{ headerSizing };
	my $headerSpacing=$matrixObject->{ headerSpacing };

	my $halfInsulationSquareSize=ceil($insulationSquareSize/2);
	my $halfInsulationDeltaBinSize=ceil($insulationDeltaBinSize/2);
	
	my @tmpInsulation=();
	for(my $y=0;$y<$numHeaders;$y++) {
		# dump insulation data to file
		my $yHead=$inc2header->{ y }->{$y};
		
		my $insulation="NA";
		$insulation=$matrixInsulation->{$yHead} if(exists($matrixInsulation->{$yHead}));
		push(@tmpInsulation,$insulation) if($insulation ne "NA");
		
	}
	
	my %tadBoundaries=();
	my $matrixDelta={};
	
	for(my $y=0;$y<$numHeaders;$y++) {
		# dump insulation data to file
		my $yHead=$inc2header->{ y }->{$y};
		my $insulation="NA";
		$insulation=$matrixInsulation->{$yHead} if(exists($matrixInsulation->{$yHead}));
		
		my $leftBound=($y-$halfInsulationDeltaBinSize);
		$leftBound=0 if($leftBound < 0);
		my $rightBound=($y+$halfInsulationDeltaBinSize);
		$rightBound=$numHeaders-1 if($rightBound >= $numHeaders);
				
		my @leftDelta=();
		for(my $ly=$leftBound;$ly<$y;$ly++) {
			my $leftHead=$inc2header->{ y }->{$ly};
			my $leftInsulation="NA";
			$leftInsulation=$matrixInsulation->{$leftHead} if(exists($matrixInsulation->{$leftHead}));
			
			my $delta="NA";
			$delta=($leftInsulation-$insulation) if(($insulation ne "NA") and ($leftInsulation ne "NA"));
			push(@leftDelta,$delta) if($delta ne "NA");
		}
		my $leftDeltaAggregrate="NA";
		if(@leftDelta > 0) {
			my $leftDeltaStats=listStats(\@leftDelta);
			$leftDeltaAggregrate=$leftDeltaStats->{ mean };
		}
		
		my @rightDelta=();
		for(my $ry=$y+1;$ry<=$rightBound;$ry++) {
			my $rightHead=$inc2header->{ y }->{$ry};
			my $rightInsulation="NA";
			$rightInsulation=$matrixInsulation->{$rightHead} if(exists($matrixInsulation->{$rightHead}));
			
			my $delta="NA";
			$delta=($rightInsulation-$insulation) if(($insulation ne "NA") and ($rightInsulation ne "NA"));
			push(@rightDelta,$delta) if($delta ne "NA");
		}
		my $rightDeltaAggregrate="NA";
		if(@rightDelta > 0) {
			my $rightDeltaStats=listStats(\@rightDelta);
			$rightDeltaAggregrate=$rightDeltaStats->{ mean };
		}
		
		my $deltaDelta="NA";
		$deltaDelta=($leftDeltaAggregrate-$rightDeltaAggregrate) if(($leftDeltaAggregrate ne "NA") and ($rightDeltaAggregrate ne "NA"));
		
		$matrixDelta->{$yHead}=$deltaDelta;
	}
	
	my %matrixDeltaSquare=();
	for(my $y=0;$y<$numHeaders;$y++) {
		# dump insulation data to file
		my $yHead=$inc2header->{ y }->{$y};
		my $delta="NA";
		$delta=$matrixDelta->{$yHead} if(exists($matrixDelta->{$yHead}));
		
		$matrixDeltaSquare{$yHead}=$delta;
		$matrixDeltaSquare{$yHead}=1 if(($delta ne "NA") and ($delta > 0));
		$matrixDeltaSquare{$yHead}=-1 if(($delta ne "NA") and ($delta < 0));
	}
	
	my @preLimBoundaries=();
	my $binc=0;
	my $lastBound=0;
	for(my $y=0;$y<$numHeaders;$y++) {
		# dump insulation data to file
		my $yHead=$inc2header->{ y }->{$y};
		my $deltaSquare="NA";
		$deltaSquare=$matrixDeltaSquare{$yHead} if(exists($matrixDeltaSquare{$yHead}));
		
		next if($deltaSquare eq "NA");
		
		if(($deltaSquare != $lastBound) and ($lastBound != 0)) {
			$preLimBoundaries[$binc]{ header }=$yHead;
			$preLimBoundaries[$binc]{ lastBound }=$lastBound;
			$binc++;
		} 
		$lastBound=$deltaSquare;
	}

	for(my $i=0;$i<@preLimBoundaries;$i++) {
		my $yHead=$preLimBoundaries[$i]{ header };
		my $yIndex=$header2inc->{ y }->{$yHead};
		
		my $currentDelta="NA";
		$currentDelta=$matrixDelta->{$yHead} if(exists($matrixDelta->{$yHead}));
		next if($currentDelta eq "NA");
		
		my ($leftSearchIndex,$rightSearchIndex);
		
		# get strength via delta
		
		$leftSearchIndex=$yIndex-1;
		# while left is increasing
		while( ($leftSearchIndex > 0) and ($matrixDelta->{$inc2header->{ y }->{$leftSearchIndex}} ne "NA") and ($matrixDelta->{$inc2header->{ y }->{$leftSearchIndex-1}} ne "NA") and ($matrixDelta->{$inc2header->{ y }->{$leftSearchIndex-1}} >= $matrixDelta->{$inc2header->{ y }->{$leftSearchIndex}}) ) {
			$leftSearchIndex--;
		}
		my $leftDeltaBound="NA";
		$leftDeltaBound=$matrixDelta->{$inc2header->{ y }->{$leftSearchIndex}} if(exists($matrixDelta->{$inc2header->{ y }->{$leftSearchIndex}}));
		
		$rightSearchIndex=$yIndex+1;
		# while right is decreasing
		while( ($rightSearchIndex < ($numHeaders-2)) and ($matrixDelta->{$inc2header->{ y }->{$rightSearchIndex}} ne "NA") and ($matrixDelta->{$inc2header->{ y }->{$rightSearchIndex+1}} ne "NA") and ($matrixDelta->{$inc2header->{ y }->{$rightSearchIndex+1}} <= $matrixDelta->{$inc2header->{ y }->{$rightSearchIndex}}) ) {
			$rightSearchIndex++;
		}
		my $rightDeltaBound="NA";
		$rightDeltaBound=$matrixDelta->{$inc2header->{ y }->{$rightSearchIndex}};
		
		my $valleyDeltaStrength="NA";
		$valleyDeltaStrength=($leftDeltaBound-$rightDeltaBound) if(($leftDeltaBound ne "NA") and ($rightDeltaBound ne "NA"));
		
		next if($valleyDeltaStrength eq "NA");
		next if($valleyDeltaStrength < $noiseThreshold);
			
		#print "\tboundary\n";
		
		my $boundaryObject=getPrimerNameInfo($yHead);
		my $boundaryChromosome=$boundaryObject->{ chromosome };
		my $boundaryAssembly=$boundaryObject->{ assembly };
		my $boundaryStart=$boundaryObject->{ start };
		my $boundaryEnd=$boundaryObject->{ end };
		my $boundaryMidpoint=(($boundaryStart+$boundaryEnd)/2);
		
		$boundaryStart=($boundaryMidpoint-($headerSpacing/2));
		$boundaryEnd=($boundaryMidpoint+($headerSpacing/2));
		
		$boundaryStart -= ($boundaryMarginOfError*$headerSpacing);
		$boundaryEnd += ($boundaryMarginOfError*$headerSpacing);
		
		my $boundaryHeader="boundary.".$i."|".$boundaryAssembly."|".$boundaryChromosome.":".$boundaryStart."-".$boundaryEnd;
		$tadBoundaries{$yHead}{ header }=$boundaryHeader;
		$tadBoundaries{$yHead}{ strength }=$valleyDeltaStrength;
	
	}
	
	return(\%tadBoundaries,$matrixDelta,\%matrixDeltaSquare);
}


sub intro() {
	print "\n";
	
	print "Tool:\t\tmatrix2insulation.pl\n";
	print "Version:\t1.0.0\n";
	print "Summary:\tcalculate insulation index (TADs) of supplied matrix\n";
	
	print "\n";
}

sub help() {
	intro();
	
	print "Usage: perl matrix2insulation.pl [OPTIONS] -i <inputMatrix>\n";
	
	print "\n";
	
	print "Required:\n";
	printf("\n\t%-10s %-10s %-10s\n", "-i", "[]", "input matrix file");
	
	print "\n";
	
	print "Options:\n";
	printf("\n\t%-10s %-10s %-10s\n", "-b", "[]", "size (bp) of the insulation square");
	printf("\n\t%-10s %-10s %-10s\n", "-v", "[]", "FLAG, verbose mode");
	printf("\n\t%-10s %-10s %-10s\n", "-ids", "[]", "insulation delta span (size (bp) of insulation delta window)");
	printf("\n\t%-10s %-10s %-10s\n", "-im", "[]", "insulation mode (how to aggregrate signal within insulation square), mean,sum,median");
	printf("\n\t%-10s %-10s %-10s\n", "-nt", "[0.1]", "noise threshold, minimum depth of valley");
	printf("\n\t%-10s %-10s %-10s\n", "-bmoe", "[3]", "boundary margin of error (specified in number of BINS), added to each side of the boundary");
	
	print "\n";
	
	print "Notes:";
	print "
	This script calculates the insulation index of a given matrix to identify TAD boundaries.
	Matrix can be TXT or gzipped TXT.
	See git wiki for details.\n";
	
	print "
	Code associated with Crane, Bian, McCord, Lajoie et al. Nature 2015
	Publisher: NPG; Journal: Nature; Article Type: Biology letter DOI: 10.1038/nature14450
	Condensin-driven remodelling of X chromosome topology during dosage compensation 
	Emily Crane, Qian Bian, Rachel Patton McCord, Bryan R. Lajoie, Bayly S. Wheeler, Edward J. Ralston, Satoru Uzawa, Job Dekker & Barbara J. Meyer\n";
	
	print "\n";
	
	print "Contact:
	Dekker Lab
	Bryan R. Lajoie
	http://my5C.umassmed.edu
	my5C.help\@umassmed.edu
	https://github.com/blajoie/crane-nature-2015\n";
	
	print"\n";
	
	exit;
}

my %options;
my $results = GetOptions( \%options,'inputMatrix|i=s','verbose|v','insulationSquareSize|is=s','insulationDeltaSpan|ids=s','insulationMode|im=s','noiseThreshold|nt=s','boundaryMarginOfError|bmoe=s','ignoreZero|iz');

#user Inputs
my ($inputMatrix,$verbose,$insulationSquareSize,$insulationDeltaSpan,$insulationMode,$noiseThreshold,$boundaryMarginOfError,$ignoreZero)=check_options( \%options );

intro() if($verbose);

print "inputMatrix (-i)\t$inputMatrix\n" if($verbose);
print "verbose (-v)\t$verbose\n" if($verbose);
print "insulationSquareSize (-is)\t$insulationSquareSize\n" if($verbose);
print "insulationDeltaSpan (-insulationDeltaSpan)\t$insulationDeltaSpan\n" if($verbose);
print "insulationMode (-im)\t$insulationMode\n" if($verbose);
print "noiseThreshold (-nt)\t$noiseThreshold\n" if($verbose);
print "boundaryMarginOfError (-bmoe)\t$boundaryMarginOfError\n" if($verbose);
print "ignoreZero (-iz)\t$ignoreZero\n" if($verbose);

print "\n" if($verbose);

#get the abssolute path of the script being used
my $cwd = getcwd();
my $fullScriptPath=abs_path($0);
my @fullScriptPathArr=split(/\//,$fullScriptPath);
my $scriptName=$fullScriptPathArr[@fullScriptPathArr-1];
my $scriptPath = $fullScriptPath;
$scriptPath =~ s/$scriptName//;

my $toolsDirectory="/cShare/tools/";

die("\nERROR: inputMatrix does not exist!\n\t$inputMatrix\n\n") if(!(-e $inputMatrix));

# get matrix information
my $matrixObject=getMatrixObject($inputMatrix,$verbose);
my $inc2header=$matrixObject->{ inc2header };
my $header2inc=$matrixObject->{ header2inc };
my $numYHeaders=$matrixObject->{ numYHeaders };
my $numXHeaders=$matrixObject->{ numXHeaders };
my $numTotalHeaders=$matrixObject->{ numTotalHeaders };
my $missingValue=$matrixObject->{ missingValue };
my $equalHeaders=$matrixObject->{ equalHeaderFlag };
my $symmetrical=$matrixObject->{ symmetrical };

die("\nERROR: matrix must be symmetrical!\n") if(!$symmetrical);
die("\nERROR: matrix must be equally-binned!\n") if(!$equalHeaders);

my $numHeaders=$numYHeaders=$numXHeaders;

# get fragment spacing (i.e. bin size)
my ($equalSpacingFlag,$equalSizingFlag,$headerSpacing,$headerSizing)=getHeaderSpacing($inc2header->{ y },$numHeaders);

print "\n" if($verbose);

my $insulationDeltaBinSize=ceil(($insulationDeltaSpan)/$headerSpacing);
$insulationDeltaBinSize += 1 if(($insulationDeltaBinSize % 2) == 1);
my $insulationDeltaBinSizeDistance=($insulationDeltaBinSize * $headerSpacing)+($headerSizing-$headerSpacing);
print "insulation delta\t$insulationDeltaBinSizeDistance bp\t$insulationDeltaBinSize\n" if($verbose);

die("\nERROR: insulationDeltaSpan cannot be larger than dataset ($insulationDeltaBinSize > $numHeaders)\n") if($insulationDeltaBinSize > $numHeaders);

# set bin size to ~1MB 
my $idealBinSize=$insulationSquareSize;
$insulationSquareSize=ceil(($idealBinSize-($headerSizing-$headerSpacing))/$headerSpacing);
$insulationSquareSize = 2 if($insulationSquareSize <= 1);
my $insulationSquareSizeDistance=($insulationSquareSize * $headerSpacing)+($headerSizing-$headerSpacing);
print "insulationSquareSize\t$insulationSquareSizeDistance bp\t$insulationSquareSize\n" if($verbose);

die("\nERROR: insulationSquareSize cannot be larger than dataset ($insulationSquareSize > $numHeaders)\n") if($insulationSquareSize > $numHeaders);

print "\n" if($verbose);

my $inputMatrixName=getFileName($inputMatrix);
$inputMatrixName .= ".is".$insulationSquareSizeDistance.".ids".$insulationDeltaBinSizeDistance;

#read Matrix
print "reading matrix into hash (subset=".(($insulationSquareSizeDistance*2)+$headerSizing).")...\n" if($verbose);
my ($matrix)=getData($inputMatrix,$matrixObject,$verbose,(($insulationSquareSizeDistance*2)+$headerSizing));
print "\tdone\n" if($verbose);

# reset sparse value to NA
$matrixObject->{ missingValue }=-7337;
$missingValue=$matrixObject->{ missingValue };

print "\n" if($verbose);

# calculate the insulation index for each bin and store in a new data struct.
print "calculating insulation index...\n" if($verbose);
my ($matrixInsulation)=calculateInsulation($matrixObject,$matrix,$inputMatrixName,$insulationSquareSize,$insulationMode,$ignoreZero,$toolsDirectory,$verbose);
print "\tdone\n" if($verbose);

print "\n" if($verbose);

# detect boundaries
print "detecting boundaries...\n" if($verbose);
my ($tadBoundaries,$matrixDelta,$matrixDeltaSquare)=detectInsulationBoundaries($matrixObject,$matrixInsulation,$insulationSquareSize,$insulationDeltaBinSize,$noiseThreshold,$boundaryMarginOfError);
print "\tdone\n" if($verbose);

print "\n" if($verbose);

# write insulation data to file
my $insulationFileName=$inputMatrixName.".insulation";
print "outputing insulation...\n" if($verbose);
outputInsulation($matrixObject,$matrixInsulation,$matrixDelta,$matrixDeltaSquare,$insulationFileName);
print "\tdone\n" if($verbose);

print "\n" if($verbose);

# write insulation data to file
print "outputing insulation boundaries...\n" if($verbose);
outputInsulationBoundaries($matrixObject,$tadBoundaries,$insulationFileName.".boundaries");
print "\tdone\n" if($verbose);

print "\n" if($verbose);
