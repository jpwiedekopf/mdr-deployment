FROM docker.verbis.dkfz.de/ccp/mdr:release-gba-mdr
ADD start.sh /samply
ADD mdr.oauth2.xml /etc/samply
RUN chmod +x /samply/start.sh
CMD ["/samply/start.sh"]
