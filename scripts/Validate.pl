#!/usr/bin/perl

use strict;
use Getopt::Long;

my $tFile = '';
my $zFile = '';;
my $help = '';
my $quiet = '';
my $outFile = "Conf.csv";

my $USAGE = <<"USAGE";
Usage: ./Validate.pl --cfile=clustering.csv --sfile=species.csv

Regular options:

--ofile    filename -- outputfile for confusion matrix default Conf.csv
--quiet             -- suppress variable names
--help      

USAGE

GetOptions("cfile=s"   => \$tFile,"sfile=s"  => \$zFile, "ofile=s" => \$outFile, 'quiet' => \$quiet, 'help' => \$help) or die("Error in command line arguments\n");

if ($help ne '') {print $USAGE;}

die $USAGE unless ($tFile ne '' && $zFile ne '');


my @t = ();
my $maxt = 0;
my $N = 0;
my $S = 0;
my %hashCluster = {};

open(FILE, $tFile) or die "Can't open $tFile";

while(my $line = <FILE>){
  $N++;
  chomp($line);
  
  my @tokens = split(/,/,$line);

  my $name = $tokens[0];
  my $cluster = $tokens[1];

  $hashCluster{$name} = $cluster;
  #print "$name $cluster\n";
  if($cluster > $maxt){
    $maxt = $cluster;
  }
}

close(FILE);

open(FILE, $zFile) or die "Can't open $zFile";


my %hashC = {};
my $count = 0;
while(my $line = <FILE>){
  chomp($line);

  my @tokens = split(/,/,$line);

  my $name = $tokens[0];

  if($hashCluster{$name} ne undef){
    my $tcluster = $hashCluster{$name};

    #print "$name $tcluster\n";

    my $genus = $tokens[1];
    #print "$genus\n";
    if($hashC{$genus} eq undef){
      my @temp = ();

      for(my $i = 0; $i < $maxt + 1; $i++){
	$temp[$i] = 0;
      }

      $temp[$tcluster]++;

      $hashC{$genus} = \@temp;
    }
    else{
      @{$hashC{$genus}}[$tcluster]++;
    }
    $count++;
    $S++;
  }
}

close(FILE);

my $classcount = 0;
my @cluster = ();
my $j = 0;

open(OUTFILE,">$outFile") or die "Can't open $outFile\n";

printf OUTFILE "Taxa,";

for(my $i = 0; $i < $maxt; $i++){
  printf OUTFILE "D%d,",$i;
}
printf OUTFILE "D%d\n",$maxt;

foreach my $key(sort keys %hashC){
  if($hashC{$key} ne undef){
    my @temp = @{$hashC{$key}};
    my $ptotal = 0;
    
    for(my $i = 0; $i < $maxt + 1; $i++){
      $ptotal += $temp[$i];
    }

    if($ptotal > 0){

      for(my $i = 0; $i < $maxt + 1; $i++){
	$cluster[$i][$j] = $temp[$i];
      }
      $j++;

      my $cTemp = join(",",@temp);

      print OUTFILE "$key,$cTemp\n";
    }
  }
}

close(OUTFILE);

if($quiet eq ''){
  printf("N\tM\tK\tC\tRec.\tPrec.\tNMI\tRand\tAdjRand\n");
}
printf("%d\t%d\t%d\t%d\t%f\t%f\t%f\t%f\t%f\n",$N,$S,$j,$maxt + 1,recall(@cluster),precision(@cluster),nmi(@cluster),randindex(@cluster),adjrandindex(@cluster));

sub precision(){
   my @cluster = @_;
   my $nN = 0;
   my $nC = scalar(@cluster);
   my $nK = scalar(@{$cluster[0]});
   my $precision = 0;

   for(my $i = 0; $i < $nC; $i++){
     my $maxS = 0;

     for(my $j = 0; $j < $nK; $j++){
       if($cluster[$i][$j] > $maxS){
	 $maxS = $cluster[$i][$j];
       }
       
       $nN += $cluster[$i][$j];
     }
     $precision += $maxS;
   } 

   return $precision/$nN;
}

sub recall(){
   my @cluster = @_;
   my $nN = 0;
   my $nC = scalar(@cluster);
   my $nK = scalar(@{$cluster[0]});
   my $recall = 0;

   for(my $i = 0; $i < $nK; $i++){
     my $maxS = 0;

     for(my $j = 0; $j < $nC; $j++){
       if($cluster[$j][$i] > $maxS){
	 $maxS = $cluster[$j][$i];
       }
       
       $nN += $cluster[$j][$i];
     }
     
     $recall += $maxS;
   } 

   return $recall/$nN;
}

sub choose2{
  my $N = shift;
  my $ret = $N*($N - 1);

  return int($ret/2);
}

sub randindex{
 my @cluster = @_;
 my @ktotals = ();
 my @ctotals = ();
 my $nN = 0;
 my $nC = scalar(@cluster);
 my $nK = scalar(@{$cluster[0]});
 my $cComb = 0;
 my $kComb = 0;
 my $kcComb = 0;
 
 for(my $i = 0; $i < $nK; $i++){
   $ktotals[$i] = 0;
   for(my $j = 0; $j < $nC; $j++){
     $ktotals[$i]+=$cluster[$j][$i];
   }
   $nN += $ktotals[$i];
   $kComb += choose2($ktotals[$i]);
 }
  		 
  
 for(my $i = 0; $i < $nC; $i++){
   $ctotals[$i] = 0;
   for(my $j = 0; $j < $nK; $j++){
     $ctotals[$i]+=$cluster[$i][$j];
   }
   $cComb += choose2($ctotals[$i]); 
 }

 for(my $i = 0; $i < $nC; $i++){
   for(my $j = 0; $j < $nK; $j++){
     $kcComb += choose2($cluster[$i][$j]);
   }
 }

 my $nComb = choose2($nN);

 return ($nComb - $cComb - $kComb + 2*$kcComb)/$nComb;

}

sub adjrandindex{
 my @cluster = @_;
 my @ktotals = ();
 my @ctotals = ();
 my $nN = 0;
 my $nC = scalar(@cluster);
 my $nK = scalar(@{$cluster[0]});
 my $cComb = 0;
 my $kComb = 0;
 my $kcComb = 0;
 
 for(my $i = 0; $i < $nK; $i++){
   $ktotals[$i] = 0;
   for(my $j = 0; $j < $nC; $j++){
     $ktotals[$i]+=$cluster[$j][$i];
   }
   $nN += $ktotals[$i];
   $kComb += choose2($ktotals[$i]);
 }
  		 
  
 for(my $i = 0; $i < $nC; $i++){
   $ctotals[$i] = 0;
   for(my $j = 0; $j < $nK; $j++){
     $ctotals[$i]+=$cluster[$i][$j];
   }
   $cComb += choose2($ctotals[$i]); 
 }

 for(my $i = 0; $i < $nC; $i++){
   for(my $j = 0; $j < $nK; $j++){
     $kcComb += choose2($cluster[$i][$j]);
   }
 }

 my $nComb = choose2($nN);
 
 my $temp = ($kComb*$cComb)/$nComb;

 my $ret = $kcComb - $temp;

 return $ret/(0.5*($cComb + $kComb) - $temp);

}



sub nmi{
  my @cluster = @_;
  my @ktotals = ();
  my @ctotals = ();
  my $nN = 0;
  my $nC = scalar(@cluster);
  my $nK = scalar(@{$cluster[0]});
  my $HC = 0.0;
  my $HK = 0.0;

  for(my $i = 0; $i < $nK; $i++){
    $ktotals[$i] = 0;
    for(my $j = 0; $j < $nC; $j++){
      $ktotals[$i]+=$cluster[$j][$i];
    }
    $nN += $ktotals[$i];
  }
  		 
  
  for(my $i = 0; $i < $nC; $i++){
    $ctotals[$i] = 0;
    for(my $j = 0; $j < $nK; $j++){
      $ctotals[$i]+=$cluster[$i][$j];
    }
    my $dFC = $ctotals[$i]/$nN;
    if($dFC > 0.0){
      $HC += -$dFC*log($dFC);
    }
  }

  for(my $i = 0; $i < $nK; $i++){
    my $dFK = $ktotals[$i]/$nN;
    if($dFK > 0.0){
      $HK += -$dFK*log($dFK);
    }
  }
  
  
  my $NMI = 0.0;

  for(my $i = 0; $i < $nK; $i++){
    my $NMII = 0.0;

    for(my $j = 0; $j < $nC; $j++){
      if($ctotals[$j] >0 && $ktotals[$i] > 0){
	my $dF = ($nN*$cluster[$j][$i])/($ctotals[$j]*$ktotals[$i]);
	if($dF > 0.0){
	  $NMII += $cluster[$j][$i]*log($dF);
	}
      }
    }
    $NMII /= $nN;
    $NMI += $NMII;
  }

  return (2.0*$NMI)/($HC + $HK);
}
