#!/usr/bin/perl -w
use strict;
use IO::Socket;

my $socket;
my $server=shift(@ARGV);
my $message="@ARGV";
my $server_port=5000;
my $LEN=4096;
my $timeout=1;
my $wait=0;


print "opening udp... \n";

$socket=IO::Socket::INET->new(Proto=>"udp",
				PeerPort=>$server_port,
				PeerAddr=>$server,
				Type=>SOCK_DGRAM
				) or die "can't make socket to $server:$server_port :$!\n";
print "sent to $server:$server_port \n";

$socket->send($message) or die "can't send message:$!\n";

print "waiting for $server:$server_port \n";


#while ($wait==0){

	eval{
		local $SIG{ALRM} = sub {
					#print "timeout!\n";
					$wait=1;
					};
		alarm $timeout;

		$socket->recv($message, $LEN) or print "$!\n";
		alarm 0;
		print "$message\n";

	} or    return();
#}


