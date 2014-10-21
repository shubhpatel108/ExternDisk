require 'socket'               # Get sockets from stdlib
require 'user.rb'
APP_ROOT = File.dirname(__FILE__)

class Server
  attr_accessor :server, :users
  def initialize(path=nil)
    @server = TCPServer.open(4000)  # Socket to listen on port 2000
    @users = []
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
        @new_user = User.new(un, c1)
        @new_user.save
        @users << @new_user
      }
    end
  end

  def build_files_with_info(result)
    files = result.split("||||")
    $app.stack do
    files.each do |f|
      file = f.split("\t")
      $app.flow do
        $app.para file[8]
        if file.last=="true"
          $app.button "open"
        end
        $app.button "download"
      end
    end
    end
  end

  def build_files(result)
    files = result.split("||||")
    $app.stack do
    files.each do |f|
      file = f.split("\t")
      $app.flow do
        $app.para file[0]
        if file.last=="true"
          $app.button "open"
        end
        $app.button "download"
      end
    end
    end
  end

  def list_files(index)
    client = @users[index]
    client.socket.puts "ls"
    result = client.socket.gets
    build_files(result)
    client.socket.close
  end
end

$app = Shoes.app(:width => 256) do
  Thread.new do
    begin
    server = Server.new("users.txt")
    users_list = stack do
      users = User.users_list
      @check_user = []
      i = 0
      for user in users
        @check_user[i] = button user
        i += 1
      end
    end
    (0..@check_user.length-1).each do |i|
      @check_user[i].click do
        debug i
        server.list_files(i)
      end
    end
    server.accepting
    rescue => e
      error(e.to_s)
    end
  end
end
