#!/usr/bin/perl -w
use strict;
use IO::Socket;
#use Thread;
use Time::HiRes qw ( time alarm sleep );



my $dump_dir="./DUMP";
my $socket;
my $loc_port=5000;
my $LEN=4096;
my $message;
my $answer;
my $cl_port;
my $cl_ip;
my $cl_addr;
my $time;

my %data;
my $peer;
my $log="./SERVER.log";
my $do_log=0;
my $do_debug=0;

###########################################################################
#print STDERR "
###########################
#commands:
#	CREATE;ID;BUF_LEN
#		create buffer for ID with length BUF_LEN
#
#	DEL;ID
#		delete buffer for ID
#
#	LIST;ID;BUF_LEN
#		list last BUF_LEN records for ID
#
#	PUSH;ID;VAL
#		insert new VAL for ID
#
#	DUMP;ALL
#		dump structure of all buffers into file 
#
#	LOAD;LAST
#		load buffers structure from las dump file
#
#	SEARCH;ID
#		serch for buffers id like ID
#
#	INC;ID;VAL
#		increase value of ID by VAL
#
#	READRESET;ID
#		get last val of ID and reset it to ZERO
#	
#	DELAY;TIME
#		get time difference Trecieve-Tsend
#
#	LOG_ON
#		start LOG
#
#	LOG_OFF
#		stop LOG
#
#	DEBUG
#                start debug messages
#
#        NO_DEBUG
#                stop debug messages
#
###########################
#\n";
###########################################################################
#############################################################################
#open (LOG, ">$log");
$socket=IO::Socket::INET->new(	
				LocalPort=>$loc_port,
				#LocalAddr=>"10.1.7.117",
				Proto=>"udp",
				Type=>SOCK_DGRAM,
				ReuseAddr=>1,
				) or die "can't make socket: $@/n";
#print "START.....\n";
#print "READY\n";
do {
	$peer=recv($socket,$message,$LEN,0);
	$time=time();
	($cl_port,$cl_ip)=sockaddr_in($peer);
	$cl_addr=inet_ntoa($cl_ip);
        #$cl_addr=gethostbyaddr($cl_ip,AF_INET);

	#print "RCVD: ",scalar(localtime($time)),"  $cl_addr($cl_ip):$cl_port>$message\n";
	#print "RCVD: ",scalar(localtime($time))," $cl_addr:$cl_port >$message\n";
	if ($do_log==1){
		print LOG "RCVD: ",scalar(localtime($time))," $cl_addr:$cl_port >$message\n";
	}
	if ($do_debug==1){
                print "RCVD: ",scalar(localtime($time))," $cl_addr:$cl_port >$message\n";
        }


	if (defined($answer=parse_message($message,$time,$peer))){
		send($socket,$answer,0,$peer);
		if ($do_log==1){
			print LOG "$answer\n";
		}
		if ($do_debug==1){
                        print "$answer\n";
                }

	}
	#print "READY\n";
}until (!defined($message,));
#close(LOG);
exit();
##############################################################################
###################
sub parse_message {
	my $mess=shift;
	my $time=shift;
	my $peer=shift(@_);
	my $sep=";";
	my $i;
	my ($cmd,@arg)=split (/$sep/,$mess);
	my $result;

	#########
	#print  "COMMAND PARSER:\n";
	#print scalar(localtime($time))," CMD:$cmd \n";
	#for ($i=0;$i<scalar(@arg);$i++){
	#	print "\tARG$i:$arg[$i]\n";
	#}
	#print  "\n";
	#########

	if ($cmd eq "CREATE"){
		$result=f_create(@arg);
	}
	
	if ($cmd eq "DEL"){
		$result=f_del(@arg);
	}
	
	if ($cmd eq "LIST"){
		$result=f_list(@arg);
	}

	if ($cmd eq "PUSH"){
		$result=f_push($time,@arg);
	}
	
	if ($cmd eq "DUMP"){
		$result=f_dump(@arg);
	}

	if ($cmd eq "LOAD"){
		$result=f_load($peer,@arg);
	}
	
	if ($cmd eq "SEARCH"){
		$result=f_search($peer,@arg);
	}

	if ($cmd eq "INC"){
                $result=f_inc($time,@arg);
        }
	
	if ($cmd eq "READRESET"){
                $result=f_readreset($time,@arg);
        }

	if ($cmd eq "DELAY"){
		$result=f_delay($time,@arg);
	}	
	
	if ($cmd eq "LOG_ON"){
                $result=f_log_on($time);
        }

	if ($cmd eq "LOG_OFF"){
                $result=f_log_off($time);
        }

	if ($cmd eq "DEBUG"){
                $result=f_debug_on($time);
        }

        if ($cmd eq "NO_DEBUG"){
                $result=f_debug_off($time);
        }


	####################
	####################
        #if ($result=~/FAIL/){
        #        #print "CMD RESULT: $result\n";
        #        print "-";
        #}else{
        #        print "+";
        #}

	return ($result);
}
##############
sub f_create {
	my @arg=@_;
	my $id		=$arg[0];
	my $buf_len	=$arg[1];

	my $i;

	my $comment;
	
	if (exists($data{$id})){
                return("FAIL CREATE ALWAYS PRESENT:$id");
        }

	if((!defined($buf_len))||($buf_len<=0)){
		$buf_len=1;
	}
	
	${$data{$id}}{"len"}	=$buf_len;
	${$data{$id}}{"point"}	=0;
	for ($i=0;$i<$buf_len;$i++){
		#print ".";
		${${$data{$id}}{"data"}}[$i]="U";
		${${$data{$id}}{"time"}}[$i]="U";
	}
	#print "\n";
	$comment="OK buffer for $id with length=$buf_len created...";
	return ($comment);
}
###########
sub f_del {
	my @arg=@_;
        my $id          =$arg[0];
	my $comment;
	my $count;
	
	if (!exists($data{$id})){
		return("FAIL");
	}

	$count=delete($data{$id});
	if ($count>0){
		$comment="OK buffer for $id deleted...";
	}else{
		$comment="FAIL NOTHING DELETED...";
	}
	return($comment);
}
############
sub f_list {
	my @arg=@_;
        my $id          =$arg[0];
        my $buf_len     =$arg[1];

	my $i;
	my $last;
	my $count;

	my @data;
	my @time;
	my @index;

	my $comment;
	my $cur_time=time;

	if (!exists($data{$id})){
		$comment="FAIL LIST NO SUCH ID: $id";
		return($comment);
	}

	$last=${$data{$id}}{"point"};
	
	if ($buf_len>scalar(@{${$data{$id}}{"data"}}) ){
		$buf_len=scalar(@{${$data{$id}}{"data"}});
	}

	$count=$buf_len;
	for ($i=$last;$i>=0; $i--){
		push (@data,${${$data{$id}}{"data"}}[$i]);
		push (@time,${${$data{$id}}{"time"}}[$i]);
		push (@index,$i);
		$count--;
	}
	if ($count >0){
		for ($i=(scalar(@{${$data{$id}}{"data"}})-1);$i>=(scalar(@{${$data{$id}}{"data"}}) - $count); $i--){
			push (@data,${${$data{$id}}{"data"}}[$i]);
                       	push (@time,${${$data{$id}}{"time"}}[$i]);
			push (@index,$i);
		}
	}
	
	$comment.="OK ID:$id LAST $buf_len elements at $cur_time:\n";
	for ($i=0;$i<$buf_len;$i++){
		if ((defined($index[$i]))&&($index[$i]==$last)){
			$comment.="*";
		}
		$comment.="\t".join("\t",$index[$i],$time[$i],$data[$i])."\n";
	}
	
	return ($comment);
}
############
sub f_push {
	my @arg=@_;
	my $time	=$arg[0];
        my $id          =$arg[1];
	my $val		=$arg[2];

	#my $time	=$arg[scalar(@arg)-1];

	my $last;

	my $comment;
	
	if (!exists($data{$id})){
		$comment="FAIL PUSH NO SUCH ID: $id";
                return($comment);
        }

	$last=${$data{$id}}{"point"};
	if ($last==(scalar(@{${$data{$id}}{"data"}})-1)){
		$last=0;
		${$data{$id}}{"point"}=0;
		#print "last=$last\n";	
	}elsif($last<(scalar(@{${$data{$id}}{"data"}})-1)){
		$last++;
		${$data{$id}}{"point"}=$last;
		#print "*last=$last\n"; 
	}else{
		$comment="FAIL";
		return($comment);
	}
	
	${${$data{$id}}{"data"}}[$last]= $val;
	${${$data{$id}}{"time"}}[$last]= $time;
	
	$comment="OK ID:$id VAL=$val and time=".scalar(localtime($time))." AS $last element";

	return($comment);
}
############
sub f_dump {
	my @arg=@_;
	my $comment="";
	my $id;
	my $count=0;
	my $n;

	if ($arg[0] ne "ALL"){
		return("FAIL");
	}
	my $time=time();
	open (DUMP, ">$dump_dir/dump.$time.txt") || 
					do {
						$comment="FAIL can't open file :$!";
						return ($comment);
					};
	foreach $id (keys %data){
		$n=scalar(@{${$data{$id}}{"data"}});
		print DUMP join(";","CREATE",$id,$n),"\n";
		$count++;
	}
	close(DUMP);
	$comment="OK dump $count parameter's info in dump.$time.txt";
	return ($comment);
}
###########
sub f_load {
	my $peer=shift(@_);
	my @arg=@_;
        my $comment="";
	my $file;
	my @files;
	my $string;
	my $time=time();

	if ($arg[0] eq "LAST"){
		opendir (DIR, "DUMP") ||
						do{
							$comment="FAIL can't open dir:$!";
							return($comment);
						};
		while (defined($file=readdir(DIR))){
			if ($file=~/dump.(\d+\.+\d+)\.txt/) {
			#if ($file=~/dump.([\d]*)\.txt/) {
				push (@files,$1);
			}
		}
		closedir(DIR);
		@files = sort {$b <=> $a} @files;
		$file=$files[0];
		#print "last file... $file\n";
		
		open (CMD, "<$dump_dir/dump.$file.txt") ||
								do {
									$comment="FAIL can't open file:$!";
									return($comment);
								};
		while (defined ($string=<CMD>)){
			chomp($string);
			if (defined($answer=parse_message($string,$time))){
		               send($socket,$answer,0,$peer);
        		}
		}
		close(CMD);
		$comment="OK load file $file";
	}else{
		return();
	}
}
###########
sub f_search {
	my $peer=shift(@_);
	my @arg=@_;
	my $trap=$arg[0];
	my $id;
	my $found;
	my $dim;
	my $answer;
	my $count=0;

	foreach $id (keys %data){
		if ($id=~/$trap/){
			$dim=scalar(@{${$data{$id}}{"data"}});
			$answer="$count FOUND ID:>$id< DIM:$dim";
			send($socket,$answer,0,$peer);
			$count++;
		}
	}
	if ($count>0){
		return ("OK SEARCH FOR >$trap< TOTAL:$count");
	}else{
		return("FAIL");
	}
	
}
###########
sub f_inc {
        my @arg=@_;
	my $time	=$arg[0];
        my $id          =$arg[1];
        my $val         =$arg[2];
	if (!defined ($val)){
		$val=1;
	}

        #my $time        =$arg[scalar(@arg)-1];

        my $last;
	my $prev;

        my $comment;

        if (!exists($data{$id})){
                $comment="FAIL INC NO SUCH ID: $id";
                return($comment);
        }

        $prev=$last=${$data{$id}}{"point"};
        if ($last==(scalar(@{${$data{$id}}{"data"}})-1)){
                $last=0;
                ${$data{$id}}{"point"}=0;
                #print "last=$last\n";  
        }elsif($last<(scalar(@{${$data{$id}}{"data"}})-1)){
                $last++;
                ${$data{$id}}{"point"}=$last;
                #print "*last=$last\n"; 
        }else{
                $comment="FAIL";
                return($comment);
        }
	
	if (${${$data{$id}}{"data"}}[$prev] eq "U"){
                ${${$data{$id}}{"data"}}[$last]= $val;
        }else{
        	${${$data{$id}}{"data"}}[$last]= ${${$data{$id}}{"data"}}[$prev] + $val;
        }
	${${$data{$id}}{"time"}}[$last]= $time;

        $comment="OK ID:$id VAL=".${${$data{$id}}{"data"}}[$last]." and time=".scalar(localtime($time))." AS $last element";

        return($comment);
}
##########
sub f_readreset {
        my @arg=@_;
	my $time	=$arg[0];
        my $id          =$arg[1];

#        my $time        =$arg[scalar(@arg)-1];

        my $last;
	my $prev;

	my $cur_time=time;

        my $comment;

        if (!exists($data{$id})){
                $comment="FAIL INC NO SUCH ID: $id";
                return($comment);
        }

        $prev=$last=${$data{$id}}{"point"};
        if ($last==(scalar(@{${$data{$id}}{"data"}})-1)){
                $last=0;
                ${$data{$id}}{"point"}=0;
                #print "last=$last\n";  
        }elsif($last<(scalar(@{${$data{$id}}{"data"}})-1)){
                $last++;
                ${$data{$id}}{"point"}=$last;
                #print "*last=$last\n"; 
        }else{
                $comment="FAIL";
                return($comment);
        }
	
	
	$comment.="OK ID:$id LAST 1 element at $cur_time:\n";
        $comment.="*";
        $comment.="\t".join("\t",$prev,${${$data{$id}}{"time"}}[$prev],${${$data{$id}}{"data"}}[$prev])."\n";


        ${${$data{$id}}{"data"}}[$last]= 0;
        ${${$data{$id}}{"time"}}[$last]= $time;

        $comment.="OK ID:$id VAL=0 and time=".scalar(localtime($time))." AS $last element";

        return($comment);
}
#############
sub f_delay {
	my @arg=@_;
	my $timeR=$arg[0];
	my $timeS=$arg[1];
	my $comment=$timeR-$timeS;
	return ("OK: delay=$comment");
}
#############
sub f_log_on {
	my $time=shift(@_);
	open (LOG, ">$log") or return ("FAIL can't start log :$!");
	$do_log=1;
	return("OK start log at ".localtime($time) );
}

sub f_log_off {
        my $time=shift(@_);
        close (LOG) or return ("FAIL can't close log :$!");
        $do_log=0;
        return("OK stop log at ".localtime($time) );
}
#############
sub f_debug_on {
	$do_debug=1;
	return("OK start debug messages at ".localtime($time) );
}

sub f_debug_off {
        $do_debug=0;
        return("OK stop debug messages at ".localtime($time) );
}

