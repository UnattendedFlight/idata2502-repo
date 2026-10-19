# The lab server - a stand-in for a cloud image: Ubuntu, sshd, keys only,
# user ubuntu with passwordless sudo, python3 so Ansible can manage it.
#
# Week 7 adds systemd as PID 1, so the server can run SERVICES the way a VM
# does (Docker's daemon among them). Week 6 ran sshd directly as PID 1.
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssh-server sudo python3 python3-apt ca-certificates \
      systemd systemd-sysv \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /run/sshd \
 && sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config \
 && systemctl enable ssh
# ubuntu:24.04 already ships a user called ubuntu - give it a home, sudo and a .ssh directory
RUN mkdir -p /home/ubuntu/.ssh \
 && chmod 700 /home/ubuntu/.ssh \
 && chown -R ubuntu:ubuntu /home/ubuntu \
 && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
EXPOSE 22
# week 7: systemd is PID 1 and starts sshd as a service; SIGRTMIN+3 is how you ask systemd to shut down
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
