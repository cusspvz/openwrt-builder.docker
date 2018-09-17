FROM package-builder
LABEL MAINTAINER "Jose Moreira <josemoreiravarzim@gmail.com>"

RUN ./scripts/feeds install bzip2
RUN ./scripts/feeds install zlib
RUN ./scripts/feeds install openzwave
RUN ./scripts/feeds install python
RUN ./scripts/feeds install perl
RUN ./scripts/feeds install node
RUN make V=s defconfig;
RUN make V=s package/bzip2/compile
RUN make V=s package/zlib/compile
RUN make V=s package/openzwave/compile
RUN make V=s package/python/compile
RUN make V=s package/perl/compile
RUN make V=s package/node/compile