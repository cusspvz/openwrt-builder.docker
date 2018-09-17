FROM base
LABEL MAINTAINER "Jose Moreira <josemoreiravarzim@gmail.com>"
ARG VERSION
ARG TARGET

ARG INSTALL_SRC
RUN /bin/bash -c "$INSTALL_SRC"

# Cache packages feeds
RUN ./scripts/feeds update -a

ADD builder.sh /builder
RUN chmod 755 /builder
CMD ["/builder"]