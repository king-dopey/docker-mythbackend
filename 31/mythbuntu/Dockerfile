FROM ubuntu:20.04

# Set correct environment variables
ENV HOME="/root"
ENV TERM=xterm
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# These should be set at runtime.
ENV USER_ID=99
ENV GROUP_ID=100
ENV DATABASE_HOST=mysql
ENV DATABASE_PORT=3306
ENV DATABASE_ROOT=root
ENV DATABASE_ROOT_PWD=pwd
ENV DATABASE_NAME=mythconverg
ENV DATABASE_USER=mythtv
ENV DATABASE_PWD=mythtv

# add repositories
RUN apt-get update -qq && \
	apt-get install -y locales tzdata && \
# chfn workaround - Known issue within Dockers
	ln -s -f /bin/true /usr/bin/chfn && \
# set the locale
	locale-gen en_US.UTF-8 && \
# prepare apt 
	apt-get install -y software-properties-common --no-install-recommends && \
	apt-add-repository ppa:mythbuntu/31 -y && \
	apt-get update -qq && \
	apt-get install -y --no-install-recommends mythtv-common mysql-client  && \
# clean up
	apt-get clean && \
	rm -rf /tmp/* /var/tmp/* \
	/usr/share/man /usr/share/groff /usr/share/info \
	/usr/share/lintian /usr/share/linda /var/cache/man && \
	(( find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true )) && \
	(( find /usr/share/doc -empty|xargs rmdir || true ))
