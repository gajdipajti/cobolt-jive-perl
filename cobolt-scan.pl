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

#	Run:		code/cobolt-scan.pl 5 0.031 0.300

use strict;
use warnings;
use feature qw(say);	# For 5.10 extra function.
use Device::SerialPort;	# Set up the serial port
my $port = Device::SerialPort->new("/dev/ttyUSB0");	# FIXME: chmod 777

# Global Variables
my $Sleep;
my $PowerHigh;
my $PowerLow;

# Input Parsing
if ($#ARGV != 2)
    {	say "#W# Using default values!";
	$Sleep = 5;			# 5 sec
	$PowerHigh = 0.300;		# 300 mW
	$PowerLow  = 0.031;		#  31 mW
    } else {
	$Sleep = $ARGV[0];
	$PowerHigh = $ARGV[2];
	$PowerLow  = $ARGV[1];
}

# Input check
if ( ($PowerHigh > 0.315) || ($PowerLow > 0.315) )	{ die "#E# Laser power to high!\n"; }
if ( ($PowerHigh < 0.030) || ($PowerLow < 0.030) )	{ die "#E# Laser power to low!\n";  }

# Input user check
say "#Sleep:\t$Sleep\nPower:\t$PowerLow <-> $PowerHigh";

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

my $i=0;		#i terator
while(($PowerLow+$i*0.005)<$PowerHigh) {
    my $current = $PowerLow+$i*0.005;
    print "#$i; ".time()."; Set:";
    $port->write("p $current\r"); say "$current";
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
    $i++;
}
# Laser Off
$port->write("l0\r");
sleep(1);
my $o = $port->lookfor();
$o =~ s/\r//;
if ($o) { say "LaserOff Response: $o;\n<<<EOL>>>"; }
$port->close || die "# failed to close port";;
undef $port;