FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y \
  sqlite3 libsqlite3-dev \
  libboost-date-time-dev libboost-system-dev libboost-filesystem-dev libboost-regex-dev \
  ruby ruby-dev build-essential \
  libbluetooth-dev git

RUN gem install bundler
COPY . /srv/sma/
WORKDIR /srv/sma
RUN bundle update --bundler
RUN bundle install -j $(nproc)
RUN mkdir /srv/sbf
WORKDIR /srv/sbf
RUN tar -xf /srv/sma/sbfspot/SBFspot_SRC_331_Linux_Win32.tar.gz
WORKDIR /srv/sbf/SBFspot
RUN make -j$(nproc) install_sqlite
RUN cp -v /srv/sma/sbfspot/*.cfg bin/Release_SQLite/
WORKDIR /srv/sma
EXPOSE 5000
CMD SMA_SBFPATH=/srv/sbf/SBFspot/bin/Release_SQLite/SBFspot bundle exec unicorn -c unicorn.conf

