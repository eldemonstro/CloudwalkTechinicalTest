FROM ruby:3.0.3 AS base

WORKDIR /var/www/cloudwalk

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
      && wget --no-check-certificate --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
      && apt-get update --allow-insecure-repositories \
      && apt-get install -y --no-install-recommends postgresql-client-12

ADD . .
RUN bundle install