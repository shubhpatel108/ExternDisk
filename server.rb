require 'socket'               # Get sockets from stdlib
require 'user.rb'
APP_ROOT = File.dirname(__FILE__)

class Server
  attr_accessor :server, :users, :last_id, :files_list
  @@file_list_path = nil
  @@ignore_list_path = nil

  def self.file_list_path=(path=nil)
    @@file_list_path = File.join(APP_ROOT, path)
  end

  def self.ignore_list_path=(path=nil)
    @@ignore_list_path = File.join(APP_ROOT, path)
  end

  def self.file_exists?
    if @@file_list_path and File.exists?(@@file_list_path)
      return true
    else
      return false
    end
  end

  def self.file_usable?
    return false unless @@file_list_path
    return false unless File.exists?(@@file_list_path)
    return false unless File.readable?(@@file_list_path)
    return false unless File.writable?(@@file_list_path)
    return true
  end

  def execute_command(cmd="")
    value = %x[#{cmd}]
    value
  end

  def self.create_file
    # create the restaurant file
    File.open(@@file_list_path, 'w') unless file_exists?
    return file_usable?
  end

  def save_listing
    return false unless User.file_usable?
    File.open(@@file_list_path, "w") do |file|
      file.puts "#{@file_list}"
    end
  end

  def initialize(path=nil, ignore_path=nil)
    @server = TCPServer.open(4000)  # Socket to listen on port 2000
    @users = []
    @last_id = 0
    @files_list = []
    # locate the user text file at path
    Server.file_list_path = path
    Server.ignore_list_path = ignore_path
    if Server.file_usable?
      debug "Found files list."
    # or create a new file
    elsif Server.create_file
      response = execute_command("ls /home/")
      parse_ls_response("/home/", response.split("\n"))
      response = execute_command("ls /media/")
      parse_ls_response("/media/", response.split("\n"))
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
    $app.window do
    stack do
    files.each do |f|
      file = f.split("\t")
      flow do
        para file[0]
        if file.last=="true"
          button "open"
        end
        button "download" do
          save_path = ask_save_file
          para save_path
        end
      end
    end
    end
    end
  end

  def parse_ls_response(path, files)
    if is_ignored?(path)
      return
    end
    queue = []
    files.each do |f|
      if File.directory?(path + f)
        add_dir(path, f, true)
        queue << f
      else
        add_dir(path, f, false)
      end
    end
    while not queue.empty?
      response = execute_command("ls #{path+queue.first.to_s}")
      response.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: "")
      parse_ls_response(path+queue.first+"/", response.split("\n"))
      queue.delete(queue.first)
    end
  end

  def is_ignored?(path)
    file = File.open(@@ignore_list_path, "r")
    files = file.read.split("\n")
    return files.include?(path)
  end

  def add_dir(path, name, is_dir)
    file = File.open(@@file_list_path, 'a')
    dirs = path.split('/')
    @last_id += 1
    append = ""
    append = "/" if is_dir
    file.puts "#{@last_id}\t#{dirs.length}\t#{is_dir}\t#{path+name+append}\n"
    file.close
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
    server = Server.new("file_list.txt", "ignore_list.txt")
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
        server.list_files(i)
      end
    end
    server.accepting
    rescue => e
      error(e.to_s)
    end
  end
end
