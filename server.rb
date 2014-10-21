require 'socket'               # Get sockets from stdlib

$app = Shoes.app(:width => 256) do
  Thread.new do
    begin
    c2 = TCPServer.open(4000)  # Socket to listen on port 2000
    loop {                         # Servers run forever
      c1 = c2.accept
      para("Client connected!")
      para(Time.now.to_s)
      c1.puts Time.now.to_s
      c1.puts "ls"
      result = c1.gets
      para result
      # while line = c1.recv(1024)
      #   $app.simple_para( "Recevied: " + line.chop)
      #   # value = %x[#{line}]
      #   # c1.write value.gsub("\n", "|||")
      #   # $app.simple_para( "Result was sent!")
      # end
      c1.close                 # Disconnect from the client
    }
    rescue => e
      error(e.to_s)
    end
  end
end
