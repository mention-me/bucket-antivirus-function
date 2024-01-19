FROM amazonlinux:2023 as builder

# Set up working directories
RUN mkdir -p /opt/python

# Install packages
RUN dnf update -y
RUN dnf install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel wget make tar xz

# Download and install Python 3.12
WORKDIR /opt
RUN wget https://www.python.org/ftp/python/3.12.1/Python-3.12.1.tar.xz
RUN tar xvf Python-3.12.1.tar.xz
WORKDIR /opt/Python-3.12.1
RUN ./configure --enable-optimizations --prefix=/opt/python
RUN make -j
RUN make install

FROM amazonlinux:2023

# Set up working directories
RUN mkdir -p /opt/app
RUN mkdir -p /opt/app/build
RUN mkdir -p /opt/app/bin/

# Copy over the python binaries
COPY --from=builder /opt/python /opt/python

# Copy in the lambda source
WORKDIR /opt/app
COPY ./*.py /opt/app/
COPY requirements.txt /opt/app/requirements.txt

# Install packages
RUN dnf update -y
RUN dnf install -y cpio openssl bzip2 libffi yum-utils zip unzip less

# This had --no-cache-dir, tracing through multiple tickets led to a problem in wheel
RUN /opt/python/bin/pip3 install -r requirements.txt
RUN rm -rf /root/.cache/pip

# Download libraries we need to run in lambda
WORKDIR /tmp
RUN yumdownloader -x \*i686 --archlist=x86_64 clamav clamav-lib clamav-update libtool-ltdl
RUN rpm2cpio clamav-0*.rpm | cpio -idmv
RUN rpm2cpio clamav-lib*.rpm | cpio -idmv
RUN rpm2cpio clamav-update*.rpm | cpio -idmv
RUN rpm2cpio libtool-ltdl* | cpio -idmv

# Copy over the binaries and libraries
RUN cp /tmp/usr/bin/clamscan /tmp/usr/bin/freshclam /tmp/usr/lib64/* /opt/app/bin/

# Fix the freshclam.conf settings
RUN echo "DatabaseMirror database.clamav.net" > /opt/app/bin/freshclam.conf
RUN echo "CompressLocalDatabase yes" >> /opt/app/bin/freshclam.conf

# Create the zip file
WORKDIR /opt/app
RUN zip -r9 --exclude="*test*" /opt/app/build/lambda.zip *.py bin

WORKDIR /opt/python/lib/python3.12/site-packages
RUN zip -r9 /opt/app/build/lambda.zip *

WORKDIR /opt/app
