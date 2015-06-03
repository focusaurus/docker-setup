apt-get --quiet --assume-yes update
apt-get --quiet --assume-yes install git-core openssl curl
cd /tmp
git clone https://github.com/focusaurus/docker-registry-setup.git
