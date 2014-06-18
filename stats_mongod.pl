#!/usr/bin/env perl

# require mongo client command should be find by PATH( export PATH=$PATH:mongo_client_path)
# user and passwd can be set in conf file.

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

#options used.
my($host, $port, $type, $user, $passwd, $items, $verbose);
GetOptions(
        "host=s" => \$host,
        "port=i" => \$port,
        "type=s" => \$type,
        "user=s" => \$user,
        "passwd=s" => \$passwd,
        "items=s" => \$items,
        "verbose!" => \$verbose,
) or die "error:$!";

#user and pass
$user='monitor';
$passwd='xxxxxxxx';

my $status;
if($type eq 'mongodb'){
  $status = `echo "db._adminCommand({serverStatus:1, repl:2})" | mongo --host $host --port $port -u $user -p $passwd admin`
} elsif(defined($type)) {
  print "need specified type option, mongodb,redis...";
} else {
  print "no type option.";
}

#read percona-monitor-plugin for more info.
my %items_list = (
   'mk' => 'MONGODB_connected_clients',
   'ml' => 'MONGODB_used_resident_memory',
   'mm' => 'MONGODB_used_mapped_memory',
   'mn' => 'MONGODB_used_virtual_memory',
   'mo' => 'MONGODB_index_accesses',
   'mp' => 'MONGODB_index_hits',
   'mq' => 'MONGODB_index_misses',
   'mr' => 'MONGODB_index_resets',
   'ms' => 'MONGODB_back_flushes',
   'mt' => 'MONGODB_back_total_ms',
   'mu' => 'MONGODB_back_average_ms',
   'mv' => 'MONGODB_back_last_ms',
   'mw' => 'MONGODB_op_inserts',
   'mx' => 'MONGODB_op_queries',
   'my' => 'MONGODB_op_updates',
   'mz' => 'MONGODB_op_deletes',
   'ng' => 'MONGODB_op_getmores',
   'nh' => 'MONGODB_op_commands',
   'ni' => 'MONGODB_slave_lag',
);

my %result;
{
   $result{'MONGODB_connected_clients'} = $1 if $status =~ /"current" : ([0-9]+)/;
   $result{'MONGODB_used_resident_memory'} = $1 if $status =~ /"resident" : ([0-9]+)/; 
   $result{'MONGODB_used_mapped_memory'} = $1 if $status =~ /"mapped" : ([0-9]+)/;
   $result{'MONGODB_used_virtual_memory'} = $1 if $status =~ /"virtual" : ([0-9]+)/;
   $result{'MONGODB_index_accesses'} = $1 if $status =~ /"accesses" : ([0-9]+)/;
   $result{'MONGODB_index_hits'} = $1 if $status =~ /"hits" : ([0-9]+)/;
   $result{'MONGODB_index_misses'} = $1 if $status =~ /"misses" : ([0-9]+)/;
   $result{'MONGODB_index_resets'} = $1 if $status =~ /"resets" : ([0-9]+)/;
   $result{'MONGODB_back_flushes'} = $1 if $status =~ /"flushes" : ([0-9]+)/;
   $result{'MONGODB_back_total_ms'} = $1 if $status =~ /"total_ms" : ([0-9]+)/;
   $result{'MONGODB_back_average_ms'} = $1 if $status =~ /"average_ms" : ([0-9]+)/;
   $result{'MONGODB_back_last_ms'} = $1 if $status =~ /"last_ms" : ([0-9]+)/;

   #commands list
   my $opcounters = $1 if $status =~ /"opcounters" : \{(.*?)\}/s;
   $result{'MONGODB_op_inserts'} = $1 if $opcounters =~ /"insert" : ([0-9]+)/;
   $result{'MONGODB_op_queries'} = $1 if $opcounters =~ /"query" : ([0-9]+)/;
   $result{'MONGODB_op_updates'} = $1 if $opcounters =~ /"update" : ([0-9]+)/;
   $result{'MONGODB_op_deletes'} = $1 if $opcounters =~ /"delete" : ([0-9]+)/;
   $result{'MONGODB_op_getmores'} = $1 if $opcounters =~ /"getmore" : ([0-9]+)/;
   $result{'MONGODB_op_commands'} = $1 if $opcounters =~ /"command" : ([0-9]+)/;

   # lastlag
   if ($status =~ /"lagSeconds" : ([0-9]+)/) {
      $result{"MONGODB_slave_lag"} = $1;
   } else {
      $result{"MONGODB_slave_lag"} = -1;
   }
}

if (defined($items)) {
    my @list = split(/,/,$items);
    print join(' ',map{ $_ . ':' . $result{$items_list{$_}} } @list);
} else {
  print "error: no items values, use v1,v2,v3.. spicified."
}
