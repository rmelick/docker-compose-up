FROM alpine:3.3
RUN rm -f "/environment-conf"
RUN mkdir "/environment-conf"
COPY . /environment-conf
VOLUME ["/environment-conf"]
CMD ["tail", "-f", "/dev/null"]