FROM dispatcher

# Set environment variables

COPY ./ecwi.sh /bin/ecwi.sh
COPY ./cert /bin/cert
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /bin/ecwi.sh
RUN chmod +x /bin/cert
RUN chmod +x /entrypoint.sh
