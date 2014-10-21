require 'socket'               # Get sockets from stdlib


def build_list(files)
  hash = {}
  files.each do |file|
    hash["#{file}"] = File.directory?(file)
  end
  hash
end

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
      files_hash = build_list(value.split("\n"))
      c1.puts files_hash
      c1.close               # Close the socket when done

    rescue => e
      error(e.to_s)
    end
  end
end
