require 'socket'
require 'dotenv/load'
require_relative 'response'
require_relative 'request'
require_relative 'logger'
require 'rack'
require 'rack/lobster'

APP = Rack::Lobster.new

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

def route(request)
  path = (request.path == "/") ? "index.html" : request.path
  full_path = File.join(__dir__, "views", path)

  if template_exists?(full_path)
    render file: full_path
  else
    status, headers, body = APP.call({
      "REQUEST_METHOD" => request.method,
      "PATH_INFO" => request.path,
      "QUERY_STRING" => request.query
    })

    Response.new(code: status, body: body.join, headers: headers)
  end
rescue => e
  puts e.full_message
  Response.new(code: 500)
end

loop do
  begin
    Thread.start(server.accept) do |client|
      request = Request.new(client.readpartial(2048))
      puts Logger.new(request).call
      response = route(request)
      response.send(client)
      client.close
    end
  rescue Interrupt => e
    puts "INFO  going to shutdown ..."
    break
  end
end
