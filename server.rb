require 'socket'               # Get sockets from stdlib
require 'user.rb'

APP_ROOT = File.dirname(__FILE__)

class Server
  attr_accessor :server, :users, :last_id, :files_list
  @@file_list_path = nil
  @@ignore_list_path = nil
  @@permission_file_path = nil

  def self.file_list_path=(path=nil)
    @@file_list_path = File.join(APP_ROOT, path)
  end

  def self.ignore_list_path=(path=nil)
    @@ignore_list_path = File.join(APP_ROOT, path)
  end

  def self.permission_file_path=(path=nil)
    @@permission_file_path = File.join(APP_ROOT, path)
  end

  def self.file_exists?(path)
    if path and File.exists?(path)
      return true
    else
      return false
    end
  end

  def self.file_usable?(path)
    return false unless path
    return false unless File.exists?(path)
    return false unless File.readable?(path)
    return false unless File.writable?(path)
    return true
  end

  def execute_command(cmd="")
    value = %x[#{cmd}]
    value
  end

  def self.create_file(path)
    # create the restaurant file
    File.open(path, 'w') unless file_exists?(path)
    return file_usable?(path)
  end

  def save_listing
    return false unless User.file_usable?
    File.open(@@file_list_path, "w") do |file|
      file.puts "#{@file_list}"
    end
  end

  def initialize(path=nil, ignore_path=nil, permission_file_path=nil)
    @server = TCPServer.open(4000)  # Socket to listen on port 2000
    @users = []
    @last_id = 0
    @files_list = []
    # locate the user text file at path
    Server.file_list_path = path
    Server.ignore_list_path = ignore_path
    Server.permission_file_path = permission_file_path
    if Server.file_usable?(@@file_list_path)
      debug "Found files list."
    # or create a new file
    elsif Server.create_file(@@file_list_path)
      response = execute_command("ls /home/")
      parse_ls_response("/home/", response.split("\n"))
      response = execute_command("ls /media/")
      parse_ls_response("/media/", response.split("\n"))
    # exit if create fails
    else
      puts "Exiting.\n\n"
      exit!
    end

    if Server.file_usable?(@@permission_file_path)
      debug "Found files list."
    # or create a new file
    elsif Server.create_file(@@permission_file_path)
      ask_for_default_permission
    else
      puts "Exiting.\n\n"
      exit!
    end

    connect_to_peer_servers
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

  def connect_to_peer_servers
    peers = get_peers
    ips = peers.map {|p| p[:ip]}
    for ip in ips
      begin
        t = Thread.new do
          socket = TCPSocket.open(ip, 4000)
          debug "connection accepted by: " + ip
        end
      rescue Exception => e
        debug "connection refused by: " + ip
      end
    end
  end

  def get_peers
    command = "arp -a"
    value = %x[#{command}]
    peers = []
    lines = value.split("\n")
    for line in lines
      tokens = line.split(/[\s()]/)
      peer = {:ip => tokens[2], :ethadr => tokens[5]}
      peers << peer
    end
    #for now include self as other client
    peers << {:ip => "localhost", :ethadr => "00:26:6c:e2:56:d8"}
    return peers
  end

  def ask_for_default_permission
    @win1 = $app.window {}
    files_to_show = files_at_depth("2", "")
    @stk1 = @win1.stack {}
    @global_stk_hash = {}
    @global_flw_hash = {}
    @stk1.append do
      files_to_show.each do |f|
        tokens = f.split("\t")
        @flw1 = @stk1.flow {}
        @global_flw_hash.merge!("#{tokens[0]}" => @flw1)
        @global_flw_hash["#{tokens[0]}"].append do
          @global_flw_hash["#{tokens[0]}"].para tokens[3]
          if tokens[2]=="true"
            @global_flw_hash["#{tokens[0]}"].button "expand" do
              @global_stk_hash["#{tokens[0]}"].toggle
            end
            @stk2 = @global_flw_hash["#{tokens[0]}"].stack(:hidden => true) {}
            @global_stk_hash.merge!("#{tokens[0]}" => @stk2)
            append_list(tokens[0], (tokens[1].to_i + 1).to_s, tokens[3])
          end
        end
      end
    end
  end

  def append_list(id, depth, path)
    files_to_show = files_at_depth(depth, path)
    @global_stk_hash["#{id}"].append do
      files_to_show.each do |f|
        tokens = f.split("\t")
        @flw1 = @global_stk_hash["#{id}"].flow {}
        @global_flw_hash.merge!("#{tokens[0]}" => @flw1)
        @global_flw_hash["#{tokens[0]}"].append do
          @global_flw_hash["#{tokens[0]}"].para tokens[3].gsub(path, "")
          if tokens[2]=="true"
            @global_flw_hash["#{tokens[0]}"].button "expand" do
              @global_stk_hash["#{tokens[0]}"].toggle
            end
            @stk2 = @global_flw_hash["#{tokens[0]}"].stack(:hidden => true) {}
            @global_stk_hash.merge!("#{tokens[0]}" => @stk2)
            append_list(tokens[0], (tokens[1].to_i + 1).to_s, tokens[3])
          end
        end
      end
    end
  end

  def files_at_depth(depth, path)
    string_comp = true
    string_comp = false if path==""
    file = File.open(@@file_list_path, "r")
    files = file.read.split("\n")
    files_to_show = []
    for ff in files
      f = ff.split("\t")
      dp = f[1]
      name = f[3]
      if dp==depth and string_comp and name.start_with?("#{path}")
        files_to_show << ff
      elsif dp==depth and not string_comp
        files_to_show << ff
      end
    end
    file.close
    files_to_show
  end

end

$app = Shoes.app(:width => 256) do
  Thread.new do
    begin
    server = Server.new("file_list.txt", "ignore_list.txt", "permission_file.xls")
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
