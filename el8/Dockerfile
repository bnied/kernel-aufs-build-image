FROM rockylinux/rockylinux:8
LABEL AUTHOR "Ben Nied <spacewreckage@gmail.com>"

RUN dnf -y install gcc make bison flex git dnf-utils spectool rpm-build dnf-plugins-core wget
RUN dnf -y clean all

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "./entrypoint.sh" ]
