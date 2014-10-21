require 'socket'               # Get sockets from stdlib

$app = Shoes.app(:width => 256) do
  Thread.new do
    begin
      hostname = 'localhost'
      port = 2000

      c1 = TCPSocket.open(hostname, port)
      para("shubham")

      while line = c1.recv(1024)   # Read lines from the socket
        para(line.chop)      # And print with platform line terminator
        # cmd = "ls"    #type a command to execute on other client
        # c1.write cmd
      end
      c1.close               # Close the socket when done

    rescue => e
      error(e.to_s)
    end
  end
end
