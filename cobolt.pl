#!/usr/bin/perl -w
#	Summary:	Cobolt Laser Triggered output.
#	Version:	0.1 (2015-02-11)
#	Package:	adoptim-lab
#	License:	http://creativecommons.org/licenses/by-sa/3.0/
#	Developer:	gajdost
#	Name:		Gajdos Tamás
#	Company:	Department of Physics, University of Szeged
#	Contact info:	gajdos.tamas@outlook.com
#	Changelog:	
#	Known limits:	

#	Run:		code/cobolt.pl 3600 120 0.031 0.300

use strict;
use warnings;
use feature qw(say);	# For 5.10 extra function.
use Device::SerialPort;	# Set up the serial port
my $port = Device::SerialPort->new("/dev/ttyUSB0");	# FIXME: chmod 777

# Global Variables
my $MeasurementDuration;
my $Sleep;
my $PowerHigh;
my $PowerLow;

# Input Parsing
if ($#ARGV != 3)
    {	say "#W# Using default values!";
	$MeasurementDuration = 3600;	# 1 hour
	$Sleep = 120;			# 2 minutes
	$PowerHigh = 0.300;		# 300 mW
	$PowerLow  = 0.031;		#  31 mW
    } else {
	$MeasurementDuration = $ARGV[0];
	$Sleep = $ARGV[1];
	$PowerHigh = $ARGV[3];
	$PowerLow  = $ARGV[2];
}

# Input check
if ( ($PowerHigh > 0.315) || ($PowerLow > 0.315) )	{ die "#E# Laser power to high!\n"; }
if ( ($PowerHigh < 0.030) || ($PowerLow < 0.030) )	{ die "#E# Laser power to low!\n";  }
if ( $MeasurementDuration < 10 )			{ die "#E# Measure Duration is low\n";}

# Input user check
say "#Input: Measurement Duration:\t$MeasurementDuration;\nSleep:\t$Sleep\nPower:\t$PowerLow <-> $PowerHigh";

# 115200@8N1
$port->baudrate(115200); 
$port->databits(8);
$port->parity("none");
$port->stopbits(1);
say "# connection setup complete 115200 8N1";
$port->write("sn?\r");
sleep(1);
my $serial = $port->lookfor();	# Read data out
if ($serial) { say "# Serial: $serial"; }
undef $serial;

$port->write("hrs?\r");
sleep(1);
my $hours = $port->lookfor();	# Read data out
if ($hours) { say "# Operating Hours: $hours"; }
undef($hours);

my $tEnd = time()+$MeasurementDuration;
my $i=0;		#i terator
while(time()<$tEnd) {
    print "#$i; ".time()."; Set:";
    if ($i++ %2) { $port->write("p $PowerLow\r"); say "$PowerLow";	}
    else	 { $port->write("p $PowerHigh\r"); say "$PowerHigh";	}
    sleep(1);
    my $out = $port->lookfor();
    $out =~ s/\r//;
    if ($out) { print " Response: $out;"; }
    $port->write("i?\r");
    sleep(1);
    my $amper = $port->lookfor();
    $amper =~ s/\r//;
    if ($amper) { print " $amper;";}
    $port->write("p?\r");		# Send data with carrige return
    sleep(1);
    my $char = $port->lookfor();	# Read data out
    $char =~ s/\r//;
    if ($char) { say " $char;"; }
    sleep ($Sleep-3);
}
# Laser Off
$port->write("l0\r");
sleep(1);
my $o = $port->lookfor();
$o =~ s/\r//;
if ($o) { say "LaserOff Response: $o\n<<<EOF>>>"; }
$port->close || die "# failed to close port";;
undef $port;