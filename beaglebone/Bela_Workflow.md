# git repo for AAL / Wearable Sensing

    mypc> git clone https://github.com/jreus/augmentedattention.git
    mypc> git init --bare ../aasync.git
    mypc> git remote add sync ../aasync.git

    *Update the new local repo with the latest from your dev repo*
    mypc> git push sync master

    *Now get the repo on the Bela*
    mypc> ssh root@192.168.7.2
    bela> git clone jon@192.168.7.1:Drive/DEV/augmentedattentionlab/aasync.git
    bela> mv aasync augmentedattention
    bela> cd augmentedattention
    bela> git remote add jon jon@192.168.7.1:Drive/DEV/augmentedattentionlab/aasync.git

    *Get the latest from your sync repository*
    bela> git pull jon master


    *Make the example projects accesible from the repository*
    bela> ln -s ~/augmentedattention/examples/all_outputs/ ~/Bela/projects/all_outputs
    bela> ln -s ~/augmentedattention/examples/analog_inputs/ ~/Bela/projects/analog_inputs
    bela> ln -s ~/augmentedattention/examples/datalogger/ ~/Bela/projects/datalogger
    bela> ln -s ~/augmentedattention/examples/serial_comm/ ~/Bela/projects/serial_comm

    *Push changes from the bela to the dev repo*
    bela> git push jon master
    bela> exit
    mypc> git pull sync master

*More on working with remotes*
https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes

*you may need to delete the RSA host key for 192.168.7.1 from known_hosts as its*
*possible someone else was working from a different machine with this Bela before you*
> nano /root/.ssh/known_hosts

*Hopefully after all that, the git pull will work. :-)*

# Being able to control SC on the Bela remotely.

*By default the Bela will automatically boot and run _main.scd*
*in order to stop this so you can play around...*
*When the Bela starts up it starts two sessions: 1 is the Bela IDE*
*the other is scsynth & sclang running _main.scd from the startup project*

*Get a list of the running sessions*
> screen -r

*To log into a process use*
> screen -r ID
*CTRL-C will stop a process when you're logged in to it*

*To disconnect from a process use CTRL-A + D*
*To scroll up, enter copy mode with CTRL-ESC, then use k and j to scroll up and down*
*More information about navigating GNU Screen Can be Found Here*
http://www.linuxscrew.com/2008/11/14/faq-how-to-scrollback-in-gnu-screen/

*Once you have shut down the startup project. You can point your browser to the*
*Bela IDE http://192.168.7.2 and load up the startserver project. This will start*
*up the server so that you can play around.*

*From there you can go into the SuperCollider IDE and start coding.*
*First by making a connection to the Bela Server*
( // remote belaserver
Server.default = s = Server("belaServer", NetAddr("192.168.7.2", 57110));
//s.initTree;
s.options.maxLogins = 5;
s.clientID = 1;
s.startAliveThread;
);





# supercollider class extensions

*this doesn't work*
copy `bela_config/sclang_conf.yaml` to : `/root/.config/SuperCollider`

*so the old-fashioned way - also doesn't work*
    cd .local/share/SuperCollider/
    root@bela ~/.local/share/SuperCollider$ mkdir Extensions
    root@bela ~/.local/share/SuperCollider$ cd Extensions/
    root@bela ~/.local/share/SuperCollider/Extensions$ ls
    root@bela ~/.local/share/SuperCollider/Extensions$ ln -s /root/earthquakes/SuperCollider/classes/

*so add to /usr/local/share - this works*

    root@bela cd /usr/local/share/SuperCollider
    root@bela /usr/local/share/SuperCollider$ mkdir Extensions
    root@bela /usr/local/share/SuperCollider$ cd Extensions
    root@bela /usr/local/share/SuperCollider/Extensions$ ln -s /root/earthquakes/SuperCollider/classes/ Earthquakes



# update wavefiles:

from `/root/earthquakes/Python`
do

    rsync -av nescivi@192.168.7.1:/home/nescivi/git/projects/earthquakes/earthquake-archive/Python/Test-Data .

# To add the project to your bela
from `/root/Bela/projects`:

    ln -s /root/earthquake/SuperCollider/EarthQuakeInstrument/

*You may also need to add the symlink for the SC class*
*so add to /usr/local/share - this works*

    root@bela cd /usr/local/share/SuperCollider
    root@bela /usr/local/share/SuperCollider$ mkdir Extensions
    root@bela /usr/local/share/SuperCollider$ cd Extensions
    root@bela /usr/local/share/SuperCollider/Extensions$ ln -s /root/earthquakes/SuperCollider/classes/ Earthquakes
