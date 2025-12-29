MythTV backend
==============

Docker image to run a MythTV backend. It also includes MythWeb, database backups, and HDHomeRun utilities.

* The mythdatabase branch/tag should be run side-by-side with master/latest branch/tag. It will run the cron job to check and backup your MythTV database.
* The mythweb branch/tag starts an Apache service, to host MythWeb, on port 80.
* The setup branch/tag is intended to run mythtv-setup over VNC. This should be run instead of the master/latest branch/tag, during setup only.
* The current version is 35, running on Ubuntu 25.10
* Older MythTV versions are available, running older versions of Ubuntu. Each older version is tagged as it's version number.
* MythWeb and MythTV-Setup are depricated and replaced with the new web application
* The mythbuntu team kept these older packages for Ubuntu 24.10, you can use them if running the backend-24.04-35 tag
* Linked Github code contains example docker-compose.yml for mythbackend and mythsetup


* Note : That this container does not include a MySQL or MariaDB database. You must set up a database before (no need to create the mythconverg database as it is automatically created if it does not exist).
* Note2: All special MythTV folders (as setup in mythtv-setup) should be added to the /var/lib/mythtv volume. If .mythtv/config.xml and/or .mythtv/*.xmltv is found in this volume, that config is used.
* Note3: The mythbackend service checks and waits for the mysql database, using the environment variables to configure.
* Note4: Setup VNC creates a terminal and launches mythtv-setup. If mythtv-setup is closed, the terminal remains, so you can do additional setup (such as with XMLTV)
* Note5: Setup runs as root. On first run you will be asked whether you wish to be added to the "mythtv" group. Choose No, and then choose Yes to disable the warning in future.
* Note6: Keep in mind that docker allows ports to be published to specific IPs, however, this does not work in host mode. Because of this, mythweb, mythdatabase and the mysql instances can have seprate IP addresses, but mythbackend must share the IP of the host.

## Usage

The [Examples](https://github.com/king-dopey/docker-mythbackend/tree/master/Examples) folder contains sample docker-compose files. You can also run the commands directly, as follows.

Launch the container via docker:
```
sudo docker run -d --name mythbackend \
        -p "5000:5000" -p "6543:6543" -p "6544:6544" \
        -v "/path/to/mythtv-home:/var/lib/mythtv" \
        -v "/path/to/mythtv-backups:/var/lib/mythtv/db_backups" \
        -e "USER_ID=1001" \
        -e "GROUP_ID=1001" \
        -e "DATABASE_HOST=mysql" \
        -e "DATABASE_PORT=3306" \
        -e "DATABASE_NAME=mythconverg" \
        -e "DATABASE_USER=mythtv" \
        -e "DATABASE_PWD=mythtv" \
        -e "TZ=Europe/Paris" \
        -h mythbackend \
        --network="host" \
        dheaps/mythbackend:latest &&
sudo docker run -d --name mythdatabase \
        -e "USER_ID=1001" \
        -e "GROUP_ID=1001" \
        -e "DATABASE_HOST=mysql" \
        -e "DATABASE_PORT=3306" \
        -e "DATABASE_NAME=mythconverg" \
        -e "DATABASE_USER=mythtv" \
        -e "DATABASE_PWD=mythtv" \
        -e "TZ=Europe/Paris" \
		 dheaps/mythbackend:mythdatabase &&
sudo docker run -d --name mythweb \
		-p 80:80
        -e "DATABASE_HOST=mysql" \
        -e "DATABASE_NAME=mythconverg" \
        -e "DATABASE_USER=mythtv" \
        -e "DATABASE_PWD=mythtv" \
        -e "TZ=Europe/Paris" \
		 dheaps/mythbackend:mythweb

or

sudo docker run -d --name mythbackend \
        -p "5000:5000" -p "6543:6543" -p "6544:6544" -p 5900:5900 \
        -v "/path/to/mythtv-home:/home/mythtv" \
        -v "/path/to/mythtv-backups:/var/lib/mythtv/db_backups" \
        -e "USER_ID=1001" \
        -e "GROUP_ID=1001" \
        -e "DATABASE_HOST=mysql" \
        -e "DATABASE_PORT=3306" \
        -e "DATABASE_ROOT=root" \
        -e "DATABASE_ROOT_PWD=rootpassword" \
        -e "DATABASE_NAME=mythconverg" \
        -e "DATABASE_USER=mythtv" \
        -e "DATABASE_PWD=mythtv" \
        -e "TZ=Europe/Paris" \
        -h mythbackend \
        --network="host" \
        dheaps/mythbackend:setup
```

Below are some remarks about the parameters.

## Ports

* Port 5000/udp is used for UPNP
* Port 6543 and 6544 are used by MythTV
* Port 80 is used for MythWeb
* Port 5900 is used for VNC

## Volumes

* /mnt/recordings can be used to store recordings (configure MythTV to point to this folder)
* /mnt/video can be used to store videos (configure MythTV to point to this folder)
* /home/mythtv is mainly useful to persist the .mythtv folder where configuration is stored like connection to the database
* /var/lib/mythtv/db_backups will hold backups of the database that are generated weekly by MythTV

## Environment variables

* USER_ID and GROUP_ID : used to match IDs defined on the Docker host so that UNIX rights are correct when accessing the volumes
* DATABASE_HOST and DATABASE_PORT : the host (and port) where the mythconverg database is. If the database exists it is untouched, if not it is created
* DATABASE_ROOT and DATABASE_ROOT_PWD : credentials used to create the database if needed
* DATABASE_USER and DATABASE_PWD : credentials used check if mysql is up and wait otherwise; and to create config as necessary
* TZ : to set the correct timezone

## Network parameters

* hostname (-h) : MythTV uses a hostname to match the parameters in the database so it is better (almost mandatory) to define your own hostname than to use the hash generated by Docker. This is the "hostname" of the container. My advice is to NOT choose the same name as the Docker host or a name of another computer on your network (be creative !).
* host network option (--network="host") : this option is not mentioned in other MythTV docker images on Docker Hub but my tests showed that without it a frontend cannot connect to the backend and HDHomeRun fails.

## XMLTV
* As of version 31 XMLTV must be used, which is no where near as friendly as its predecessor, yet more featureful
* Be sure to select the new XMLTV Video Source in mythtv-setup, over VNC
* Once video source is seleted the XMLTV config file must be created by invoking a command such as below, replacing \${XML_TV_COMMAND} with the correct result from tv_find_grabbers and \${FILENAME} is the name of the video source created in mythtv-setup
``` 
${XML_TV_COMMAND} --configure --config-file ~mythtv/.mythtv/${FILENAME}.xmltv
```

