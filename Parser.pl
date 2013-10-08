###################################################################################################################
#																												  #
#									Parser for TrackLocation App files											  #
#																												  #
###################################################################################################################


#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use POSIX;

# Accept the argument from user
my $path = $ARGV[0];

my @latitude;															# To store all latitude values
my @longitude;															# To store all longitude values
my @time;																# To store the time difference
my @type;																# To store type of the record (from GPS or skyhook)
my @accuracy;															# To store accuracy for each record
my $count = 1;
my $count1;															    # Counter for maintaining no. of types found
my $count2;
my $lasttype = 0;														# To store last type so that duplicates won't be considered
my $lastlatitude = 0;													# To store last latitude for the same reason

# Exit gracefully if argument is not provided
if (not defined $path){
	print "Please provide path of file to be parsed\n";
	exit $!;
}

# Open the file and perform operations
open (MYFILE, $path) or die $!;
while(<MYFILE>){
	chomp;
	my $line = $_;
	$line =~ s/  / /g;                                                  # Remove extra spaces
	$line=~ s/: /:/g;                                                   # Remove extra space after semicolon
	my @values = split(' ', $line);
	
	### Skip irrelevant lines
	if (scalar@values<4){
		next;
	}
	my $i = 1;
	my $j = 1;
	my $flag = 0;
	
	### Exclude duplicate rows
	
	if ($values[0] == 1 || $values[0] == 8){
		$flag = 1 if ($values[0] == $lasttype && $values[2] == $lastlatitude); 
		next if($values[4] > 75);                                       # Ignore values with very very less accuracy
	}

	next if ($flag == 1);                                               # Exclude if duplicate row found	
	
	foreach my $item(@values){	
		if ($i == 1 && $item != 1 && $item != 8){	
				last;	
		}				
		$count1++ if ($i == 1 && $item == 1);
		$count2++ if ($i == 1 && $item == 8);
		
		### To get exact longitude and latitude			
		if ($i==5){
				push (@accuracy,$item);
				last;
			}
			push (@type,$item) if ($i == 1);
			push (@time,$item) if ($i == 2);
			push (@latitude,$item) if ($i == 3);
			push (@longitude,$item) if ($i == 4);	

		### For checking duplicate rows store last values
		if ($i == 1){
			$lasttype = $item;
		}
		if ($i == 3){
			$lastlatitude = $item;		
		}
		$i++;
	}	
}
close (MYFILE);



### Process results collected and choose the best co-ordinates

my $f = 0;
my $finaltype;												# Final type to be printed								
my $finaltime;												# Final time to be printed
my $finallat;												# Final latitude to be printed
my $finallong;												# Final longitude to be printed
my $finalacc;												# Final Accuracy to be printed
my $year;
my $month;
my $day;
my $hour;
my $min;
my $sec;
my $milisec;
my @finallatitude;
my @finaltype;
my @finaltime;												# To store the time difference
my @finallongitude;
my @finalaccuracy;

while($f != scalar@accuracy){
	if (($type[$f]==1 && $type[$f+1]==8) || ($type[$f] == 8 && $type[$f+1]==1) ){
		
		my @times = split(':',$time[$f]);
		my @times1 = split(':',$time[$f+1]);
		my $c = 0;
		
		if ($times[3] == $times1[3] && $times[4] == $times1[4] && $times[5] == $times1[5]){ # averaging rows of 1 and 8 taken at same second
			
			if (abs($accuracy[$f]-$accuracy[$f + 1]) <= 20){	
				
				$year = ceil(($times[0] + $times1[0])/2); 							#calculate year
				$month = ceil(($times[1] + $times1[1])/2) if ($times[1] != 12); 	#calculate month
				$month = $times1[1] if($times[1] == 12);
				$day = ceil(($times[2] + $times1[2])/2) if ($times[2] != 31); 		#calculate day
				$day = $times1[2] if ($times[2] == 31);
				$hour = ceil(($times[3] + $times1[3])/2) if ($times[3] != 23);	 	#calculate hour
				$hour = $times1[3] if ($times[3] == 23);
				$min = ceil(($times[4] + $times1[4])/2) if ($times[4] != 59); 		#calculate minutes
				$min = $times1[4] if ($times[4] == 59);
				$sec = ceil(($times[5] + $times1[5])/2) if ($times[5] != 59); 		#calculate seconds
				$sec = $times1[5] if ($times[5] == 59);
				$milisec = ceil(($times[6] + $times1[6])/2) if ($times[6] != 999); 	#calculate miliseconds
				$milisec = $times1[6] if ($times[6] == 999);
				
				$finaltype = 9; 													# Average of skyhook and gps
				$finaltime = join(':',$year,$month,$day,$hour,$min,$sec,$milisec);		
				$finallat = ($latitude[$f] + $latitude[$f + 1]) / 2;
				$finallong = ($longitude[$f] + $longitude[$f + 1]) / 2;
				$finalacc = ($accuracy[$f] + $accuracy[$f + 1]) / 2;
				$f = $f + 2;				
			}else{
				my $which;
				$which = $f if ($accuracy[$f]<$accuracy[$f + 1]);
				$which = $f+1 if ($accuracy[$f]>$accuracy[$f + 1]);
				$finaltype = $type[$which];
				$finaltime = $time[$which];
				$finallat = $latitude[$which];
				$finallong = $longitude[$which];
				$finalacc = $accuracy[$which];		
				$f = $f + 2 if ($accuracy[$f]<$accuracy[$f + 1]);
				$f++ if ($accuracy[$f]>$accuracy[$f + 1]);
			}
		}else{
			$finaltype = $type[$f];
			$finaltime = $time[$f];
			$finallat = $latitude[$f];
			$finallong = $longitude[$f];
			$finalacc = $accuracy[$f];
			$f++;
		}
	}else{
		$finaltype = $type[$f];
		$finaltime = $time[$f];
		$finallat = $latitude[$f];
		$finallong = $longitude[$f];
		$finalacc = $accuracy[$f];
		$f++;
	}
	
	$finallat = sprintf("%.6f", $finallat);											# Get result upto 6 decimal points
	$finallong =sprintf("%.6f", $finallong);										# Get result upto 6 decimal points
	
	### Push all the values in respective array
	push(@finaltype,$finaltype);push(@finaltime,$finaltime);push(@finallatitude,$finallat);push(@finallongitude,$finallong);push(@finalaccuracy,$finalacc);	

}

my $l = 0;
my $first = 1;
my $last = 1;
my $starttime;
my $endtime;
my $commonlat;
my $commonlong;
my $commonacc;
open (RESULT, "> results.txt");														# Write the results in results.txt file
print RESULT "From\t\t\t\t\tTo\t\t\t\t\tLatitude\tLongitude\tAccuracy\n";					# Header line
while ($l != scalar@finallatitude){
	$starttime = $finaltime[$l] if ($last == 1);
	
	if (($finallatitude[$l] == $finallatitude[$l + 1]) && ($finallongitude[$l] == $finallongitude[$l + 1])){
		$last++;
		$l++;
		next;
	}
	$endtime = $finaltime[$l];
	
	my @starttimesplit=split(':',$starttime);
	my @endtimesplit=split(':',$endtime);	
	$commonlat = $finallatitude[$l];
	$commonlong = $finallongitude[$l];	
	$commonacc = $finalaccuracy[$l];
	print RESULT $starttimesplit[3]."h ".$starttimesplit[4]."m ".$starttimesplit[5]."s\t\t\t\t".$endtimesplit[3]."h ".$endtimesplit[4]."m ".$endtimesplit[5]."s\t\t\t".$commonlat."\t".$commonlong."\t".$commonacc."\n";
	$last = 1;
	$l++
}
close(RESULT);

###################################################### THE END ####################################################