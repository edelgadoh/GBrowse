#!/usr/bin/perl

use strict;
use Getopt::Long;
use FindBin '$Bin';
use lib "$Bin/../libnew";

use Bio::Graphics::Browser::Render::Server;
use constant DEFAULT_PORT => 8101;

my ($port,$debug,$logfile,$pidfile,$user,$kill);

my $usage = <<USAGE;
Usage: $0 [options]

Options:

    --port    -p  <port>  Network port number to listen to (default 8101).
    --verbose -v  <level> Verbosity level (0-3)
    --user    -u  <name>  User to run under (same as current)
    --log     -l  <path>  Log file path (default, use STDERR)
    --pid         <path>  PID file path (default, none)
    --kill    -k          Kill running server (use in conjunction with --pid).

Bare-naked Gbrowse render server.
Launch with the port number to listen on.

No other configuration information is necessary. The
needed configuration will be transmitted from the master
server at run time.
USAGE
    ;


Getopt::Long::Configure('bundling');
GetOptions('port|p=i'       => \$port,
	   'verbose|v=i'    => \$debug,
	   'logfile|l=s'    => \$logfile,
	   'pidfile|pid=s'  => \$pidfile,
	   'user|u=s'       => \$user,
	   'kill|k'         => \$kill,
    ) or die $usage;

if ($kill) {
    kill_running_server();
    exit 0;
}

$port  ||= DEFAULT_PORT;

my $server = Bio::Graphics::Browser::Render::Server->new(LocalPort=>$port,
							 User     => $user,
							 LogFile  => $logfile,
							 PidFile  => $pidfile,
    )
    or die "Could not create server.\n";

$server->debug($debug);
$server->run();
exit 0;

sub kill_running_server {
    my $pid;

    if ($pidfile) {
	open my $f,$pidfile or die "Can't open $pidfile: $!";
	chomp($pid = <$f>);
    }
    elsif (-d '/proc') {  # try to get pid from process list
	opendir my $d,"/proc";
	while (my $dir = readdir($d)) {
	    next unless $dir =~ /^\d+$/;
	    open my $f,"/proc/$dir/status" or next;
	    my $cmd = <$f>;
	    $cmd =~ /Name:\s+gbrowse_server/ or next;
	    $pid = $dir;
	    last;
	}
    }

    die "Can't find pid of running slave server"
	unless $pid;

    kill TERM => $pid or
	die "Could not signal process $pid: $!";
    warn "Server terminated.\n";
    unlink $pidfile if $pidfile;
}
