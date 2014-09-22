require 'socket'               # Get sockets from stdlib

c2 = TCPServer.open(2000)  # Socket to listen on port 2000
loop {                         # Servers run forever
  c1 = c2.accept       # Wait for a client to connect
  c1.puts(Time.now.ctime)  # Send the time to the client
  while line = c1.gets
  	puts "Recevied: " + line.chop
		value = %x[#{line}]
		c1.puts value.gsub("\n", "|||")
		puts "Result was sent!"
  end
  c1.puts "Closing the connection. Bye!"
	c1.close                 # Disconnect from the client
}