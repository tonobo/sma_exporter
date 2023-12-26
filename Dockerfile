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
RUN tar -xf /srv/sma/sbfspot/V3.9.7.tar.gz
WORKDIR /srv/sbf/SBFspot-3.9.7/SBFspot
RUN make -j$(nproc) sqlite
RUN cp -v /srv/sma/sbfspot/*.cfg sqlite/bin/
RUN cp -v /srv/sbf/SBFspot-3.9.7/SBFspot/TagListEN-US.txt /srv/sbf/SBFspot-3.9.7/SBFspot/sqlite/bin/TagListEN-US.txt
RUN cp -v /srv/sbf/SBFspot-3.9.7/SBFspot/date_time_zonespec.csv /srv/sbf/SBFspot-3.9.7/SBFspot/sqlite/bin/date_time_zonespec.csv
WORKDIR /srv/sma
EXPOSE 5000
CMD SMA_SBFPATH=/srv/sbf/SBFspot-3.9.7/SBFspot/sqlite/bin/SBFspot bundle exec unicorn -c unicorn.conf

