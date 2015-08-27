package cworld::crane_nature2015;

use strict; 
use warnings;
use POSIX qw(ceil floor);
use List::Util qw[min max];
use Cwd 'abs_path';
use Cwd;
use File::Path;
use File::Copy;

require Exporter;

our @ISA = qw(Exporter);

#alias of different export categories
our %EXPORT_TAGS = (
	'all' => [ qw(
		listStats
		round
		badFormat
		getPrimerNameInfo
		classifyInteraction
		classifyInteractionDistance
		parseHeaders
		getNARows
		getData
		truDist
		getMatrixSum
		getRowSum
		writeMatrix
		getMatrixAttributes
		getDate
		quit
		checkMatrixSize
		getHeaderSpacing
		getFileName
		isSymmetrical
		getMaxHeaderLength
		getMatrixObject
		updateMatrixObject
		isOverlapping
		validateZoomCoordinate
		splitCoordinate
		header2subMatrix
		stripChromosomeGroup
		getFilePath
		baseName
		translateFlag
		deGroupHeader
		getUserHomeDirectory
		getUniqueString
		getSmallUniqueString
		getComputeResource
		getShortFileName
		removeFileExtension
		getNumberOfLines
		createTmpDir
		removeTmpDir
		outputWrapper
		inputWrapper
		flipBool
	) ],
	'lite' => [ qw(
		listStats
	) ],
);
  
#what is allowed to be exported
our @EXPORT_OK = ( @{ $EXPORT_TAGS{ all } } );

#global export to user namespace
our @EXPORT = qw( );

#current version
our $VERSION = '0.01';

# Preloaded methods go here.

sub quit($$) {
	my $error_string=shift;
	my $error_file=shift;
	
	open(OUT,">>",$error_file) || die("\nERROR: Could not open file ($error_file)\n\t$!\n\n");
	print OUT "$error_string\n";
	close(OUT);
	
	die("\n\n***ERROR***\n$error_string\n***ERROR***\n\n");	
}
	
sub getDate() {

	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
	my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
	my $year = 1900 + $yearOffset;
	my $time = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
	
	return($time);
}

sub commify {
   (my $num = shift) =~ s/\G(\d{1,3})(?=(?:\d\d\d)+(?:\.|$))/$1,/g; 
   return $num; 
}
	
sub writeMatrix($$$;$$) {
	#required
	my $matrix=shift;
	my $inc2header=shift;
	my $matrixFile=shift;
	#optional
	my $missingValue=0;
	$missingValue=shift if @_;
	my $sigDigits=4;
	$sigDigits=shift if @_;
	
	my $numYHeaders=keys(%{$inc2header->{ y }});
	my $numXHeaders=keys(%{$inc2header->{ x }});
	
	open(OUT,outputWrapper($matrixFile)) || die("\nERROR: Could not open file ($matrixFile)\n\t$!\n\n");
	
	my $time = getDate();
	print OUT "# my5C - http://my5C.umassmed.edu\n# $time\n#\n";	
	
	for(my $x=0;$x<$numXHeaders;$x++) {
		my $xHeader=$inc2header->{ x }->{$x};
		print OUT "\t".$xHeader;
	}
	
	print OUT "\n";
	
	for(my $y=0;$y<$numYHeaders;$y++) {
		my $yHeader=$inc2header->{ y }->{$y};
		
		print OUT "$yHeader";
		
		for(my $x=0;$x<$numXHeaders;$x++) {
			my $xHeader=$inc2header->{ x }->{$x};	
			
			my $cScore=$missingValue;
			$cScore = $matrix->{$y}->{$x} if(defined($matrix->{$y}->{$x}));
			$cScore = "NA" if(($cScore eq "") or ($cScore =~ /^NULL$/i) or ($cScore =~ /^NA$/i) or ($cScore =~ /inf$/i) or ($cScore =~ /^nan$/i) or ($cScore == -7337));
			$cScore = sprintf "%.".$sigDigits."f", $cScore if($cScore ne "NA");
			
			print OUT "\t$cScore";
			
		}
		
		print OUT "\n" if($y != ($numYHeaders-1))
	}
	
	close(OUT);

}

sub listStats($;$) {
	my $listRef=shift;
	my $trimPC=shift || 0;
	
	#flip trim for top/bottom
	$trimPC = ($trimPC / 2);
	
	die("invalid trimPC value (0-1 range)\n") if(($trimPC > 1) or ($trimPC < 0));
	
	my $listArrSize=0;
	$listArrSize=@$listRef if(defined($listRef));
	
	my ($mean,$stdev,$variance,$median,$q1,$q3,$iqr,$min,$max,$count,$sum,$binary,$geomean);
	$mean=$stdev=$variance=$median=$q1=$q3=$iqr=$min=$max=$count=$sum=$binary=$geomean=0;
	
	my $skipGeoMean=0;
	my $iqrMean="NA";
	my $zeroPC=0;
	
	# listArr and sort list
	my @listArr=@$listRef;
	@listArr = sort { $a <=> $b } @listArr;
	
	# validate non null list
	for(my $i=0;$i<$listArrSize;$i++) {
		my $tmpVal=$listArr[$i];
		die("warning - found null in listStats(list)...\n") if($tmpVal == -7337);
	}
	
	die("warning - the list is EMPTY!\n") if($listArrSize == 0);
	
	#quartiles
	my $medianPosition=0.5;
	my $q1Position=0.25;
	my $q3Position=0.75;
	
	if(($listArrSize % 2) == 1) {
		#median
		my $medianIndex = floor($listArrSize * $medianPosition);
		$median = $listArr[$medianIndex];
		#quartile 1
		my $q1Index = floor($listArrSize * $q1Position);
		$q1 = $listArr[$q1Index];
		#quartile 3
		my $q3Index = floor($listArrSize * $q3Position);
		$q3 = $listArr[$q3Index];
		
	} else {
		#median
		my $medianIndexLeft = floor($listArrSize * $medianPosition) - 1;
		my $medianIndexRight = $medianIndexLeft + 1;		
		my $medianLeft = $listArr[$medianIndexLeft];
		my $medianRight = $listArr[$medianIndexRight];
		$median = (($medianLeft + $medianRight) / 2);		
		#quartile 1
		my $q1IndexLeft = floor($listArrSize * $q1Position) - 1;
		my $q1IndexRight = $q1IndexLeft + 1;		
		my $q1Left = $listArr[$q1IndexLeft];
		my $q1Right = $listArr[$q1IndexRight];
		$q1 = (($q1Left + $q1Right) / 2);		
		#quartile 3
		my $q3IndexLeft = floor($listArrSize * $q3Position) - 1;
		my $q3IndexRight = $q3IndexLeft + 1;		
		my $q3Left = $listArr[$q3IndexLeft];
		my $q3Right = $listArr[$q3IndexRight];
		$q3 = (($q3Left + $q3Right) / 2);		
	}
	
	$iqr = ($q3-$q1);
	my $iqrLowerBound = $q1-(1.5*$iqr);
	my $iqrUpperBound = $q3+(1.5*$iqr);
	my $iqrSum=0;
	my $iqrCount=0;
	for(my $i=0;$i<$listArrSize;$i++) {
		my $val=$listArr[$i];
		$iqrSum += $val if(($val >= $iqrLowerBound) and ($val <= $iqrUpperBound));
		$iqrCount++ if(($val >= $iqrLowerBound) and ($val <= $iqrUpperBound));
	}
	$iqrMean=($iqrSum/$iqrCount) if($iqrCount != 0);
	
	my $iqrStdev="NA";
	my $iqrVariance="NA";
	
	if($iqrCount > 1) {
		my $total_iqr_deviation=0;
		for(my $i=0;$i<$listArrSize;$i++) {
			my $val=$listArr[$i];
			
			# only use those values within the new IQR bounds
			next if(($val <= $iqrLowerBound) or ($val >= $iqrUpperBound));
			
			my $deviation=$val-$iqrMean;
			my $sqr_deviation=($deviation**2);
			$total_iqr_deviation += $sqr_deviation;
		}
		$iqrStdev=($total_iqr_deviation/($iqrCount-1));
		$iqrVariance=$iqrStdev;
		$iqrStdev=sqrt($iqrStdev);
	}
		
	$min=$listArr[0]; # get first element (smallest)
	$max=$listArr[-1]; # get last element (largest)
		
	# perform desired trimming
	my $trimmedStart=floor($listArrSize*$trimPC);
	my $trimmedEnd=($listArrSize-$trimmedStart);
	
	#handle small list issue
	$trimmedStart=0 if($trimmedEnd < $trimmedStart);
	$trimmedEnd=($listArrSize) if($trimmedEnd < $trimmedStart);
			
	die("no elements in the list ($listArrSize) [$trimmedStart - $trimmedEnd]!\n") if(($trimmedEnd-$trimmedStart) < 0);
	
	my @trimmedListArr=();
	for(my $i=$trimmedStart;$i<$trimmedEnd;$i++) {
		my $val=$listArr[$i];
		push(@trimmedListArr,$val);
	}
	
	my $trimmedListArrSize = @trimmedListArr;
	die("warning - trimmed list is EMPTY!\n") if($trimmedListArrSize == 0);
	
	my $trimmedMin=0;
	my $trimmedMax=0;
	
	if($trimmedListArrSize > 0) {	
		
		#handle small list issue
		$trimmedStart=0 if($trimmedEnd < $trimmedStart);
		$trimmedEnd=($trimmedListArrSize-1) if($trimmedEnd < $trimmedStart);
				
		die("no elements in the list ($trimmedListArrSize) [$trimmedStart - $trimmedEnd]!\n") if(($trimmedEnd-$trimmedStart) < 0);
		
		$trimmedMin=$trimmedListArr[0]; # get first element (smallest)
		$trimmedMax=$trimmedListArr[-1]; # get last element (largest)
		
		$sum=0;
		my $sumLogs=0;
		for(my $i=0;$i<$trimmedListArrSize;$i++) {
			my $val=$trimmedListArr[$i];
			$sum += $val;
						
			$zeroPC++ if($val == 0);
			
			my $logTmpVal=0;
			$logTmpVal = log($val)/log(2) if($val > 0);
			$skipGeoMean=1 if($val < 0);
			
			$sumLogs += $logTmpVal;
			$count++;
		}
				
		$mean = ($sum / $count);
		$geomean = ($sumLogs / $count);
		$geomean = (2 ** $geomean);
		
		
		my $total_deviation=0;
		for(my $i=0;$i<$trimmedListArrSize;$i++) {
			my $val=$trimmedListArr[$i];
			my $deviation=$val-$mean;
			my $sqr_deviation=$deviation**2;
			$total_deviation=$total_deviation+$sqr_deviation;
		}
		
		if($trimmedListArrSize > 1) {
			$stdev=$total_deviation/($trimmedListArrSize-1);
			$variance=$stdev;
			$stdev=sqrt($stdev);
		}
			
		$binary=1;
	}
	
	#calculate MAD
	my $mad=0;
	
	my @madArr=();
	for(my $i=0;$i<$trimmedListArrSize;$i++) {
		my $val=$trimmedListArr[$i];
		my $absoluteDeviation=abs($val-$median);
		push(@madArr,$absoluteDeviation);		
	}
	@madArr = sort { $a <=> $b } @madArr;
	my $madArrSize=@madArr;
	if(($madArrSize % 2) == 1) {
		my $madIndex = floor($madArrSize * 0.5);
		$mad = $madArr[$madIndex];
	} else {
		my $madIndexLeft = floor($madArrSize * 0.5) - 1;
		my $madIndexRight = $madIndexLeft + 1;		
		my $madLeft = $madArr[$madIndexLeft];
		my $madRight = $madArr[$madIndexRight];
		$mad = (($madLeft + $madRight) / 2);		
	}
	
	$geomean="NA" if($skipGeoMean == 1);
	$zeroPC = round((($zeroPC / $count) * 100),3) if($count != 0);
	
	my %dataHash=();
	$dataHash{ sum }=$sum;
	$dataHash{ count }=$count;
	$dataHash{ zeroPC }=$zeroPC;
	$dataHash{ mean }=$mean;
	$dataHash{ geomean }=$geomean;
	$dataHash{ stdev }=$stdev;
	$dataHash{ variance }=$variance;
	$dataHash{ median }=$median;
	$dataHash{ q1 }=$q1;
	$dataHash{ q3 }=$q3;
	$dataHash{ iqr }=$iqr;
	$dataHash{ iqrMean }=$iqrMean;
	$dataHash{ iqrStdev }=$iqrStdev;
	$dataHash{ iqrVariance }=$iqrVariance;
	$dataHash{ mad }=$mad;
	$dataHash{ min }=$min;
	$dataHash{ max }=$max;
	$dataHash{ trimmedMin }=$trimmedMin;
	$dataHash{ trimmedMax }=$trimmedMax;
	$dataHash{ binary }=$binary;
	
	return(\%dataHash);
	
}

sub roundNearest($$) {
	my $num=shift;
	my $nearest=shift;
	
	return(round($num)) if($nearest == 0);
	
	$num=($num/$nearest);
	$num=round($num);
	$num=($num*$nearest);
	
	return($num);
}
	
sub round($;$) {
	# required
	my $num=shift;
	# optional
	my $digs_to_cut=0;
	$digs_to_cut = shift if @_;
	
	return($num) if($num eq "NA");
	
	my $roundedNum=$num;
	
	if(($num != 0) and ($digs_to_cut == 0)) {
		$roundedNum = int($num + $num/abs($num*2));
	} else {
		$roundedNum = sprintf("%.".($digs_to_cut)."f", $num) if($num =~ /\d+\.(\d){$digs_to_cut,}/);
	}
	
	return($roundedNum);
}

sub badFormat($$$) {
	my $line=shift;
	my $lineNum=shift;
	my $errorType=shift;
	
	die("\nERROR: bad format @ line # $lineNum ($errorType) | $line\n\n");
}

sub getPrimerNameInfo($;$) {
	# required
	my $header=shift;
	# optional 
	my $enforceValidHeaders=0;
	$enforceValidHeaders=shift if @_;
	
	my @tmp=();
	my $tmpSize=0;
	
	my ($subName,$assembly,$coords);
	$subName=$assembly=$coords="NA";	
	@tmp=split(/\|/,$header);
	$tmpSize=scalar @tmp;
	($subName,$assembly,$coords)=split(/\|/,$header) if($tmpSize == 3);	
	badFormat($header,$header,'header is not in proper format...') if(($enforceValidHeaders == 1) and ($tmpSize != 3));
	
	my ($chromosome,$pos);
	$chromosome=$pos="NA";
	@tmp=split(/:/,$coords);
	$tmpSize=scalar @tmp;
	$pos=$tmp[-1];
	$chromosome = $coords;
	$chromosome =~ s/:$pos//;
	badFormat($coords,$coords,'coordinates are not in proper format...') if(($enforceValidHeaders == 1) and ($tmpSize != 2));
	
	my ($region);
	$region=$chromosome;
	
	my $primerType="NA";
	if($subName =~ /__/) {
		@tmp=split(/__/,$subName);
		$region=$tmp[0];
	} else {
		@tmp=split(/_/,$subName);
		$tmpSize=scalar @tmp;
		$region=$tmp[1]."_".$tmp[2] if(($tmpSize == 5) and ($tmp[0] eq "5C"));
		$primerType=$tmp[3] if(($tmpSize == 5) and ($tmp[0] eq "5C"));
	}
	
	my ($start,$end);
	$start=$end=0;
	@tmp=split(/-/,$pos);
	$tmpSize=scalar @tmp;
	($start,$end)=split(/-/,$pos) if($tmpSize == 2);
	badFormat($pos,$pos,'position is not in proper format...') if(($enforceValidHeaders == 1) and ($tmpSize != 2));
	
	my $size=(($end-$start)+1); # add to for 1-based positioning
	my $midpoint=(($end+$start)/2);
		
	my %primerObject=();
	$primerObject{ subName }=$subName;
	$primerObject{ primerType }=$primerType;
	$primerObject{ assembly }=$assembly;
	$primerObject{ chromosome }=$chromosome;
	$primerObject{ coords }=$coords;
	$primerObject{ region }=$region;
	$primerObject{ start }=$start;
	$primerObject{ end }=$end;
	$primerObject{ midpoint }=$midpoint;
	$primerObject{ size }=$size;
	
	return(\%primerObject);
	
}

sub truDist($$$;$$) {
	#required
	my $matrixObject=shift;
	my $primerObject1=shift;
	my $primerObject2=shift;
	#optional
	my $cisApproximateFactor=1;
	$cisApproximateFactor=shift if @_;
	my $logTransform=0;
	$logTransform=shift if @_;

	my $chr_1=$primerObject1->{ chromosome };
	my $region_1=$primerObject1->{ region };
	my $start_1=$primerObject1->{ start };
	my $end_1=$primerObject1->{ end };
	my $midpoint_1=$primerObject1->{ midpoint };
	
	my $chr_2=$primerObject2->{ chromosome };
	my $region_2=$primerObject2->{ region };
	my $start_2=$primerObject2->{ start };
	my $end_2=$primerObject2->{ end };
	my $midpoint_2=$primerObject2->{ midpoint };
	
	return(-1) if(($chr_1 eq "NA") or ($chr_2 eq "NA"));
	return(-1) if(($start_1 >= $end_1) or ($start_2 >= $end_2));
	return(-1) if($region_1 ne $region_2);	
	return(-1) if($chr_1 ne $chr_2);	
	
	my $equalHeaderFlag = $matrixObject->{ equalHeaderFlag };
	my $headerSizing = $matrixObject->{ headerSizing };
	
	# override midpoint, if equalHeaderFlag == 1 (to deal with many many extra distances because of half empty final bin per contig)
	$midpoint_1 = ($start_1+($headerSizing/2)) if($equalHeaderFlag == 1);
	$midpoint_2 = ($start_2+($headerSizing/2)) if($equalHeaderFlag == 1);	
	
	my $dist=-1;
	if($equalHeaderFlag == 0) { # bins do not overlap
		if($midpoint_1 == $midpoint_2) { #self
			$dist = 0;
		} else {
			if($start_1 > $start_2) { 
				$dist = abs($start_1-$end_2);
			} else { 
				$dist = abs($start_2-$end_1);
			}
		}
	} else { # bins do overlap
		$dist = abs($midpoint_1-$midpoint_2);
	}	
	
	#transform dist into approximate dist if necessary
	$dist = round($dist/$cisApproximateFactor) if(($dist != -1) and ($dist != 0)); #do not re-scale if TRANS or SELF
	$dist = log($dist)/log($logTransform) if(($logTransform > 0) and ($dist > 0));
	
	return($dist);
}
	
sub classifyInteraction($$$$$$) {
	my $matrixObject=shift;
	my $includeCis=shift;
	my $cisLimit=shift;
	my $includeTrans=shift;
	my $primerObject1=shift;
	my $primerObject2=shift;
	
	# get true interactor distance (non-scaled)
	my $interactionDistance=truDist($matrixObject,$primerObject1,$primerObject2);
	
	my $chr_1=$primerObject1->{ chromosome };
	my $region_1=$primerObject1->{ region };
	
	my $chr_2=$primerObject2->{ chromosome };
	my $region_2=$primerObject2->{ region };
	
	return("USABLE") if(($includeTrans == 1) and ($interactionDistance == -1) and ($chr_1 ne $chr_2));

	#local mode
	return("USABLE") if( ($includeCis == 1) and ( ($cisLimit eq "NA") or (($cisLimit ne "NA") and ($cisLimit == 0)) or (($cisLimit ne "NA") and (($interactionDistance <= $cisLimit) and ($region_1 eq $region_2))) ) );
	
	return("NULL");
}

sub parseContigs($$$) {
	my $inputMatrix=shift;
	my $inc2header=shift;
	my $header2inc=shift;
	
	my $numYHeaders=keys(%{$header2inc->{ y }});
	my $numXHeaders=keys(%{$header2inc->{ x }});
	my $numTotalHeaders=keys(%{$header2inc->{ xy }});
	
	my $header2contig={};
	my $contig2index={};
	my $index2contig={};
	my $contig2inc={};
	my $header2contiginc={};
	my $contiginc2header={};
	my $contigList={};
	
	my $contigIndex=-1;
	my ($contigInc);
	
	my $lastYContig="NA";
	for(my $y=0;$y<$numYHeaders;$y++) {
		my $yHeader=$inc2header->{ y }->{$y};
		my $yHeaderObject=getPrimerNameInfo($yHeader);
		my $yContig=$yHeaderObject->{ region };
		
		$contigIndex = $contig2index->{$yContig} if(exists($contig2index->{$yContig}));
		$contigIndex = (keys %{$contig2index->{ xy }}) if(!exists($contig2index->{ xy }->{$yContig}));
		
		$contigInc = $header2contiginc->{ xy }->{$yHeader} if(exists($header2contiginc->{ xy }->{$yHeader}));
		$contigInc = $contig2inc->{$yContig}++ if(!exists($header2contiginc->{ xy }->{$yHeader}));
		
		$contig2index->{ y }->{$yContig}=$contigIndex;
		$index2contig->{ y }->{$contigIndex}=$yContig;
		$contig2index->{ xy }->{$yContig}=$contigIndex;
		$index2contig->{ xy }->{$contigIndex}=$yContig;
		
		$header2contig->{ y }->{$yHeader}=$yContig;
		$header2contiginc->{ y }->{$yHeader}=$contigInc;
		$header2contig->{ xy }->{$yHeader}=$yContig;
		$header2contiginc->{ xy }->{$yHeader}=$contigInc;
		
		$contiginc2header->{$yContig}->{$contigInc}=$yHeader;
		#print "Y\t$y\t$yHeader\t$yContig\t$contigIndex\t$contigInc\n";
		$lastYContig=$yContig;
	}
	
	my $lastXContig="NA";
	for(my $x=0;$x<$numXHeaders;$x++) {
		my $xHeader=$inc2header->{ x }->{$x};
		my $xHeaderObject=getPrimerNameInfo($xHeader);
		my $xContig=$xHeaderObject->{ region };
		
		$contigIndex = $contig2index->{$xContig} if(exists($contig2index->{$xContig}));
		$contigIndex = (keys %{$contig2index->{ xy }}) if(!exists($contig2index->{ xy }->{$xContig}));
		
		$contigInc = $header2contiginc->{ xy }->{$xHeader} if(exists($header2contiginc->{ xy }->{$xHeader}));
		$contigInc = $contig2inc->{$xContig}++ if(!exists($header2contiginc->{ xy }->{$xHeader}));
		
		$contig2index->{ x }->{$xContig}=$contigIndex;
		$index2contig->{ x }->{$contigIndex}=$xContig;
		$contig2index->{ xy }->{$xContig}=$contigIndex;
		$index2contig->{ xy }->{$contigIndex}=$xContig;
		
		$header2contig->{ x }->{$xHeader}=$xContig;
		$header2contiginc->{ x }->{$xHeader}=$contigInc;
		$header2contig->{ xy }->{$xHeader}=$xContig;
		$header2contiginc->{ xy }->{$xHeader}=$contigInc;
		
		$contiginc2header->{$xContig}->{$contigInc}=$xHeader;
		#print "X\t$x\t$xHeader\t$xContig\t$contigIndex\t$contigInc\n";
		$lastXContig=$xContig;
	}
	
	my $nContigs=keys(%{$contig2index->{ xy }});
	
	for(my $c=0;$c<$nContigs;$c++) {
		my $contig=$index2contig->{ xy }->{$c};
		
		my $nContigHeaders=$contig2inc->{$contig};
		#print "$c -> $contig -> $nContigHeaders\n";
		for(my $ci=0;$ci<$nContigHeaders;$ci++) {
			my $contigHeader=$contiginc2header->{$contig}->{$ci};

			my $contigHeaderObject=getPrimerNameInfo($contigHeader);
			my $contigHeaderStart=$contigHeaderObject->{ start };
			my $contigHeaderEnd=$contigHeaderObject->{ end };
			my $contigHeaderChromosome=$contigHeaderObject->{ chromosome };
			my $contigHeaderAssembly=$contigHeaderObject->{ assembly };
			
			$contigList->{$contig}->{ contigStart }=$contigHeaderStart if( (!exists($contigList->{$contig}->{ contigStart })) or ($contigHeaderStart < $contigList->{$contig}->{ contigStart }) );
			$contigList->{$contig}->{ contigEnd }=$contigHeaderEnd if( (!exists($contigList->{$contig}->{ contigEnd })) or ($contigHeaderEnd > $contigList->{$contig}->{ contigEnd }) );
			$contigList->{$contig}->{ contigAssembly }=$contigHeaderAssembly;
			$contigList->{$contig}->{ contigChromosome }=$contigHeaderChromosome;
			$contigList->{$contig}->{ contigLength }=($contigList->{$contig}->{ contigEnd }-$contigList->{$contig}->{ contigStart });
		}
		my $contigStart=$contigList->{$contig}->{ contigStart };
		my $contigEnd=$contigList->{$contig}->{ contigEnd };
		my $contigAssembly=$contigList->{$contig}->{ contigAssembly };
		my $contigChromosome=$contigList->{$contig}->{ contigChromosome };
		my $contigLength=$contigList->{$contig}->{ contigLength };
		#print "$contigAssembly\t$contigChromosome\t$contigStart - $contigEnd [$contigLength]\n";
	}
	
	return($header2contig,$index2contig,$contig2index,$contigList);
	
}

sub validateMatrixFile($) {
	my $inputMatrix=shift;
		
	return(1) if(($inputMatrix =~ /\.gz$/) and (!(-T($inputMatrix))));
	return(1) if((-T($inputMatrix)) and ($inputMatrix !~ /.png$/) and ($inputMatrix !~ /.gz$/));
	
	return(0);
}


sub checkHeaders($) {
	#required
	my $inputMatrix=shift;

	my $headerFlag=1;
	my $lineNum=0;
	my $init=1;
	
	open(IN,inputWrapper($inputMatrix)) || die("\nERROR: Could not open file ($inputMatrix)\n\t$!\n\n");
	
	while(my $line = <IN>) {
		chomp($line);
		next if($line =~ m/^#/);
		next if($line eq "");
		next if($lineNum > 0);
		
		if($lineNum == 0) {
			my @xHeaders=split(/\t/,$line);
			my $xhsize=@xHeaders;
			
			$init=0;
			my %tmpXHeaders=();
			for(my $x=1;$x<$xhsize;$x++) { # skip to left of matrix
				my $xHead=$xHeaders[$x];
				$headerFlag = 0 if($xHead =~ (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/));
				$headerFlag = 0 if(exists($tmpXHeaders{$xHead})); # if duplicate header, then use row/col # as header
				$tmpXHeaders{$xHead}=1;
			}
			undef %tmpXHeaders;
		}
		last;
	}
	
	close(IN);
	
	return($headerFlag);
		
}

sub parseHeaders($) {
	#required
	my $inputMatrix=shift;
	
	my $inc2header={};	
	my $header2inc={};
	
	my $noHeaderFlag=0;
	my $headerCornerFlag=0;
	
	my %tmpXHeaders=();
	my %tmpYHeaders=();
	
	my ($lineNum,$numXHeaders,$numYHeaders);
	$lineNum=$numXHeaders=$numYHeaders=0;
	
	# subtract 1 to get rid of header line
	my $numLines=getNumberOfLines($inputMatrix)-1;
	
	open(IN,inputWrapper($inputMatrix)) || die("\nERROR: Could not open file ($inputMatrix)\n\t$!\n\n");
	while(my $line = <IN>) {
		chomp($line);
		next if($line =~ m/^#/);
		next if($line eq "");
		
		if($lineNum == 0) {
			my @xHeaders=split(/\t/,$line);
			my $xhsize=@xHeaders;
			
			$headerCornerFlag = 1 if(($xHeaders[0] eq "") or ($xHeaders[0] !~ (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)));
			
			for(my $x=0;$x<$xhsize;$x++) {
				my $xHead=$xHeaders[$x];
				$noHeaderFlag = 1 if($xHead =~ (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/));
				$noHeaderFlag = 1 if(exists($tmpXHeaders{$xHead}));
				die("\nERROR: Must supply headered matrix!\n\n") if(($headerCornerFlag == 0) and ($noHeaderFlag == 1));
				$tmpXHeaders{$xHead}=1;
			}
			undef %tmpXHeaders;
			
			for(my $x=1;$x<$xhsize;$x++) {
				my $xHead=$xHeaders[$x];
				#$xHead="x".$xHead if($noHeaderFlag == 1);
				$header2inc->{ x }->{$xHead}=$numXHeaders;
				$inc2header->{ x }->{$numXHeaders}=$xHead;
				$numXHeaders++;
			}
			
		} else {
			
			my @data=split(/\t/,$line);
			my $dsize=@data;
			my $yHead=$data[0];
			
			# if X is > 10000, assume symmetrical
			if(($numXHeaders > 10000) and ($numLines - ($numXHeaders-1) >= 0) and ($yHead eq $inc2header->{ x }->{0})) {
				close(IN);
				$header2inc->{ y }=$header2inc->{ x };
				$inc2header->{ y }=$inc2header->{ x };
				$header2inc->{ xy }=$header2inc->{ x };
				$inc2header->{ xy }=$inc2header->{ x };
				return($inc2header,$header2inc);
			}
			
			
			$noHeaderFlag = 1 if($yHead =~ (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/));
			$noHeaderFlag = 1 if(exists($tmpYHeaders{$yHead}));
			die("\nERROR: Must supply headered matrix!\n\n") if(($headerCornerFlag == 0) and ($noHeaderFlag == 1));
			
			$header2inc->{ y }->{$yHead}=$numYHeaders;
			$inc2header->{ y }->{$numYHeaders}=$yHead;
			$numYHeaders++;
		}
		$lineNum++;
	}
	
	undef %tmpYHeaders;
	
	my $symmetricalFlag=isSymmetrical($inc2header);
	if($symmetricalFlag == 1) {
		$header2inc->{ xy }=$header2inc->{ y };
		$inc2header->{ xy }=$inc2header->{ x };
		return($inc2header,$header2inc);
	}
	
	# combine and sort the headers
	my %uniqueHeaders=();
	my @headers=();
	my $h=0;
	for(my $y=0;$y<$numYHeaders;$y++) {
		my $yHeader=$inc2header->{ y }->{$y};
		my $yHeaderObject=getPrimerNameInfo($yHeader);
		my $yHeaderStart=$yHeaderObject->{ start };
		
		my $yHeaderChromosome=header2subMatrix($yHeader,'liteChr');
		my $yHeaderGroup=header2subMatrix($yHeader,'group');
		
		next if(exists($uniqueHeaders{$yHeader}));
		
		$headers[$h]{ group } = $yHeaderGroup;
		$headers[$h]{ chr } = $yHeaderChromosome;
		$headers[$h]{ start } = $yHeaderStart;
		$headers[$h]{ header } = $yHeader;
		$uniqueHeaders{$yHeader}=1;
		$h++;
	}
	for(my $x=0;$x<$numXHeaders;$x++) {
		my $xHeader=$inc2header->{ x }->{$x};
		my $xHeaderObject=getPrimerNameInfo($xHeader);
		my $xHeaderStart=$xHeaderObject->{ start };
		
		my $xHeaderChromosome=header2subMatrix($xHeader,'liteChr');
		my $xHeaderGroup=header2subMatrix($xHeader,'group');
		
		next if(exists($uniqueHeaders{$xHeader}));
		
		$headers[$h]{ group } = $xHeaderGroup;
		$headers[$h]{ chr } = $xHeaderChromosome;
		$headers[$h]{ start } = $xHeaderStart;
		$headers[$h]{ header } = $xHeader;
		$uniqueHeaders{$xHeader}=1;
		$h++;
	}	
	
	@headers = sort { $a->{ header } cmp $b->{ header } } @headers;
	@headers = sort { $a->{ start } <=> $b->{ start } } @headers;
	@headers = sort { $a->{ chr } cmp $b->{ chr } } @headers;
	@headers = sort { $a->{ group } cmp $b->{ group } } @headers;
	
	for(my $i=0;$i<@headers;$i++) {
		my $header=$headers[$i]{ header };
		if( (!exists($header2inc->{ xy }->{$header})) and (!exists($inc2header->{ xy }->{$i})) ) {
			$header2inc->{ xy }->{$header}=$i;
			$inc2header->{ xy }->{$i}=$header;
		}
	}
		
	close(IN);
	
	return($inc2header,$header2inc);
		
}

sub updateMatrixObject($) {
	my $matrixObject=shift;
	
	my $inc2header=$matrixObject->{ inc2header };
	my $header2inc=$matrixObject->{ header2inc };
	my $numYHeaders=keys(%{$header2inc->{ y }});
	my $numXHeaders=keys(%{$header2inc->{ x }});
	
	undef $header2inc->{ xy };
	undef $inc2header->{ xy };
	
	$matrixObject->{ numYHeaders }=$numYHeaders;
	$matrixObject->{ numXHeaders }=$numXHeaders;
	$matrixObject->{ numTotalHeaders }="NA";
	
	# combine and sort the headers
	my %uniqueHeaders=();
	my @headers=();
	my $h=0;
	for(my $y=0;$y<$numYHeaders;$y++) {
		my $yHeader=$inc2header->{ y }->{$y};
		my $yHeaderObject=getPrimerNameInfo($yHeader);
		my $yHeaderChromosome=$yHeaderObject->{ chromosome };
		my $yHeaderStart=$yHeaderObject->{ start };
		
		next if(exists($uniqueHeaders{$yHeader}));
		
		$headers[$h]{ chr } = $yHeaderChromosome;
		$headers[$h]{ start } = $yHeaderStart;
		$headers[$h]{ header } = $yHeader;
		$uniqueHeaders{$yHeader}=1;
		$h++;
	}
	for(my $x=0;$x<$numXHeaders;$x++) {
		my $xHeader=$inc2header->{ x }->{$x};
		my $xHeaderObject=getPrimerNameInfo($xHeader);
		my $xHeaderChromosome=$xHeaderObject->{ chromosome };
		my $xHeaderStart=$xHeaderObject->{ start };
		
		next if(exists($uniqueHeaders{$xHeader}));
		
		$headers[$h]{ chr } = $xHeaderChromosome;
		$headers[$h]{ start } = $xHeaderStart;
		$headers[$h]{ header } = $xHeader;
		$uniqueHeaders{$xHeader}=1;
		$h++;
	}	
	
	@headers = sort { $a->{ header } cmp $b->{ header } } @headers;
	@headers = sort { $a->{ start } <=> $b->{ start } } @headers;
	@headers = sort { $a->{ chr } cmp $b->{ chr } } @headers;
	
	for(my $i=0;$i<@headers;$i++) {
		my $header=$headers[$i]{ header };
		if( (!exists($header2inc->{ xy }->{$header})) and (!exists($inc2header->{ xy }->{$i})) ) {
			$header2inc->{ xy }->{$header}=$i;
			$inc2header->{ xy }->{$i}=$header;
		}
	}
	
	my $numTotalHeaders=keys(%{$header2inc->{ xy }});
	
	$matrixObject->{ inc2header }=$inc2header;
	$matrixObject->{ header2inc }=$header2inc;
	
	my $yMaxHeaderLength=getMaxHeaderLength($inc2header->{ y });
	my $xMaxHeaderLength=getMaxHeaderLength($inc2header->{ x });
	
	my $symmetricalFlag=isSymmetrical($inc2header);
	
	# calculate number of interactions
	my $numInteractions=($numYHeaders*$numXHeaders);
	$numInteractions=((($numTotalHeaders*$numTotalHeaders)-$numTotalHeaders)/2) if($symmetricalFlag == 1);
	
	$matrixObject->{ numInteractions }=$numInteractions;
	$matrixObject->{ xHeaderLength }=$xMaxHeaderLength;
	$matrixObject->{ yHeaderLength }=$yMaxHeaderLength;
	$matrixObject->{ symmetrical }=$symmetricalFlag;
	
	return($matrixObject);
}
	
sub getNARows($) {
	#required
	my $inputMatrix=shift;
	
	my $lineNum=0;
	my %NA_headers=();
	
	open(IN,inputWrapper($inputMatrix)) || die("\nERROR: Could not open file ($inputMatrix)\n\t$!\n\n");
	while(my $line = <IN>) {
		chomp($line);
		next if($line =~ m/^#/);
		next if($line eq "");
		
		if($lineNum > 0) { # skip x headers
			my @data=split(/\t/,$line);
			my $dsize=@data;
			my $yHead=$data[0];
			
			my $naCount=0;
			for(my $d=1;$d<$dsize;$d++) {
				my $score=$data[$d];
				last if($score ne "NA");
				$naCount++;
			}
			
			$NA_headers{$yHead}=1 if($naCount == ($dsize-1));
		}
		$lineNum++;
	}
	close(IN);
	
	return(\%NA_headers);
}

sub getData($$;$$$$$) {
	# required
	my $inputMatrix=shift;
	my $matrixObject=shift;
	# optional
	my $verboseMode=0;
	$verboseMode=shift if @_;
	my $distanceLimit="NA";
	$distanceLimit=shift if @_;
	my $excludeCis=0;
	$excludeCis=shift if @_;
	my $excludeTrans=0;
	$excludeTrans=shift if @_;
	my $sigDigits=4;
	$sigDigits=shift if @_;
	
	my $header2inc=$matrixObject->{ header2inc };
	
	checkMatrixSize($header2inc);
	
	my $subsetMode=0;
	$subsetMode = 1 if(($distanceLimit ne "NA") or ($excludeTrans == 1) or ($excludeCis == 1));
	$matrixObject->{ missingValue }=-7337 if($subsetMode == 1);
	
	my $symmetricalFlag=$matrixObject->{ symmetrical };
	my $inputMatrixName=$matrixObject->{ inputMatrixName };
	my $headerSizing=$matrixObject->{ headerSizing };
	my $headerSpacing=$matrixObject->{ headerSpacing };
	my $missingValue=$matrixObject->{ missingValue };
	my $headerFlag=$matrixObject->{ headerFlag };
	
	my $binOffset=0;
	$binOffset=ceil(($distanceLimit-($headerSizing-$headerSpacing))/$headerSpacing) if(($distanceLimit ne "NA") and ($symmetricalFlag == 1));
	
	my %matrix=();
	
	my $lineNum=0;
	my @xHeaders=();
	
	print "\tgetData\n" if($verboseMode == 1);
	
	my $nLines = getNumberOfLines($inputMatrix)-1;
	my $progressBucketSize=ceil($nLines / 1000);
	my $pcComplete=0;
	
	my $nNonZeros=0;
	
	my %headerObjects=();
	
	open(IN,inputWrapper($inputMatrix)) || die("\nERROR: Could not open file ($inputMatrix)\n\t$!\n\n");
	while(my $line = <IN>) {
		chomp($line);
		next if($line =~ m/^#/);
		next if($line eq "");
		
		if($lineNum == 0) {
			@xHeaders=split(/\t/,$line);
		} else {
			my @data=split(/\t/,$line);
			my $dsize=@data;
			
			my $yHeader=$data[0];
			my $yHeaderObject={};
			$yHeaderObject=getPrimerNameInfo($yHeader) if(($subsetMode == 1) and (!exists($headerObjects{$yHeader})));
			$yHeaderObject=$headerObjects{$yHeader} if(($subsetMode == 1) and (exists($headerObjects{$yHeader})));
			$headerObjects{$yHeader}=$yHeaderObject if(($subsetMode == 1) and (!exists($headerObjects{$yHeader})));
			
			my $yIndex=-1;
			$yIndex = $header2inc->{ y }->{$yHeader} if(defined($header2inc->{ y }->{$yHeader}));
			next if($yIndex == -1);
			
			my $indexStart=1;
			$indexStart=($yIndex-$binOffset)+1 if(($binOffset != 0) and (($yIndex-$binOffset) > 1));
			
			my $indexEnd=$dsize;
			$indexEnd=($yIndex+$binOffset)+1 if(($binOffset != 0) and (($yIndex+$binOffset) < $dsize));
			
			for(my $i=$indexStart;$i<$indexEnd;$i++) {
				my $cScore=$data[$i];
				
				# skip if cScore is not a valid number
				$cScore = -7337 if($cScore !~ (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/));
				
				# sparse matrix logic - do not store 0/nan (depending on quantity)
				next if($cScore == $missingValue); 
				
				# truncate numbers to minimal digits
				$cScore = sprintf "%.".$sigDigits."f", $cScore if($cScore != -7337);
				
				my $xHeader=$xHeaders[$i];
				my $xHeaderObject={};
				$xHeaderObject=getPrimerNameInfo($xHeader) if(($subsetMode == 1) and (!exists($headerObjects{$xHeader})));
				$xHeaderObject=$headerObjects{$xHeader} if(($subsetMode == 1) and (exists($headerObjects{$xHeader})));
				$headerObjects{$xHeader}=$xHeaderObject if(($subsetMode == 1) and (!exists($headerObjects{$xHeader})));
				
				my $xIndex=-1;
				$xIndex = $header2inc->{ x }->{$xHeader} if(defined($header2inc->{ x }->{$xHeader}));
				next if($xIndex == -1);
				
				if($subsetMode == 1) {
					my $interactionDistance=truDist($matrixObject,$yHeaderObject,$xHeaderObject,1);
					next if(($distanceLimit ne "NA") and ($interactionDistance == -1));
					next if(($distanceLimit ne "NA") and ($interactionDistance >= $distanceLimit));
					next if(($interactionDistance == -1) and ($excludeTrans == 1));
					next if(($interactionDistance != -1) and ($excludeCis == 1));
				}
				
				# ensure symmetrical data
				if(($symmetricalFlag == 1) and (exists($matrix{$xIndex}{$yIndex}))) {
					print STDERR "\nERROR - data is not symmetrical ($xIndex,$yIndex) [$cScore vs ".$matrix{$xIndex}{$yIndex} ."]\n\n" if(($matrix{$xIndex}{$yIndex} != $cScore) and ($subsetMode == 0));
				}
				
				$matrix{$yIndex}{$xIndex}=$cScore;
				$nNonZeros++
				
			}
		}
				
		$pcComplete = 100 if($lineNum == ($nLines-1));
		print "\e[A" if(($verboseMode == 1) and ($lineNum != 0));
		printf "\t%.2f%% complete ($lineNum/".($nLines-1).")...\n", $pcComplete if($verboseMode == 1);
		$pcComplete = round((($lineNum/$nLines)*100),2);
		$lineNum++;
	}
	close(IN);
	
	$pcComplete=100;
	print "\e[A" if($verboseMode == 1);
	printf "\t%.2f%% complete ($lineNum/$nLines)...\n", $pcComplete if($verboseMode == 1);

	return(\%matrix,$matrixObject);
}

sub getRowSum($$$$$$$$) {
	# required
	my $matrixObject=shift;
	my $matrix=shift;
	my $cisLimit=shift;
	my $cisApproximateFactor=shift;
	my $includeCis=shift;
	my $includeTrans=shift;
	my $ignoreZero=shift;
	my $aggregrateMode=shift;
	# optional 
	
	my $inc2header=$matrixObject->{ inc2header };
	my $numYHeaders=$matrixObject->{ numYHeaders };
	my $numXHeaders=$matrixObject->{ numXHeaders };
	my $symmetricalFlag=$matrixObject->{ symmetrical };
	my $inputMatrixName=$matrixObject->{ inputMatrixName };

	my %rowSums=();
	
	for(my $y=0;$y<$numYHeaders;$y++) {
		
		my $yHeader=$inc2header->{ y }->{$y};
		my $yHeaderObject=getPrimerNameInfo($yHeader);
		
		my @tmpList=();
		
		for(my $x=0;$x<$numXHeaders;$x++) {
			
			#only work above diagonal if symmetrical 
			next if(($symmetricalFlag == 1) and ($y < $x)); 
			
			my $xHeader=$inc2header->{ x }->{$x};	
			my $xHeaderObject=getPrimerNameInfo($xHeader);
			
			my $cScore=$matrixObject->{ missingValue };
			$cScore=$matrix->{$y}->{$x} if(defined($matrix->{$y}->{$x}));
						
			next if($cScore eq "");
			next if(($cScore =~ /^NULL$/i) or ($cScore =~ /^NA$/i) or ($cScore =~ /inf$/i) or ($cScore =~ /^nan$/i));
			next if($cScore == -7337);
			
			next if(($ignoreZero == 1) and ($cScore == 0));
						
			my $interactionDistance=truDist($matrixObject,$yHeaderObject,$xHeaderObject,$cisApproximateFactor);
			my $interactionClassification=classifyInteraction($matrixObject,1,$cisLimit,1,$yHeaderObject,$xHeaderObject);
						
			next if($interactionClassification ne "USABLE");
			
			push(@tmpList,$cScore);
			
		}
		
		my $tmpArrStats=listStats(\@tmpList) if(@tmpList > 0);
		my $rowSum="NA";
		$rowSum=$tmpArrStats->{ $aggregrateMode } if(exists($tmpArrStats->{ $aggregrateMode }));
		#print "\t$yHeader -> $rowSum\n";
		
		$rowSums{$yHeader}=$rowSum;
	}
	
	return(\%rowSums);
}

sub checkMatrixSize($) {
	my $header2inc=shift;
	
	my $numYHeaders=keys(%{$header2inc->{ y }});
	my $numXHeaders=keys(%{$header2inc->{ x }});
	
	my $numInteractions = ($numYHeaders * $numXHeaders);
}

sub getHeaderSpacing($$) {
	my $inc2header=shift;
	my $numFrags=shift;
	
	my $equalSpacingFlag=1;
	my $equalSizingFlag=1;
	
	my (@globalHeaderSpacingArr,@globalHeaderSizingArr);
	my ($globalHeaderSpacing,$globalHeaderSizing);
	$globalHeaderSpacing=$globalHeaderSizing=-1;
	for(my $i=0;$i<$numFrags-1;$i++) {
		
		my $header=$inc2header->{$i};
		my $headerObject=getPrimerNameInfo($header);
		my $headerRegion=$headerObject->{ region };
		my $headerStart=$headerObject->{ start };
		my $headerEnd=$headerObject->{ end };
		my $headerSize=$headerObject->{ size };
		
		my $nextHeader=$inc2header->{$i+1};
		my $nextHeaderObject=getPrimerNameInfo($nextHeader);
		my $nextHeaderRegion=$nextHeaderObject->{ region };
		my $nextHeaderStart=$nextHeaderObject->{ start };
		my $nextHeaderEnd=$nextHeaderObject->{ end };
		my $nextHeaderSize=$nextHeaderObject->{ size };
		
		next if(($nextHeaderRegion ne $headerRegion) or ($headerEnd == $nextHeaderEnd) or ($headerStart == $nextHeaderStart));
		
		$equalSpacingFlag=0 if(($globalHeaderSpacing != (($nextHeaderStart-$headerStart))) and ($globalHeaderSpacing != -1));
		$equalSizingFlag=0 if(($globalHeaderSizing != ($headerSize)) and ($globalHeaderSizing != -1));
		
		$globalHeaderSpacing=($nextHeaderStart-$headerStart);
		$globalHeaderSizing=$headerSize;
				
		push(@globalHeaderSpacingArr,$globalHeaderSpacing);
		push(@globalHeaderSizingArr,$globalHeaderSizing);
		
	}
	
	my $meanGlobalHeaderSpacing=0;
	my $globalHeaderSpacingArrStats=listStats(\@globalHeaderSpacingArr) if(@globalHeaderSpacingArr > 0);
	$meanGlobalHeaderSpacing=$globalHeaderSpacingArrStats->{ mean } if(@globalHeaderSpacingArr > 0);
	
	
	my $meanGlobalHeaderSizing=0;
	my $globalHeaderSizingArrStats=listStats(\@globalHeaderSizingArr) if(@globalHeaderSizingArr > 0);
	$meanGlobalHeaderSizing=$globalHeaderSizingArrStats->{ mean } if(@globalHeaderSizingArr > 0);
	
	return($equalSpacingFlag,$equalSizingFlag,$meanGlobalHeaderSpacing,$meanGlobalHeaderSizing);
	
}

sub isSymmetrical($) {
	my $input=shift;
	
	# two possible inputs - either a file, or a hash ref to headers
	my ($inc2header,$header2inc);
	if(-e $input) {
		($inc2header,$header2inc)=parseHeaders($input);
	} else {
		$inc2header=$input;
	}
		
	my $numYHeaders=keys(%{$inc2header->{ y }});
	my $numXHeaders=keys(%{$inc2header->{ x }});
	
	# lazy test for symmetrical heatmap - should actually check that all headers are identical
	return(0) if($numYHeaders != $numXHeaders); # not symmetrical

	# enforce perfectly symmetrical input matrix
	for(my $y=0;$y<$numYHeaders;$y++) {
		my $yHeader=$inc2header->{ y }->{$y};
		my $xHeader=$inc2header->{ x }->{$y};
			
		return(0) if($yHeader ne $xHeader);
	}

	for(my $x=0;$x<$numXHeaders;$x++) {
		my $xHeader=$inc2header->{ x }->{$x};
		my $yHeader=$inc2header->{ y }->{$x};
		
		return(0) if($xHeader ne $yHeader);
	}
	
	# no longer do this 
	
	# if symmetrical headers, ensure header spacing is equal
	#my $numFrags=$numYHeaders;
	#my ($equalSpacingFlag_y,$equalSizingFlag_y,$headerSpacing_y,$headerSizing_y)=getHeaderSpacing($inc2header->{ y },$numYHeaders);
	#my ($equalSpacingFlag_x,$equalSizingFlag_x,$headerSpacing_x,$headerSizing_x)=getHeaderSpacing($inc2header->{ x },$numXHeaders);
	
	# enforce symmetrical headers, and all equal header spacing/sizing
	#return(0) if(($equalSpacingFlag_y == 0) or ($equalSizingFlag_y == 0)); # headers are not all equally sized/spaced
	#return(0) if(($equalSpacingFlag_x == 0) or ($equalSizingFlag_x == 0)); # headers are not all equally sized/spaced
	#return(0) if(($headerSpacing_y != $headerSpacing_x) or ($headerSizing_y != $headerSizing_x));
	
	return(1);
	
}

sub getMatrixSum($$;$) {	
	my $matrixObject=shift;
	my $matrix=shift;
	#optional
	my $ignoreDiagonal=0;
	$ignoreDiagonal=shift if @_;
	
	my $inc2header=$matrixObject->{ inc2header };
	my $numYHeaders=$matrixObject->{ numYHeaders };
	my $numXHeaders=$matrixObject->{ numXHeaders };
	my $missingValue=$matrixObject->{ missingValue };
	my $numFrags=$numYHeaders=$numXHeaders;
	
	my $symmetricalFlag=isSymmetrical($inc2header);	
	
	my $sumMatrix=0;
	for(my $y=0;$y<$numYHeaders;$y++) {
		for(my $x=0;$x<$numXHeaders;$x++) {
			
			# skip below diagonal
			next if(($symmetricalFlag == 1) and ($y > $x));
			
			# skip diagonal
			next if(($ignoreDiagonal == 1) and ($y == $x) and ($symmetricalFlag == 1));
			
			my $inten=$missingValue;
			$inten=$matrix->{$y}->{$x} if(defined($matrix->{$y}->{$x}));
						
			$sumMatrix += $inten if($inten != -7337);
		}
	}
	
	return($sumMatrix);
}

sub getFileName($) {
	my $file=shift;
	
	my $fileName=(split(/\//,$file))[-1];
	my $shortName=$fileName;
	$shortName =~ s/\.matrix\.gz$//;
	$shortName =~ s/\.matrix$//;
	$shortName =~ s/\.gz$//;
	
	# if non-matrix file - remove extension
	$shortName=removeFileExtension($shortName) if($shortName eq $fileName);
	
	return($shortName);
}	

sub getShortFileName($) {
	my $fileName=shift;
	
	$fileName=(split(/\//,$fileName))[-1];
	my $shortName=(split(/\./,$fileName))[0];
	$shortName=(split(/__/,$shortName))[0];
	
	return($shortName);
}	

sub getFilePath($) {
	my $filePath=shift;
	
	my $shortName=(split(/\//,$filePath))[-1];
	$filePath =~ s/$shortName$//;	
	
	my $cwd = getcwd();
	$filePath = $cwd."/" if($filePath eq "");
	
	return($filePath);
}	

sub baseName($) {
	my $fileName=shift;
	
	my $shortName=(split(/\//,$fileName))[-1];
	
	return($shortName);
}	

sub removeFileExtension($) {
	my $fileName=shift;
	
	my $extension=(split(/\./,$fileName))[-1];
	$fileName =~ s/\.$extension$//;
	
	return($fileName);
}

sub getMatrixAttributes($) {
	my $inputMatrix=shift;
	
	my $cisApproximateFactor=1;
	
	my $matrixObject=getMatrixObject($inputMatrix,1);
	my $inc2header=$matrixObject->{ inc2header };
	my $header2inc=$matrixObject->{ header2inc };
	my $numYHeaders=$matrixObject->{ numYHeaders };
	my $numXHeaders=$matrixObject->{ numXHeaders };
	my $symmetricalFlag=$matrixObject->{ symmetrical };
	
	my ($iCis,$iTrans,$totalCis,$totalTrans);
	$iCis=$iTrans=$totalCis=$totalTrans=0;
	
	my $lineNum=0;
	my @xHeaders=();
	
	print "\n\tgetMatrixAttributes\n";
	
	my $nLines = getNumberOfLines($inputMatrix);
	my $progressBucketSize=ceil($nLines / 1000);
	my $pcComplete=0;
	
	open(IN,inputWrapper($inputMatrix)) || die("\nERROR: Could not open file ($inputMatrix)\n\t$!\n\n");
	while(my $line = <IN>) {
		chomp($line);
		next if($line =~ m/^#/);
		next if($line eq "");
		
		if($lineNum == 0) {
			@xHeaders=split(/\t/,$line);
		} else {
			my @data=split(/\t/,$line);
			my $dsize=@data;
			my $yHeader=$data[0];
			
			my $yIndex=-1;
			$yIndex = $header2inc->{ y }->{$yHeader} if(defined($header2inc->{ y }->{$yHeader}));
			print "\nWARNING - header ($yHeader) does not exists in header2inc!\n\n" if($yIndex == -1);
			next if($yIndex == -1);
				
			my $yHeaderObject=getPrimerNameInfo($yHeader);
			
			for(my $d=1;$d<$dsize;$d++) {
				my $xHeader=$xHeaders[$d];
				
				my $xIndex=-1;
				$xIndex = $header2inc->{ x }->{$xHeader} if(defined($header2inc->{ x }->{$xHeader}));
				print "\nWARNING - header ($xHeader) does not exists in header2inc!\n\n" if($xIndex == -1);
				next if($xIndex == -1);
			
				next if(($yIndex > $xIndex) and ($symmetricalFlag == 1)); # only work above diagonal if symmetrical map
	
				my $xHeaderObject=getPrimerNameInfo($xHeader);			
				
				my $cScore=$data[$d];
				
				# skip if cScore is not a valid number
				next if($cScore !~ (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/));
				next if($cScore eq "");
				next if(($cScore =~ /^NULL$/i) or ($cScore =~ /^NA$/i) or ($cScore =~ /inf$/i) or ($cScore =~ /^nan$/i));
				next if($cScore == -7337);
				
				my $interactionClassification=classifyInteraction($matrixObject,1,0,1,$yHeaderObject,$xHeaderObject);
				next if($interactionClassification ne "USABLE");
				
				my $interactionDistance=truDist($matrixObject,$yHeaderObject,$xHeaderObject,$cisApproximateFactor);
				
				if($interactionDistance == -1) {
					$iTrans++;
					$totalTrans += $cScore;
				} else { 
					$iCis++;
					$totalCis += $cScore;
				}
			}
		}
		
		$pcComplete = 100 if($lineNum == ($nLines-1));
		print "\e[A" if($lineNum != 0);
		printf "\t%.2f%% complete ($lineNum/$nLines)...\n", $pcComplete;
		$pcComplete = round((($lineNum/$nLines)*100),2);
		$lineNum++;
		
	}
	close(IN);
	
	$pcComplete=100;
	print "\e[A";
	printf "\t%.2f%% complete ($lineNum/$nLines)...\n", $pcComplete;
	
	my $totalReads=($totalCis+$totalTrans);
	
	my $cisPercent=round((($totalCis/$totalReads)*100),2);
	my $transPercent=round((($totalTrans/$totalReads)*100),2);
	
	my $averageTrans="NA";
	$averageTrans=($totalTrans/$iTrans) if($iTrans > 0);
	
	return($totalReads,$cisPercent,$transPercent,$averageTrans);
}

sub getMaxHeaderLength($) {
	my $inc2header=shift;
	
	my $numHeaders=keys(%{$inc2header});
	
	my $maxHeaderLength=0;
	for(my $i=0;$i<$numHeaders;$i++) {
		my $header=$inc2header->{$i};
		my $headerLength=length($header);
		$maxHeaderLength=$headerLength if($headerLength > $maxHeaderLength);
	}
	
	return($maxHeaderLength);
}

sub getMatrixObject($;$$) {
	# required
	my $inputMatrix=shift;
	# optional
	my $verboseMode=0;
	$verboseMode=shift if @_;
	my $mode="";
	$mode=shift if @_;
	
	print "getting matrix object [$mode]...\n" if($verboseMode == 1);
	
	my %matrixObject=();
	
	# ensure file exists
	die("\nERROR - File does not exist! ($inputMatrix)\n\n") if(!(-e $inputMatrix));
	
	# ensure file is valid
	die("\nERROR - Bad input file supplied (not normal matrix file -$inputMatrix)\n\n") if(!(validateMatrixFile($inputMatrix)));
	
	# get matrix headers
	my ($headerFlag)=checkHeaders($inputMatrix);
	
	my ($inc2header,$header2inc)=parseHeaders($inputMatrix);
	my $numYHeaders=keys(%{$header2inc->{ y }});
	my $numXHeaders=keys(%{$header2inc->{ x }});
	my $numTotalHeaders=keys(%{$header2inc->{ xy }});
	
	# get matrix headers
	my ($header2contig,$index2contig,$contig2index,$contigList)=parseContigs($inputMatrix,$inc2header,$header2inc);
	my $numXContigs=keys(%{$contig2index->{ x }});
	my $numYContigs=keys(%{$contig2index->{ y }});
	my $numContigs=keys(%{$contig2index->{ xy }});
	
	my $yMaxHeaderLength=getMaxHeaderLength($inc2header->{ y });
	my $xMaxHeaderLength=getMaxHeaderLength($inc2header->{ x });

	# get header spacing/sizing/overlap etc.
	#print "get header stats...\n";
	my ($headerSizing,$headerSpacing,$binningStep,$equalSizingFlag,$equalSpacingFlag,$equalHeaderFlag)=getHeaderStats($inputMatrix);
	
	# check for matrix symmetry
	my $symmetricalFlag=isSymmetrical($inputMatrix);
	
	# get NA row/cols
	my $NA_rowcols;
	if(($numTotalHeaders < 10000) and ($symmetricalFlag == 1) and ($mode ne "lite")) {
		my ($NA_rows)=getNARows($inputMatrix);
		my $NA_cols=$NA_rows;
	
		my %NA_rowcols_hash=(%$NA_rows,%$NA_cols);
		$NA_rowcols=\%NA_rowcols_hash;
	}
	my $numNArowcols=keys %{$NA_rowcols};
	
	# calculate number of interactions
	my $numInteractions=($numYHeaders*$numXHeaders);
	$numInteractions=((($numTotalHeaders*$numTotalHeaders)-$numTotalHeaders)/2) if($symmetricalFlag == 1);
	
	my $num_zeros="NA";
	my $num_nans="NA";
	my $missingValue=0;
	($num_zeros,$num_nans,$missingValue)=chooseOptimalMissingValue($inputMatrix) if(($numTotalHeaders < 20000) and ($mode ne "lite"));
	
	my $inputMatrixName=getFileName($inputMatrix);
	my $inputMatrixPath=getFilePath($inputMatrix);
	
	if($verboseMode == 1) {
		print "\tinputMatrixName\t$inputMatrixName\n";
		print "\tinputMatrixPath\t$inputMatrixPath\n";
		print "\tmatrixHeaderFlag\t$headerFlag\n";
		print "\tequalHeaderSizing\t$equalSizingFlag\n";
		print "\tequalHeaderSpacing\t$equalSpacingFlag\n";
		print "\tequalHeaderFlag\t$equalHeaderFlag\n";
        print "\theaderSizing\t$headerSizing\n";
		print "\theaderSpacing\t$headerSpacing\n";
		print "\tbinningStep\t$binningStep\n";
		print "\t# contigs\t$numContigs\n";
		print "\t# yHeaders\t$numYHeaders\n";
		print "\t# xHeaders\t$numXHeaders\n";
		print "\t# totalHeaders\t$numTotalHeaders\n";
		print "\tnumNArowcols\t$numNArowcols\n";
		print "\tsymmetricalFlag\t$symmetricalFlag\n";
		print "\tnumInteractions\t$numInteractions\n";
		print "\tclosest distance mode\n" if($equalHeaderFlag == 0);
		print "\tmidpoint distance mode\n" if($equalHeaderFlag == 1);
		print "\tnum_zeros\t$num_zeros\n";
		print "\tnum_nan\t$num_nans\n";
		print "\tmissingValue\t$missingValue\n";
		print "\n";
	}
	
	$matrixObject{ inputMatrixName }=$inputMatrixName;
	$matrixObject{ inputMatrixPath }=$inputMatrixPath;
	$matrixObject{ header2contig }=$header2contig;
	$matrixObject{ index2contig }=$index2contig;
	$matrixObject{ contig2index }=$contig2index;
	$matrixObject{ contigList }=$contigList;
	$matrixObject{ numXContigs }=$numXContigs;
	$matrixObject{ numYContigs }=$numYContigs;
	$matrixObject{ numContigs }=$numContigs;
	$matrixObject{ headerFlag }=$headerFlag;
	$matrixObject{ inc2header }=$inc2header;
	$matrixObject{ header2inc }=$header2inc;
	$matrixObject{ numYHeaders }=$numYHeaders;
	$matrixObject{ numXHeaders }=$numXHeaders;
	$matrixObject{ numTotalHeaders }=$numTotalHeaders;
	$matrixObject{ numNArowcols }=$numNArowcols;
	$matrixObject{ NArowcols }=$NA_rowcols;
	$matrixObject{ numInteractions }=$numInteractions;
	$matrixObject{ xHeaderLength }=$xMaxHeaderLength;
	$matrixObject{ yHeaderLength }=$yMaxHeaderLength;
	$matrixObject{ symmetrical }=$symmetricalFlag;
	$matrixObject{ equalHeaderFlag }=$equalHeaderFlag;
	$matrixObject{ equalSizingFlag }=$equalSizingFlag;
	$matrixObject{ equalSpacingFlag }=$equalSpacingFlag;
	$matrixObject{ headerSizing }=$headerSizing;
	$matrixObject{ headerSpacing }=$headerSpacing;
	$matrixObject{ binningStep }=$binningStep;
	$matrixObject{ missingValue }=$missingValue;
	
	return(\%matrixObject);
	
}

sub getHeaderStats($) {
	my $input=shift;
	
	# two possible inputs - either a file, or a hash ref to headers
	my ($inc2header,$header2inc);
	if(-e $input) {
		($inc2header,$header2inc)=parseHeaders($input);
	} else {
		$inc2header=$input;
	}
		
	my $numYHeaders=keys(%{$inc2header->{ y }});
	my $numXHeaders=keys(%{$inc2header->{ x }});
	
	my ($ySpacingFlag,$ySizingFlag,$yHeaderSpacing,$yHeaderSizing)=getHeaderSpacing($inc2header->{ y },$numYHeaders); 
	my ($xSpacingFlag,$xSizingFlag,$xHeaderSpacing,$xHeaderSizing)=getHeaderSpacing($inc2header->{ x },$numXHeaders);

	my $equalSpacingFlag=0;
	$equalSpacingFlag = 1 if(($ySpacingFlag == 1) and ($xSpacingFlag == 1) and ($yHeaderSpacing == $xHeaderSpacing));
	
	my $equalSizingFlag=0;
	$equalSizingFlag = 1 if(($ySizingFlag == 1) and ($xSizingFlag == 1) and ($yHeaderSizing == $xHeaderSizing));
	
	my $equalHeaderFlag=0;
	my $binningStep=0;
	my $headerSpacing=-1;
	my $headerSizing=-1;
	if(($equalSpacingFlag == 1) and ($equalSizingFlag == 1)) {
		# y / x headers are equivalent
		$headerSpacing=$yHeaderSpacing=$xHeaderSpacing;
		$headerSizing=$yHeaderSizing=$xHeaderSizing;
		
		$binningStep=round($headerSizing/$headerSpacing) if($headerSpacing != 0);
		
		$equalHeaderFlag=1;
	}
	
	return($headerSizing,$headerSpacing,$binningStep,$equalSizingFlag,$equalSpacingFlag,$equalHeaderFlag);
	
}

sub validateZoomCoordinate($) {
	my $zoomCoordinate=shift;
	
	$zoomCoordinate =~ s/,//g;
	
	return(0) if($zoomCoordinate eq "");
	return(0) if($zoomCoordinate !~ m/:/);
	return(0) if($zoomCoordinate !~ m/-/);
	
	my @tmp1=split(/:/,$zoomCoordinate);
	return(0) if(@tmp1 != 2);
	return(0) if($tmp1[0] eq "");
	
	my @tmp2=split(/-/,$tmp1[1]);
	return(0) if(@tmp2 != 2);
	return(0) if($tmp2[0] == $tmp2[1]);
	
	return(0) if($tmp2[0] !~ /^(\d+\.?\d*|\.\d+)$/);
	return(0) if($tmp2[1] !~ /^(\d+\.?\d*|\.\d+)$/);
	
	return(0) if($tmp2[0] > $tmp2[1]);
	
	return(1);
}

sub splitCoordinate($) {
	my $coordinate=shift;
	
	my ($coordinateChromosome,$coordinateStart,$coordinateEnd,$coordinatePosition);
	$coordinateChromosome=$coordinateStart=$coordinateEnd=$coordinatePosition="NA";
	
	my $goodCoordinateFlag=0;
	if(($coordinate ne "") and (validateZoomCoordinate($coordinate))) {
	
		($coordinateChromosome,$coordinatePosition)=split(/:/,$coordinate);
		$coordinatePosition =~ s/,//g;
	
		($coordinateStart,$coordinateEnd)=split(/-/,$coordinatePosition);
		
		$goodCoordinateFlag=1;
	}
	 
	my %coordinateData=();
	$coordinateData{ chromosome } = $coordinateChromosome;
	$coordinateData{ start } = $coordinateStart;
	$coordinateData{ end } = $coordinateEnd;
	$coordinateData{ size } = ($coordinateEnd-$coordinateStart);
	$coordinateData{ flag } = $goodCoordinateFlag;
	$coordinateData{ name } = $coordinateChromosome.":".$coordinateStart."-".$coordinateEnd;
	
	return(\%coordinateData);
}

sub header2subMatrix($$) {
	my $header=shift;
	my $extractBy=shift;
	
	my $headerObject=getPrimerNameInfo($header);
	
	my $chromosome=$headerObject->{ chromosome };
	my $region=$headerObject->{ region };
		
	my @tmp=split(/-/,$chromosome);
	my $group="amb";
	$group=$tmp[1] if(@tmp == 2);
	
	my $nakedChromosome=$chromosome;
	$nakedChromosome =~ s/chr//;
	
	my $liteChromosome=$chromosome;
	$liteChromosome =~ s/-$group//;
	
	my $subMatrix="NA";
	$subMatrix=$region if($extractBy eq "region");
	$subMatrix=$chromosome if($extractBy eq "chr");
	$subMatrix=$nakedChromosome if($extractBy eq "nakedChr");
	$subMatrix=$liteChromosome if($extractBy eq "liteChr");
	$subMatrix=$group if($extractBy eq "group");
	
	return($subMatrix);
}

sub deGroupHeader($;$$) {
	#required 
	my $header=shift;
	#optional
	my $extractBy="liteChr";
	$extractBy=shift if @_;
	my $index=undef;
	$index=shift if @_;
	$index=getSmallUniqueString() if(!defined($index));
	
	my $headerObject=getPrimerNameInfo($header);

	my $subName=$headerObject->{ subName };
	my $assembly=$headerObject->{ assembly };
	my $chromosome=$headerObject->{ chromosome };
	my $start=$headerObject->{ start };
	my $end=$headerObject->{ end };

	my $liteChromosome=header2subMatrix($header,$extractBy);

	my $deGroupedHeader=$index."|".$assembly."|".$liteChromosome.":".$start."-".$end;
	
	return($deGroupedHeader);
}

sub reOrientIntervals($$$$) {
	my $start1=shift;
	my $end1=shift;
	my $start2=shift;
	my $end2=shift;
	
	return($start1,$end1,$start2,$end2) if($start1 <= $start2);
	return($start2,$end2,$start1,$end1) if($start2 <= $start1);
	
	die("poorly formed intervals!\n\t$start1 - $end1\t$start2 - $end2\n");
}
	
sub isOverlapping($$$$;$$) {
	#required
	my $start1=shift;
	my $end1=shift;
	my $start2=shift;
	my $end2=shift;
	#optional
	my $chromosome1="NA";
	$chromosome1=shift if @_;
	my $chromosome2="NA";
	$chromosome2=shift if @_;
	
	return(0) if($chromosome1 ne $chromosome2);
	
	die("poorly formed intervals!\n\t$start1 - $end1\n") if(($start1 > $end1) or (!defined($start1)) or (!defined($end1)));
	die("poorly formed intervals!\n\t$start2 - $end2\n") if(($start2 > $end2) or (!defined($end1)) or (!defined($end2)));
	
	($start1,$end1,$start2,$end2)=reOrientIntervals($start1,$end1,$start2,$end2);

	# method 1 
	my $overlap_1 = 0;
	$overlap_1 = 1 if(max($start1,$start2) <= min($end1,$end2));

	# method 2
	my $overlap_2 = 0;
	$overlap_2 = 1 if(($start1 <= $end2) and ($start2 <= $end1));
		
	return(1) if(($overlap_1 == 1) and ($overlap_2 == 1));
	
	die("\nERROR: overlap logic failire ($overlap_1 || $overlap_2)\n") if($overlap_1 != $overlap_2);
	
	return(0);
}

sub stripChromosomeGroup($) {
	my $chromosome=shift;
	
	my @tmp=split(/-/,$chromosome);
	my $group="amb";
	$group=$tmp[1] if(@tmp == 2);
	
	my $liteChromosome=$chromosome;
	$liteChromosome =~ s/-$group//;
	
	return($liteChromosome);
}

sub getUserHomeDirectory() {
	my $userHomeDirectory = `echo \$HOME`;
	chomp($userHomeDirectory);
	return($userHomeDirectory);
}

sub getUniqueString() {
	my $UUID = `uuidgen`;
	chomp($UUID);
	return($UUID);
}

sub getSmallUniqueString() {
	my $UUID=`uuidgen | rev | cut -d '-' -f 1`;
	chomp($UUID);
	return($UUID);
}

sub getComputeResource() {
	my $hostname = `hostname`;
	chomp($hostname);
	return($hostname);
}

sub translateFlag($) {
	my $flag=shift;
	
	my $response="off";
	$response="on" if($flag == 1);	
	return($response);
}

sub getNumberOfLines($) {
	my $inputFile=shift;
	
	my $nLines = 0;
	
	if(($inputFile =~ /\.gz$/) and (!(-T($inputFile)))) {
		my $matrixInfo=`gunzip -c '$inputFile' 2>/dev/null | head -n 1 | cut -f 1`;
		if($matrixInfo =~ /(\d+)x(\d+)/) {
			chomp($matrixInfo);
			my ($nRows,$nCols) = split(/x/,$matrixInfo);
			$nLines = $nRows;
		} else { 
			$nLines = `gunzip -c '$inputFile' 2>/dev/null | grep -v "# " | wc -l`;
		}
	} else {
		$nLines = `grep -v "# " '$inputFile' | wc -l`;
	}

	chomp($nLines);
	$nLines =~ s/ //g;
	
	return($nLines);
}

sub classifyInteractionDistance($) {
	my $interactionDistance=shift;
	
	return("cis") if($interactionDistance != -1);
	return("trans") if($interactionDistance == -1);
	return("NA")
}

sub chooseOptimalMissingValue($) {
	my $inputMatrix=shift;
	
	my $num_nans=0;
	my $num_zeros=0;
	
	if(($inputMatrix =~ /\.gz$/) and (!(-T($inputMatrix)))) {
		my $num_na=`gunzip -c '$inputMatrix' | fgrep -o -w NA | wc -l`;
		chomp($num_na);
		my $num_nan=`gunzip -c '$inputMatrix' | fgrep -o -w nan | wc -l`;
		chomp($num_nan);
		$num_nans=$num_na+$num_nan;
		
		$num_zeros=`gunzip -c '$inputMatrix' | fgrep -o -w 0 | wc -l`;
		chomp($num_zeros);
	} else {
		my $num_na=`fgrep -o -w NA '$inputMatrix' | wc -l`;
		chomp($num_na);
		my $num_nan=`fgrep -o -w nan '$inputMatrix' | wc -l`;
		chomp($num_nan);
		$num_nans=$num_na+$num_nan;
		
		$num_zeros=`fgrep -o -w 0 '$inputMatrix' | wc -l`;
		chomp($num_zeros);
	}
	
	my $missingValue=0;
	if($num_nans > $num_zeros) {
		$missingValue = -7337;
	} else {
		$missingValue = 0;
	}

	return($num_zeros,$num_nans,$missingValue)
}

sub createTmpDir(;$) {
	#optional
	my $tmpDir="/tmp";
	$tmpDir=shift if @_;
	
	# remove trailing /
	$tmpDir =~ s/\/$//;
	
	my $uniq=getSmallUniqueString();
	$tmpDir = $tmpDir."/cWorld__".$uniq."/";
	
	system("mkdir -p '".$tmpDir."'");
	
	die("ERROR: could not create tmpDir (".$tmpDir.")!\n") if(!(-d($tmpDir)));
	
	return($tmpDir);
}

sub removeTmpDir($) {
	my $tmpDir=shift;
	
	die("ERROR: tmpDir does not exist! (".$tmpDir.")!\n") if(!(-d($tmpDir)));
	
	system("rm -rf '".$tmpDir."'") if($tmpDir =~ /\/cWorld__/);
}

sub headers2bed($) {
	my $input=shift;
	
	my ($matrixObject);
	if(-e $input) { # if this is a file
		$matrixObject=getMatrixObject($input);
	} elsif(exists($input->{ inc2header })) {
		$matrixObject=$input;
	} else {
		die("\nERROR: invalid input, must be either matrixObject, or inputMatrix file\n");
	}
	
	my $inc2header=$matrixObject->{ inc2header };
	my $header2inc=$matrixObject->{ header2inc };
	my $numYHeaders=$matrixObject->{ numYHeaders };
	my $numXHeaders=$matrixObject->{ numXHeaders };
	my $numTotalHeaders=$matrixObject->{ numTotalHeaders };
	my $inputMatrixName=$matrixObject->{ inputMatrixName };
	my $NA_rowcols=$matrixObject->{ NArowcols };
	
	my $headerBEDFile=getSmallUniqueString()."__".$inputMatrixName.".headers.bed";
	open(BED,outputWrapper($headerBEDFile)) || die("\nERROR: Could not open file ($headerBEDFile)\n\t$!\n\n");
	
	my $enforceValidHeader=1;
	for(my $i=0;$i<$numTotalHeaders;$i++) {
		my $header=$inc2header->{ xy }->{$i};
		
		my $headerObject=getPrimerNameInfo($header,$enforceValidHeader);
		
		my $headerChromosome="NA";
		$headerChromosome=$headerObject->{ chromosome } if(exists($headerObject->{ chromosome }));
		
		my $headerStart="NA";
		$headerStart=$headerObject->{ start } if(exists($headerObject->{ start }));
		my $headerEnd="NA";
		$headerEnd=$headerObject->{ end } if(exists($headerObject->{ end }));
		
		my $usableHeaderFlag=1;
		$usableHeaderFlag=0 if(exists($NA_rowcols->{$header}));
		
		# de group chromosome for UCSC use
		$headerChromosome=stripChromosomeGroup($headerChromosome);
		print BED "$headerChromosome\t$headerStart\t$headerEnd\t$header\t$usableHeaderFlag\n";
		
	}
	
	close(BED);
	
	die("\nERROR: could not write BED file ($headerBEDFile).\n") if(!(-e($headerBEDFile)));
	
	return($headerBEDFile);
	
	
}

sub flipBool($) {
	my $boolean=shift;
	
	die("\nERROR: invalid bool value ($boolean)\n\n") if(($boolean != 0) and ($boolean != 1));
	
	return(1) if($boolean == 0);
	return(0) if($boolean == 1);
}

sub outputWrapper($;$) {
	# required
	my $outputFile=shift;
	# optional
	my $outputCompressed=0;
	$outputCompressed=shift if @_;
	
	$outputCompressed = 1 if($outputFile =~ /\.gz$/);
	$outputFile .= ".gz" if(($outputFile !~ /\.gz$/) and ($outputCompressed == 1));
	$outputFile = "| gzip -c > '".$outputFile."'" if(($outputFile =~ /\.gz$/) and ($outputCompressed == 1));
	$outputFile = ">".$outputFile if($outputCompressed == 0);
	
	return($outputFile);
}

sub inputWrapper($) {
	my $inputFile=shift;
	
	$inputFile = "gunzip -c '".$inputFile."' | " if(($inputFile =~ /\.gz$/) and (!(-T($inputFile))));
	
	return($inputFile);
}

1;

__END__

=head1 NAME

cWorld - Perl extension for interfacing with my5C (3C/5C/HiC Data analysis).
http://my5C.umassmed.edu

=head1 SYNOPSIS

use cWorld;  

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head1 SEE ALSO

Please see website for module details.
website: my5C.umassmed.edu

=head1 AUTHOR

bryan lajoie, E<lt>bryan.lajoie@umassmed.edu<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by bryan lajoie; gaurav jain; job dekker;

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
