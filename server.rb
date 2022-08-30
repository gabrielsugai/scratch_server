require 'socket'
require_relative 'response'
require_relative 'request'
require_relative 'logger'

port = ENV.fetch("PORT", 2000).to_i
server = TCPServer.new(port)

puts "=> Listening on port #{port}..."
puts "=> Starting on http://localhost:#{port}"
puts "=> Ctrl-C to shutdown server"

def render(path)
  full_path = File.join(__dir__, "views", path)
  if File.exists?(full_path)
    Response.new(code: 200, body: File.binread(full_path))
  else
    Response.new(code: 404)
  end
end

def route(request)
  if request.path == "/"
    render "index.html"
  else
    render request.path
  end
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
