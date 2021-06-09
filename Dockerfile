ARG DOCKER_IMAGE=i386/ubuntu:focal
FROM $DOCKER_IMAGE AS builder

#RUN apk add --no-cache gcc make musl-dev git \
RUN apt-get update && apt-get install -y git g++ gcc make && git clone --recurse-submodules https://github.com/drh/lcc.git

WORKDIR /lcc

RUN ln -s /lcc/x86/linux /usr/local/lib/lcc
ENV BUILDDIR /lcc/x86/linux
RUN mkdir -p $BUILDDIR
#RUN cp doc/*.1 /usr/local/man/man1
RUN mkdir $BUILDDIR/include
RUN cp -p -R include/x86/linux/* $BUILDDIR/include

RUN ln -s /usr/lib/gcc/i686-linux-gnu/9 $BUILDDIR/gcc

RUN make HOSTFILE=etc/linux.c lcc

RUN /lcc/x86/linux/lcc -help

RUN make CC=gcc all

RUN make TARGET=x86/linux test

RUN ln -s /usr/local/lib/lcc/cpp /usr/local/lib/lcc/gcc/cpp

COPY hello.c .
RUN /lcc/x86/linux/lcc -target=x86/linux hello.c


ARG DOCKER_IMAGE=alpine:latest
FROM $DOCKER_IMAGE AS runtime

LABEL author="Bensuperpc <bensuperpc@gmail.com>"
LABEL mantainer="Bensuperpc <bensuperpc@gmail.com>"

ARG VERSION="1.0.0"
ENV VERSION=$VERSION

RUN apk add --no-cache musl-dev make

COPY --from=builder /usr/local /usr/local

ENV PATH="/usr/local/bin:${PATH}"

ENV CC=/usr/local/bin/lcc
WORKDIR /usr/src/myapp

CMD ["", "-h"]

LABEL org.label-schema.schema-version="1.0" \
	  org.label-schema.build-date=$BUILD_DATE \
	  org.label-schema.name="bensuperpc/lcc" \
	  org.label-schema.description="build lcc compiler" \
	  org.label-schema.version=$VERSION \
	  org.label-schema.vendor="Bensuperpc" \
	  org.label-schema.url="http://bensuperpc.com/" \
	  org.label-schema.vcs-url="https://github.com/Bensuperpc/docker-lcc" \
	  org.label-schema.vcs-ref=$VCS_REF \
	  org.label-schema.docker.cmd="docker build -t bensuperpc/lcc -f Dockerfile ."
