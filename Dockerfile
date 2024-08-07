FROM ubuntu:22.04

# Set environment variables

COPY ./cert /bin/cert
COPY ./ecwi.sh /bin/ecwi.sh

RUN apt-get update 
#&& \
    #apt-get install -y apache2 apache2-* 
#RUN a2enmod macro

# Download and install Jira
RUN chmod +x /bin/ecwi.sh
RUN chmod +x /bin/cert
RUN /bin/ecwi.sh -i '{"PUBLIC":"0.0.0.0"}' '{"kashef.ir"}'
RUN /bin/cert -i
RUN cp -r /etc/apache2 /etc/apache2-default
RUN cp -r /var/log/apache2 /var/log/apache2-default


COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash", "-c", "while true; do sleep 1000; done"]
