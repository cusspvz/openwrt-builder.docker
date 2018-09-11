FROM package-builder
LABEL MAINTAINER "Jose Moreira <josemoreiravarzim@gmail.com>"

RUN ./scripts/feeds install bzip2
RUN ./scripts/feeds install zlib
RUN ./scripts/feeds install openzwave
RUN ./scripts/feeds install python
RUN ./scripts/feeds install perl
RUN ./scripts/feeds install node
RUN make defconfig;
RUN make package/bzip2/compile
RUN make package/zlib/compile
RUN make package/openzwave/compile
RUN make package/python/compile
RUN make package/perl/compile
RUN make package/node/compile