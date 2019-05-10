# Doorkeeper Sinatra Client

[![Build Status](https://semaphoreci.com/api/v1/doorkeeper-gem/doorkeeper-sinatra-client/branches/master/badge.svg)](https://semaphoreci.com/doorkeeper-gem/doorkeeper-sinatra-client)

This app is an example of OAuth 2 client. It was built in order to test the [doorkeeper provider example](http://doorkeeper-provider.herokuapp.com/). It uses [oauth2](https://github.com/intridea/oauth2) and [sinatra](http://www.sinatrarb.com/) gems. Check out the [live app here](http://doorkeeper-sinatra.herokuapp.com/). The source code is, as always, [available on GitHub](https://github.com/applicake/doorkeeper-sinatra-client).

## About Doorkeeper Gem

For more information [about the gem](https://github.com/applicake/doorkeeper), [documentation](https://github.com/applicake/doorkeeper#readme), [wiki](https://github.com/applicake/doorkeeper/wiki/_pages) and another resources, check out the project [on GitHub](https://github.com/applicake/doorkeeper).

## Installation

First clone the [repository from GitHub](https://github.com/applicake/doorkeeper-sinatra-client):

    git clone git://github.com/applicake/doorkeeper-sinatra-client.git

Install all dependencies with:

    bundle install

## Configuration

### Client application

If you have your own provider or you are using [this example](http://doorkeeper-provider.herokuapp.com/), you'll need to create a new client for this application. Make sure to append the `/callback` to the `redirect uri` (e.g. `http://localhost:9393/callback`).

### Environment variables

You need to setup few environment variables in order to make the client work. You can either set the variables in you environment:

    export PUBLIC_CLIENT_ID                 = "129477f..."
    export PUBLIC_CLIENT_REDIRECT_URI       = "c1eec90..."

    export CONFIDENTIAL_CLIENT_ID           = "129477f..."
    export CONFIDENTIAL_CLIENT_SECRET       = "c1eec90..."
    export CONFIDENTIAL_CLIENT_REDIRECT_URI = "http://localhost:9393/callback"

    export PROVIDER_URL = "http://you-server-app.com"

or set them in a file named `.env` in the app's root. This file is loaded automatically by the app.

    # .env
    PUBLIC_CLIENT_ID                 = "129477f..."
    PUBLIC_CLIENT_REDIRECT_URI       = "c1eec90..."

    CONFIDENTIAL_CLIENT_ID           = "129477f..."
    CONFIDENTIAL_CLIENT_SECRET       = "c1eec90..."
    CONFIDENTIAL_CLIENT_REDIRECT_URI = "http://localhost:9393/callback"

    PROVIDER_URL = "http://you-server-app.com"

## Start the server

Fire up the server with:

    bundle exec rackup config.ru
