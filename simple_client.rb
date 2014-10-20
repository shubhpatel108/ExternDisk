require 'socket'      # Sockets are in standard library

hostname = 'localhost'
port = 2000

c1 = TCPSocket.open(hostname, port)

while line = c1.gets   # Read lines from the socket
  puts line.chop      # And print with platform line terminator
  cmd = gets.chomp		#type a command to execute on other client
  c1.puts cmd
end
c1.close               # Close the socket when done
