FROM ubuntu:artful
ARG http_proxy
ENV http_proxy=${http_proxy}
ARG https_proxy
ENV https_proxy=${https_proxy}
ARG ftp_proxy
ENV ftp_proxy=${ftp_proxy}
ARG no_proxy
ENV no_proxy=${no_proxy}
ARG HTTP_PROXY
ENV HTTP_PROXY=${HTTPS_PROXY}
ARG HTTPS_PROXY
ENV HTTPS_PROXY=${HTTPS_PROXY}
ARG FTP_PROXY
ENV FTP_PROXY=${FTP_PROXY}
ARG NO_PROXY
ENV NO_PROXY=${NO_PROXY}
ENV DEBIAN_FRONTEND noninteractive
ENV TVNC_WM=startlxde

COPY conf/sources /tmp
RUN cat /tmp/sources > /etc/apt/sources.list && rm /tmp/sources && apt update
RUN apt install -y gdebi-core

COPY debs/turbovnc_2.1.2_amd64.deb /tmp
RUN gdebi -n /tmp/turbovnc_2.1.2_amd64.deb && rm /tmp/turbovnc_2.1.2_amd64.deb

COPY debs/code_1.19.3-1516876437_amd64.deb /tmp
RUN gdebi -n /tmp/code_1.19.3-1516876437_amd64.deb && rm /tmp/code_1.19.3-1516876437_amd64.deb

COPY debs/google-chrome-stable_current_amd64.deb /tmp
RUN gdebi -n /tmp/google-chrome-stable_current_amd64.deb && rm /tmp/google-chrome-stable_current_amd64.deb

RUN apt install -y wget curl vim htop default-jre
RUN apt install -y qt5-default qtdeclarative5-dev build-essential ccache valgrind ssh-askpass meld kcachegrind
RUN apt install -y git subversion p7zip unzip lxde xinit

ENV PATH=/usr/lib/ccache:$PATH
RUN cd /opt && git clone https://github.com/rejkowic/qt-creator.git

WORKDIR /opt/qt-creator
#BASE VERSION
RUN git fetch &&  git checkout v4.5.0a -b v4.5.0a && qmake -r && make -j8
#NEXT VERSION
#RUN git fetch &&  git checkout v4.5.0a -b v4.5.0a && qmake -r && make -j8
RUN make install INSTALL_ROOT=/usr/local

ARG USER=rejkowic
RUN useradd -m -s /bin/bash ${USER} && \
    adduser ${USER} sudo
RUN chown -R ${USER}:${USER} .

RUN apt install -y pkg-config

ARG PW=123
RUN (echo ${PW} && echo ${PW}) | passwd ${USER} && \
    (echo ${PW} && echo ${PW}) | passwd

RUN echo http_proxy=$http_proxy > /etc/environment && \
    echo https_proxy=$https_proxy >> /etc/environment && \
    echo ftp_proxy=$ftp_proxy >> /etc/environment && \
    echo no_proxy=$no_proxy >> /etc/environment && \
    echo HTTP_PROXY=$HTTP_PROXY >> /etc/environment && \
    echo HTTPS_PROXY=$HTTPS_PROXY >> /etc/environment && \
    echo FTP_PROXY=$FTP_PROXY >> /etc/environment && \
    echo NO_PROXY=$NO_PROXY >> /etc/environment && \
    echo TVNC_WM=$TVNC_WM >> /etc/environment

COPY conf/panel /tmp
RUN cat /tmp/panel > /etc/xdg/lxpanel/LXDE/panels/panel

USER ${USER}
ARG TVNC_PW=123890
RUN (echo ${TVNC_PW} && echo ${TVNC_PW} && echo n) | /opt/TurboVNC/bin/vncserver :1 && rm -f /tmp/.X1-lock

ARG NAME="Pawel Rejkowicz"
ARG EMAIL="pawel@rejkowicz.pl"
RUN git config --global user.name "${NAME}" && \
    git config --global user.email ${EMAIL} && \
    git config --global push.default current && \
    git config --global alias.co checkout && \
    git config --global alias.ci commit && \
    git config --global alias.rh "reset --hard"

RUN echo "#!/bin/bash" > /tmp/init.sh && chmod +x /tmp/init.sh && \
    echo "/opt/TurboVNC/bin/vncserver :1 && sleep 3 && pkill -9 light-locker" >> /tmp/init.sh && \
    echo /bin/bash >> /tmp/init.sh

COPY conf/clipitrc /tmp
RUN mkdir -p /home/${USER}/.config/clipit && cat /tmp/clipitrc > /home/${USER}/.config/clipit/clipitrc

EXPOSE 5901
CMD ["/tmp/init.sh"]
