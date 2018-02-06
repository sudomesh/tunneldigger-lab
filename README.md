# tunneldigger-lab
experiments on digging tunnels 

tested on ubuntu 16.04 LTS

# prerequisites

```
sudo apt update
sudo apt install cmake libnl-3-dev libnl-genl-3-dev
```

# install
## clone
First clone and build the tunneldigger client

```
git clone https://github.com/wlanslovenija/tunneldigger.git
```

The version that is used in [firmware](https://github.com/sudomesh/sudowrt-firmware) can be found at https://github.com/sudomesh/nodewatcher-firmware-packages/blob/sudomesh/net/tunneldigger/Makefile . At time of writing https://github.com/sudomesh/tunneldigger was used, a fork of https://github.com/wlanslovenija/tunneldigger . The sudomesh fork does not run on ubuntu because of some library depedencies. 

## compile
```
cd tunneldigger/client
cmake .
```
cmake may provide an output like:
```
-- Checking for module 'libasyncns'
--   No package 'libasyncns' found
-- Configuring done
-- Generating done
-- Build files have been written to: /home/user/tunneldigger/client
```
do not worry about the missing package, the libasyncns source is included in the tunneldigger repository, so it does not need to be installed globally.  
now you can run make, 
```
make 
```
which should produce and output like:
```
Scanning dependencies of target tunneldigger
[ 33%] Building C object CMakeFiles/tunneldigger.dir/l2tp_client.c.o
[ 66%] Building C object CMakeFiles/tunneldigger.dir/libasyncns/asyncns.c.o
[100%] Linking C executable tunneldigger
[100%] Built target tunneldigger
```

and the file [tunneldigger-lib]/tunneldigger/client/tunneldigger should exist.

# digging a tunnel
Before digging a tunnel, check interfaces using ```ip addr```, there should be no l2tp interface yet. Check udp ports using ```netstat -u```, this should be empty. Check syslog using ```cat /var/log/syslog | grep td-client```, this should not contain any recent entries. 

Now run 
```sudo $PWD/tunneldigger/client/tunneldigger -b exit.sudomesh.org:8942 -u 07105c7f-681f-4476-b5aa-5146c6e579de -i l2tp0 -s $PWD/tunnel_hook.sh```

where:

1. exit.sudomesh.org:8942 is the end of the tunnel you are attempting to dig also known as the "broker"
2. 07105c7f-681f-4476-b5aa-5146c6e579de is some unique identifier aka a uuid
3. l2tp0 is the interface that will be created for the tunnel
4. tunnel_hook.sh is the shell script (aka "hook") that is called by the tunnel digger on creating/destroying a session.

Now, open another terminal and check the status of the tunnel by:

1. inspecting the tunnel_hook.sh.log for recent entries of new sessions. Expected entries are like
```
Mon Dec 18 21:29:28 PST 2017 [td-hook] session.up l2tp0
Mon Dec 18 21:30:10 PST 2017 [td-hook] session.down l2tp0
```
2. run ```ip addr``` and verify that an interface ```l2tp0``` now exists. 
3. also, open udp ports ```netstat -u``` and verify you see something like this:
```
Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
udp        0      0 xxxx:42862         unassigned.psychz.:8942 ESTABLISHED
```
4. verify syslog entries using ```cat /var/log/syslog | grep td-client``` - expecting something like:
```
Dec 17 13:24:06 xx td-client: Performing broker selection...
Dec 17 13:24:08 xx td-client: Broker usage of exit.sudomesh.org:8942: 1471
Dec 17 13:24:08 xx td-client: Selected exit.sudomesh.org:8942 as the best broker.
Dec 17 13:24:12 xx td-client: Tunnel successfully established.
Dec 17 13:24:21 xx td-client: Setting MTU to 1446
```
5. the tunnel can be closed using CRTL-C in the original, or can be run in the background like any shell command.

## digging a tunnel to your own computer

To dig a tunnel to our own computer, you'll have to run your own broker. You can find instructions on how to do this at http://tunneldigger.readthedocs.io/en/latest/server.html . Note that these instructions use the latest tunneldigger broker - the broker running on the sudomesh exit node (5 Feb 2018) is reportedly github.com/sudomesh/tunneldigger/blob/f05d9adc170929f883600c3637b66b9c60705630/ with install instructions at https://github.com/sudomesh/exitnode/blob/master/provision.sh#L72 . 

On starting the broker with default configuration, you should see something like:

```
$sudo /srv/tunneldigger/env_tunneldigger/bin/python -m tunneldigger_broker.main /srv/tunneldigger/tunneldigger/broker/l2tp_broker.cfg
[INFO/tunneldigger.broker] Initializing the tunneldigger broker.
[INFO/tunneldigger.broker] Maximum number of tunnels is 1024.
[INFO/tunneldigger.broker] Tunnel identifier base is 100.
[INFO/tunneldigger.broker] Tunnel port base is 20000.
[INFO/tunneldigger.broker] Namespace is default.
[INFO/tunneldigger.broker] Listening on 127.0.0.1:53.
[INFO/tunneldigger.broker] Listening on 127.0.0.1:123.
[INFO/tunneldigger.broker] Listening on 127.0.0.1:8942.
[INFO/tunneldigger.broker] Broker initialized.
```

Now, repeat [digging a tunnel](#digging-a-tunnel) using broker config localhost:8942 . 

Now, you should see the following in the broker log:

```
[INFO/tunneldigger.broker] Creating tunnel (07105c7f-681f-4476-b5aa-5146c6e579de) with id 100.
[INFO/tunneldigger.tunnel] Set tunnel 100 MTU to 1446.
```

on closing the client, the following is logged:

```
[INFO/tunneldigger.tunnel] Closing tunnel 100 after 42 seconds
```

