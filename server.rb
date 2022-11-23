require 'socket'
require 'dotenv/load'
require_relative 'response'
require_relative 'request'
require_relative 'server_logger'

require 'rails'
require 'action_controller/railtie'

class SingleFile < Rails::Application
  config.session_store :cookie_store, :key => '_session'
  config.secret_key_base = '7893aeb3427daf48502ba09ff695da9ceb3c27daf48b0bba09df'
  Rails.logger = Logger.new($stdout)
end

class PagesController < ActionController::Base
  def index
    render inline: "<h1>Hello World!</h1> <p>I'm just a single file Rails application</p>"
  end
end

SingleFile.routes.draw do
  root to: "pages#index"
end

APP = SingleFile

port = ENV.fetch("PORT", 2000).to_i
server = TCPServer.new(port)

puts "=> Listening on port #{port}..."
puts "=> Starting on http://localhost:#{port}"
puts "=> Ctrl-C to shutdown server"

def render(file:)
  body = File.binread(file)
  Response.new(
    code: 200,
    body: body,
    headers: {
      "Content-Length" => body.length,
      "Content-type" => "text/html"
    }
  )
end

def template_exists?(path)
  File.exists?(path)
end

def route(request, client)
  server = ENV.fetch("SERVER", "localhost").to_i
  port = ENV.fetch("PORT", 2000).to_i

  status, headers, body = APP.call({
    "REQUEST_METHOD" => request.method,
    "PATH_INFO" => request.path,
    "QUERY_STRING" => request.query,
    "SERVER_NAME" => server,
    "SERVER_PORT" => port,
    "HTTP_HOST" => server,
    "rack.input" => client
  })

  Response.new(code: status, body: body.join, headers: headers)
rescue => e
  puts e.full_message
  Response.new(code: 500)
end

loop do
  begin
    Thread.start(server.accept) do |client|
      request = Request.new(client.readpartial(2048))
      puts ServerLogger.new(request).call
      response = route(request, client)
      response.send(client)
      client.close
    end
  rescue Interrupt => e
    puts "INFO  going to shutdown ..."
    break
  end
end
