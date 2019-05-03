FROM ruby:2.6.3

LABEL maintainer="felipe@yerba.dev"

RUN gem install bundler:2.0.1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./

RUN bundle install --jobs 4

COPY . .

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
