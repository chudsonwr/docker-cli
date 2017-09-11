#DOCKER
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update
apt-get install -y docker-ce
apt-get install -y docker-compose
#docker run hello-world

apt-get install -y ruby 2.3.1

groupadd docker

apt-get install -y build-essential patch ruby-dev zlib1g-dev liblzma-dev libsqlite3-dev

# for nokogiri
apt-get install -y libxml2-dev libxslt1-dev

# for capybara-webkit
apt-get install -y libqtwebkit4 libqt4-dev xvfb


gem install bundler

# Allows use of docker without Sudo.
gpasswd -a $USER docker