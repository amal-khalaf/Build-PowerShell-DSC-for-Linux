FROM centos:5
LABEL description="Build environment for the dsc"

RUN mkdir -p /home/scratch

COPY BuildDSC.sh /home/scratch

RUN cd /home/scratch && \
# CentoOS 5 has reached EOL and the mirrors are no longer available; edit the repo files to use vault.centos.org instead
    sed -i 's/^mirrorlist/#mirrorlist/' /etc/yum.repos.d/*.repo && \
    sed -i 's/^#baseurl=http:\/\/mirror\.centos\.org\/centos\//baseurl=http:\/\/vault\.centos\.org\//' /etc/yum.repos.d/*.repo && \
    sed -i 's/\$releasever/5.11/g' /etc/yum.repos.d/*.repo && \
# Add extra repos & dependencies
    yum update -y && \
    yum install -y wget epel-release && \
    wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtools-2.repo && \
    yum update -y && \
    yum install -y \
      devtoolset-2-gcc devtoolset-2-gcc-c++ devtoolset-2-binutils \
      which sudo make cmake zip git redhat-lsb openssh-clients bind-utils bison gcc-c++ \
      rpm-devel pam-devel openssl-devel rpm-build mysql-devel curl-devel selinux-policy-devel \
      audit-libs-devel boost148-devel && \    
# Build OpenSSL
	cd /home/scratch && \
	git clone https://github.com/Microsoft/ostc-openssl.git && \
    cd ./ostc-openssl && \
    sed -i 's/git@github.com:/https:\/\/github.com\//' .gitmodules && \
    git submodule update --init --recursive && \
    # build 0.9.8
    cd ./openssl-0.9.8 && \
    ./config --prefix=/usr/local_ssl_0.9.8 shared && \
    make && \
    make install && \
    # build 1.0.0
    cd ../openssl-1.0.0 && \
    ./config --prefix=/usr/local_ssl_1.0.0 shared -no-ssl2 -no-ec -no-ec2m -no-ecdh && \
    make depend && \
    make && \
    make install_sw && \
    # 1.1.0 requires perl 5.24
    cd /home/scratch && \
    git clone https://github.com/Perl/perl5.git && \
    cd perl5 && \
    git checkout v5.24.1 && \
    ./Configure -des -Dprefix=/usr/local_perl_5_24_1 && \
    #make test && \
    make install && \
    export PATH=/usr/local_perl_5_24_1/bin:$PATH && \
    # now build 1.1.0
    cd /home/scratch/ostc-openssl/openssl-1.1.0 && \
    ./config --prefix=/usr/local_ssl_1.1.0 shared -no-ssl2 -no-ec -no-ec2m -no-ecdh && \
    make depend && \
    make && \
    # skip tests: one of them verifies that the current user is not root and that would fail when building the container image
    #make test && \
    make install_sw
RUN  cd /bld-dsc/dsc/build && \
    chmod +x configure && \
    ./configure --enable-debug --enable-ulinux && \
    make && \
    cd ~
	

	  

