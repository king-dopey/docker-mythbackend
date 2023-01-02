FROM dheaps/mythbackend:mythbuntu

# Add files
COPY files /root/

# Install mythtv-database
RUN apt-get install -y --no-install-recommends mythtv-database && \
# Add crontab entry
	echo "3 23   * * 7    root    /usr/share/mythtv/mythconverg_backup.pl" >> /etc/crontab &&\
# clean up
	apt-get clean && \
	rm -rf /tmp/* /var/tmp/* \
	/usr/share/man /usr/share/groff /usr/share/info \
	/usr/share/lintian /usr/share/linda /var/cache/man && \
	(( find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true )) && \
	(( find /usr/share/doc -empty|xargs rmdir || true ))

CMD ["/root/dockerentry.sh"]