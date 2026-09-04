# frozen_string_literal: true

workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['SINATRA_MAX_THREADS'] || 5)
threads threads_count, threads_count

port        ENV['PORT']     || 9292
environment ENV['RACK_ENV'] || 'development'
