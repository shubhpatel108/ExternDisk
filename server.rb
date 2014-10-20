require 'socket'               # Get sockets from stdlib
require 'shoes'

Thread.new do
  begin
  c2 = TCPServer.open(2000)  # Socket to listen on port 2000
  loop {                         # Servers run forever
    c1 = c2.accept
    $app.simple_para("Client connected!")
    $app.simple_para(Time.now.to_s)
    c1.write Time.now.to_s
    # while line = c1.recv(1024)
    #   $app.simple_para( "Recevied: " + line.chop)
    #   # value = %x[#{line}]
    #   # c1.write value.gsub("\n", "|||")
    #   # $app.simple_para( "Result was sent!")
    # end
    c1.puts "Closing the connection. Bye!"
    c1.close                 # Disconnect from the client
  }
  rescue => e
    $app.error(e.to_s)
  end
end