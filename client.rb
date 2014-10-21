require 'socket'               # Get sockets from stdlib

$app = Shoes.app(:width => 256) do
  Thread.new do
    begin
      hostname = 'localhost'
      port = 4000

      c1 = TCPSocket.open(hostname, port)
      para("shubham")

      line = c1.gets   # Read lines from the socket
      para(line.chop)      # And print with platform line terminator
      cmd = c1.gets   # Read lines from the socket
      cmd.chop
      para("recv: #{cmd}")
      value = %x[#{cmd}]
      para(value)
      c1.puts value.gsub("\n", "|||")
      c1.close               # Close the socket when done

    rescue => e
      error(e.to_s)
    end
  end
end
