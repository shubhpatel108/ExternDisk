require 'socket'               # Get sockets from stdlib
require 'user.rb'
APP_ROOT = File.dirname(__FILE__)

class Server
  attr_accessor :server
  def initialize(path=nil)
    @server = TCPServer.open(4000)  # Socket to listen on port 2000
    # locate the user text file at path
    User.filepath = path
    if User.file_usable?
      debug "Found users file."
    # or create a new file
    elsif User.create_file
      debug "Created users file."
    # exit if create fails
    else
      puts "Exiting.\n\n"
      exit!
    end
  end

  def accepting
    Thread.new do
      loop {                         # Servers run forever
        debug "accepting.."
        c1 = @server.accept
        $app.para "Client connected!"
        un = c1.gets
        @new_user = User.new(un)
        @new_user.save
        c1.puts "ls"
        result = c1.gets
        $app.para result
        c1.close
      }
    end
  end
end

$app = Shoes.app(:width => 256) do
  Thread.new do
    begin
    server = Server.new("users.txt")
    server.accepting
    rescue => e
      error(e.to_s)
    end
  end
end
