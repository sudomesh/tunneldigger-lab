# tunneldigger-lab
experiments on digging tunnels 

Why tunneldigger? See https://wlan-si.net/en/blog/2012/10/29/tunneldigger-the-new-vpn-solution/ .

tested on ubuntu 16.04 LTS

## Fast Mode (Vagrant)
This will get you up and running quickly.
It's more for folks setting up the lab for workshop purposes,
and you'll learn a bit less if you skip the setup that this saves you from.

Anyway, if you have Vagrant installed, you should be able to run the following:

```bash
git clone https://github.com/sudomesh/tunneldigger-lab
cd tunneldigger-lab
vagrant up && vagrant ssh
cd /vagrant
./lab.sh
```

The various tmux panes will highlight changes to the system's network as they occur.
You can stop the current client session by pressing Ctrl+C,
and experiment with other commands to see how they change things.

To learn how to configure a tunneldigger client yourself, read on!

## prerequisites

```bash
sudo apt update
sudo apt install cmake libnl-3-dev libnl-genl-3-dev build-essential pkg-config
sudo apt install linux-image-extra-$(uname -r)
```

## install
### kernel modules
You have to load some kernel modules (`l2tp_*`).

```bash
sudo modprobe l2tp_netlink
sudo modprobe l2tp_eth
sudo modprobe l2tp_core
```

Verify that the modules were loaded by running `sudo lsmod | grep l2tp`, result should be something like:

```bash
$ sudo lsmod | grep l2tp
l2tp_eth               16384  0
l2tp_ppp               24576  0
l2tp_netlink           20480  2 l2tp_eth,l2tp_ppp
l2tp_core              32768  3 l2tp_eth,l2tp_ppp,l2tp_netlink
ip6_udp_tunnel         16384  1 l2tp_core
udp_tunnel             16384  1 l2tp_core
pppox                  16384  2 l2tp_ppp,pppoe
```

If you'd like to automatically load the kernel modules on reboot, the system should be configured to load these modules at boot which is usually done by listing the modules in /etc/modules. For more information see the [Tunneldigger docs](https://tunneldigger.readthedocs.io/en/latest/server.html).

### clone
First clone and build the tunneldigger client

```bash
git clone https://github.com/wlanslovenija/tunneldigger.git
```

The version that is used in [firmware](https://github.com/sudomesh/sudowrt-firmware) can be found in the [nodewatcher Makefile](https://github.com/sudomesh/nodewatcher-firmware-packages/blob/sudomesh/net/tunneldigger/Makefile). At time of writing, [sudomesh/tunneldigger](https://github.com/sudomesh/tunneldigger) was used, a fork of [wlanslovenija](https://github.com/wlanslovenija/tunneldigger). The sudomesh fork does not run on ubuntu because of some library depedencies. 

### compile
```bash
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
Do not worry about this missing package. The libasyncns source is included in the tunneldigger repository, so it does not need to be installed globally.
Now you can run make, 
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
Before digging a tunnel, check interfaces using `ip addr`, there should be no l2tp interface yet. Check udp ports using `netstat -u`, this should be empty. Check syslog using `cat /var/log/syslog | grep td-client`, this should not contain any recent entries. 

First, generate a uuid using `uuidgen` on the commandline: the output should be a valid [uuid](https://en.wikipedia.org/wiki/Universally_unique_identifier) .

Now run 
```bash
sudo $PWD/tunneldigger/client/tunneldigger -f -b 64.71.176.94:8942 -u [uuid] -i l2tp0 -s $PWD/tunnel_hook.sh
```

where:

1. 64.71.176.94:8942 is the end of the tunnel you are attempting to dig also known as the "broker"
2. [uuid] is the uuid you just generated with `uuidgen`
3. l2tp0 is the interface that will be created for the tunnel
4. tunnel_hook.sh is the shell script (aka "hook") that is called by the tunnel digger on creating/destroying a session.

On starting, you should see something like:

```
td-client: Performing broker selection...
td-client: Broker usage of [ip tunnel digger broker]:8942: 127
td-client: Selected [ip tunnel digger broker]:8942 as the best broker.
td-client: Tunnel successfully established.
td-client: Setting MTU to 1446
```

Now, open another terminal and check the status of the tunnel by:

1. inspecting the tunnel_hook.sh.log for recent entries of new sessions. Expected entries are like
```
Mon Dec 18 21:29:28 PST 2017 [td-hook] session.up l2tp0
Mon Dec 18 21:30:10 PST 2017 [td-hook] session.down l2tp0
```
2. run `ip addr` and verify that an interface `l2tp0` now exists. 
3. also, open udp ports `netstat -u` and verify you see something like this:
```
Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
udp        0      0 xxxx:42862         xxxx:8942 ESTABLISHED
```
4. verify syslog entries using `cat /var/log/syslog | grep td-client` - expecting something like:
```
Dec 17 13:24:06 xx td-client: Performing broker selection...
Dec 17 13:24:08 xx td-client: Broker usage of 64.71.176.94:8942: 1471
Dec 17 13:24:08 xx td-client: Selected 64.71.176.94:8942 as the best broker.
Dec 17 13:24:12 xx td-client: Tunnel successfully established.
Dec 17 13:24:21 xx td-client: Setting MTU to 1446
```
5. the tunnel can be closed using CRTL-C in the original, or can be run in the background like any shell command.

## Setting up a broker 

It is also possible to set up your own broker within the client machine or on a hosted server (such as on digitalocean). You can follow instructions published in the [Tunneldigger docs](httpss://tunneldigger.readthedocs.io/en/latest/server.html). Perhaps easiest way to setup a broker is to follow instructions and/or inspect scripts published at [sudomesh/exitnode](https://github.com/sudomesh/exitnode).
