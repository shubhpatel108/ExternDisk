require 'socket'               # Get sockets from stdlib


def build_info_list(files)
  response = ""
  files.delete(files[0])
  files.each do |file|
    info = file.split(' ')
    i = 0
    file = ""
    8.times do
      file += info[i]+ "\t"
      i+=1
    end
    while i<info.length do
      file += info[i]+ " "
      i+=1
    end
    file += "\t" + File.directory?(file).to_s
    response += file + "||||"
  end
  response
end

def build_simple_list(files)
  response = ""
  files.delete(files[0])
  files.each do |file|
    response += file + "\t" + File.directory?(file).to_s + "||||"
  end
  response
end

$app = Shoes.app(:width => 256) do
  un = ask "Enter username"
  Thread.new do
    begin
      hostname = 'localhost'
      port = 4000

      c1 = TCPSocket.open(hostname, port)
      para un
      c1.puts un
      cmd = c1.gets   # Read lines from the socket
      cmd.chop
      para("recv: #{cmd}")
      value = %x[#{cmd}]
      para(value)
      files_hash = build_simple_list(value.split("\n"))
      debug files_hash
      c1.puts files_hash
      c1.close               # Close the socket when done

    rescue => e
      error(e.to_s)
    end
  end
end
