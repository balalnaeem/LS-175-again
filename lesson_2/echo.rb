require "socket"

server = TCPServer.new("localhost", 4567)

def parse_url(request_line)
  http_method, path_and_params, http_version = request_line.split(" ")
  path, params = path_and_params.split("?")
  params = (params || "").split("&").each_with_object({}) do |pair, hash|
    key, value = pair.split("=")
    hash[key] = value
  end
  [http_method, path, params]
end

loop do
  client = server.accept

  request_line = client.gets
  next if !request_line || request_line =~ /favicon/
  puts request_line

  http_method, path, params = parse_url(request_line)

  client.puts "HTTP/1.1 200 OK"
  client.puts "Content-Type: text/html\r\n\r\n"
  client.puts

  client.puts "<html>"
  client.puts "<body>"
  client.puts "<pre>"
  client.puts request_line

  number = params["number"].to_i

  client.puts "<h1>Counter</h1>"
  client.puts "<p>The current number is #{number}.</p>"
  client.puts "<a href='?number=#{number + 1}'> Add one </a>"
  client.puts "<a href='?number=#{number - 1}'> Minus one </a>"

  client.puts "</body>"
  client.puts "</html>"

  client.close
end