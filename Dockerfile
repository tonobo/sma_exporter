FROM armv7/armhf-ubuntu:16.04

RUN apt update && apt install -y \
  libboost-all-dev sqlite3 libsqlite3-dev \
  ruby ruby-dev build-essential \
  libbluetooth-dev git

RUN gem install bundler

RUN git clone https://github.com/dopykuh/sma_exporter /srv/sma
WORKDIR /srv/sma
RUN bundle install
RUN mkdir /srv/sbf
WORKDIR /srv/sbf
RUN tar -xf /srv/sma/sbfspot/SBFspot_SRC_331_Linux_Win32.tar.gz
WORKDIR /srv/sbf/SBFspot
RUN make -j8 install_sqlite
RUN cp -v /srv/sma/sbfspot/*.cfg bin/Release_SQLite/
WORKDIR /srv/sma
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen
EXPOSE 5000
CMD SMA_SBFPATH=/srv/sbf/SBFspot/bin/Release_SQLite/SBFspot bundle exec unicorn -c unicorn.conf

