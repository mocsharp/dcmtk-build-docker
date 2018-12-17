FROM ubuntu:latest

# There is a bug on building dcmtk with openssl
# see https://forum.dcmtk.org/viewtopic.php?f=3&t=4791 Post #8 for manual fix.

RUN apt-get update
RUN apt-get install -y curl \
                        git \
                        build-essential \
                        cmake \
                        make \
                        ninja-build \
                        python-dev \
                        libtiff5-dev \
                        libwrap0-dev \
                        doxygen

WORKDIR downloads

RUN curl -O ftp://dicom.offis.de/pub/dicom/offis/software/dcmtk/dcmtk364/support/libiconv-1.15.tar.gz 
RUN curl -O ftp://dicom.offis.de/pub/dicom/offis/software/dcmtk/dcmtk364/support/zlib-1.2.11.tar.gz 
RUN curl -O ftp://dicom.offis.de/pub/dicom/offis/software/dcmtk/dcmtk364/support/libpng-1.6.35.tar.gz 
RUN curl -O ftp://dicom.offis.de/pub/dicom/offis/software/dcmtk/dcmtk364/support/libxml2-2.9.7.tar.gz 
RUN curl -O https://www.openssl.org/source/openssl-1.1.1a.tar.gz


RUN tar xzf libxml2-2.9.7.tar.gz && \
    cd libxml2-2.9.7 && \
    ./configure --prefix=/usr/local && \
    make && \
    make install

RUN tar xzf libiconv-1.15.tar.gz && \
    cd libiconv-1.15 && \
    ./configure --prefix=/usr/local && \
    make > libiconv.log && \
    make install

RUN tar xzf zlib-1.2.11.tar.gz && \
    cd zlib-1.2.11 && \
    ./configure --prefix=/usr/local && \
    make > zlib.log && \
    make install

RUN tar -xzf libpng-1.6.35.tar.gz && \
    cd libpng-1.6.35 && \
    ./configure --prefix=/usr/local && \
    make > libpng.log && \
    make install

RUN tar -xzf openssl-1.1.1a.tar.gz && \
    cd openssl-1.1.1a && \
    ./config  --prefix=/downloads/ssl-build --openssldir=/downloads/ssl-build -Wl,--enable-new-dtags,-rpath,'$(LIBRPATH)' && \
    make > openssl.log && \
    make test && \
    make install


RUN git clone https://github.com/DCMTK/dcmtk.git
# Uncomment for DCMTK 3.6.4 release
# RUN cd dcmtk && \
#     git checkout 1967b13134308f311e6a827e616958c6a4da5bc9

RUN mkdir dcmtk-build dcmtk-install 
    
RUN cd dcmtk-build && \
    (cmake -DBUILD_APPS:BOOL=FALSE \
        -DDCMTK_ENABLE_BUILTIN_DICTIONARY:BOOL=TRUE \
        -DDCMTK_ENABLE_CXX11:BOOL=TRUE \
        -DDCMTK_ENABLE_STL:BOOL=TRUE \
        -DDCMTK_WITH_OPENSSL:BOOL=TRUE \
        -DDCMTK_WITH_PNG:BOOL=TRUE \
        -DDCMTK_WITH_TIFF:BOOL=TRUE \
        -DDCMTK_WITH_XML:BOOL=TRUE \
        -DDCMTK_WITH_ZLIB:BOOL=TRUE \
        -DDCMTK_WITH_WRAP:BOOL=TRUE \
        -DDCMTK_WITH_DOXYGEN:BOOL=TRUE \
        -DOPENSSL_ROOT_DIR=/downloads/ssl-build \
        ../dcmtk ;\
    make -j8 ;\
    make DESTDIR=../dcmtk-install install )
