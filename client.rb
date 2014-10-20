require 'socket'               # Get sockets from stdlib
require 'shoes'
Thread.new do
  begin
    hostname = 'localhost'
    port = 2000

    c1 = TCPSocket.open(hostname, port)
    $app.simple_para("shubham")      # And print with platform line terminator

    while line = c1.recv(1024)   # Read lines from the socket
      $app.simple_para(line.chop)      # And print with platform line terminator
      # cmd = "ls"    #type a command to execute on other client
      # c1.write cmd
    end
    c1.close               # Close the socket when done

  rescue => e
    $app.error(e.to_s)
  end
end
