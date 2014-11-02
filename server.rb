require 'socket'               # Get sockets from stdlib
require 'user.rb'
require 'peer_server.rb'
require 'file_utility.rb'
require 'shoesgui.rb'

APP_ROOT = File.dirname(__FILE__)

class Server
  attr_accessor :server, :users, :last_id, :files_list, :peer_servers
  include FileUtility
  include ShoesGUI

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

  def execute_command(cmd="")
    value = %x[#{cmd}]
    value
  end

  def save_listing
    return false unless FileUtility.file_usable?
    File.open(@@file_list_path, "w") do |file|
      file.puts "#{@file_list}"
    end
  end

  def initialize(path=nil, ignore_path=nil, permission_file_path=nil)
    @server = TCPServer.open(5000)  # Socket to listen on port 2000
    @users = []
    @last_id = 0
    @ids = {}
    @depths = {}
    @peer_servers = {}
    @permission_windows = {}
    @access_windows = {}
    # locate the user text file at path
    Server.file_list_path = path
    Server.ignore_list_path = ignore_path
    Server.permission_file_path = permission_file_path
    if FileUtility.file_usable?(@@file_list_path)
      build_ids
      debug "Found files list."
    # or create a new file
    elsif FileUtility.create_file(@@file_list_path)
      response = execute_command("ls /home/")
      parse_ls_response("/home/", response.split("\n"))
      # response = execute_command("ls /media/")
      # parse_ls_response("/media/", response.split("\n"))
      build_ids
    # exit if create fails
    else
      puts "Exiting.\n\n"
      exit!
    end

    if FileUtility.file_usable?(@@permission_file_path)
      debug "Found files list."
    # or create a new file
    elsif FileUtility.create_file(@@permission_file_path)
      ask_for_default_permission
    else
      puts "Exiting.\n\n"
      exit!
    end

    @peer_servers_stack = $app.stack {}
    connect_to_peer_servers
  end

  def build_ids
    @ids = {}
    files_list = File.open(@@file_list_path, "r")
    files = files_list.read.split("\n")
    for file in files
      f = file.split("\t")
      @ids.merge!("#{f[3]}" => "#{f[0]}")
      @depths.merge!("#{f[0]}" => "#{f[1]}")
    end
    files_list.close
  end

  def accepting
    sleep(1)
    $app.timer(1) do
    Thread.new do
      server = TCPServer.open(6000)
      while true
        Thread.new(server.accept) do |client|
          fn = client.gets.chomp
          file = open(fn, 'r')
          filecontent = file.read
          client.puts(filecontent)
          client.close
        end
      end
    end
    end
    Thread.new do
      loop {                         # Servers run forever
        debug "accepting.."
        Thread.current[:c1] = @server.accept
        new_user = User.new(Thread.current[:c1])
        @users << new_user
        Thread.current[:index] = @users.index(new_user)
        $app.para "Client connected!"
        @users[Thread.current[:index]].socket.puts "code|getethaddr"
        Thread.current[:eth] = @users[Thread.current[:index]].socket.gets.chomp
        @users[Thread.current[:index]].socket.puts("code|whoareyou")
        Thread.current[:identity] = @users[Thread.current[:index]].socket.gets.chomp
        $app.para Thread.current[:identity] + "@" + Thread.current[:eth]
        @users[Thread.current[:index]].username = Thread.current[:identity]
        @users[Thread.current[:index]].ethaddr = Thread.current[:eth]
        @users[Thread.current[:index]].socket.puts(reveal_identity)

        # @new_user.save
        start_serving
      }
    end
  end

  def start_serving
    @global_permissions = {}
    for user in @users
      index = @users.index(user)
      Thread.new(index, user) do |index, user|
        if File.exists?("#{user.username}_permission_file.txt")
          @global_permissions.merge!("#{user.username}" => get_individual_permissions(user))
        elsif FileUtility.create_file("#{user.username}_permission_file.txt")
          ask_for_default_permission(user)
        end
        loop {
          request = @users[index].socket.gets.chomp
          $app.para request
          if request=="confirm_listening"
            return "true"
          elsif request=="start_browsing"
            init_files = initial_files(user)
            @users[index].socket.puts init_files
          elsif request.start_with?("browse>>>")
            inner_files = content_of(user, request.split(">>>")[1])
            @users[index].socket.puts inner_files
          elsif request.start_with?("download>>>")
            transfer_file(@users[index], request.split(">>>")[1])
          end
          #take request for browsing or downloading
        }
      end
    end
  end

  def transfer_file(user, filename)
    fork do
      server = TCPServer.open(6000)
      file = open(filemame, 'r')

      filecontent = file.read

      client.puts(filecontent)
      client.close
    end
  end

  def initial_files(user)
    files = files_at_depth_2("2", "", user)
    return files
  end

  def files_at_depth_2(depth, path, user)
    string_comp = true
    string_comp = false if path==""
    files_to_show = ""
    f_ids = @depths.select {|key,value| value==depth}
    f_ids = f_ids.keys
    f_names = @ids.select {|key, value| f_ids.include?(value)}
    f_names = f_names.keys
    for f in f_names
      if string_comp and f.start_with?("#{path}") and permitted(user, f)
        is_dir = f.end_with?("/").to_s
        name_dir = f + ">>>" + is_dir + ">>>" + @ids[f] + "|||"
        files_to_show += name_dir
      elsif not string_comp and permitted(user, f)
        is_dir = f.end_with?("/").to_s
        name_dir = f + ">>>" + is_dir + ">>>" + @ids[f] + "|||"
        files_to_show += name_dir
      end
    end
    return files_to_show
  end

  def content_of(user, filename)
    id = @ids["#{filename}"]
    dep = @depths[id]
    files_at_depth_2((dep.to_i+1).to_s, filename, user)
  end

  def permitted(user, filename)
    id = @ids["#{filename}"]
    permission = @global_permissions["#{user.username}"]
    if not permission["#{id}"].nil?
      if permission["#{id}"]
        return true
      end
    elsif parent=parent(filename)
      permitted(user,parent)
    else
      return false
    end
  end

  def parent(filename)
    paths = filename.split("/")
    paths.delete(paths.last)
    parent = paths.join("/") + "/"
    if not @ids[parent].nil?
      return parent
    else
      return false
    end
  end

  def get_individual_permissions(user)
    file = File.open("#{user.username}_permission_file.txt")
    files = file.read.split("\n")
    hash = {}
    files.each do |f|
      toks = f.split("\t")
      bool = false
      bool = true if toks[1]=="true"
      hash.merge!("#{toks[0]}" => bool)
    end
    return hash
  end

  def reveal_identity
    username = execute_command("whoami")
    hostname = execute_command("hostname")
    return username.chomp + "@" + hostname.chomp
  end

  def build_files(result, identity)
    win3 = $app.window {}
    @access_windows.merge!("#{identity}" => win3)
    @access_windows["#{identity}"].para "You are browsing #{identity}"
    files = result.split("|||")
    @browse_stk_hash = {}
    @browse_flw_hash = {}
    stk3 = @access_windows["#{identity}"].stack {}
    stk3.append do
      files.each do |f|
        tokens = f.split(">>>")
        flw3 = stk3.flow {}
        @browse_flw_hash.merge!("#{tokens[2]}" => flw3)
        @browse_flw_hash["#{tokens[2]}"].append do
          @browse_flw_hash["#{tokens[2]}"].para "#{tokens[0]}"
          if tokens[1]=="true"
            @browse_flw_hash["#{tokens[2]}"].button "open" do
              Thread.new do
                @peer_servers["#{identity}"].socket.puts "browse>>>#{tokens[0]}"
                lss = @peer_servers["#{identity}"].socket.gets.chomp
                append_browsing_list(lss, tokens[2], identity)
              end
            end
            @browse_flw_hash["#{tokens[2]}"].button "close" do
              @browse_stk_hash["#{tokens[2]}"].clear()
            end
          end
          @browse_flw_hash["#{tokens[2]}"].button "download" do
            sleep(1)
            $app.timer(1) do
              Thread.new do
                begin
                  sock = TCPSocket.open(@peer_servers["#{identity}"].ip, 6000)
                  sock.puts "#{tokens[0]}"
                  data = sock.read
                  new_filename = tokens[0].split("/").last
                  destFile = File.open("#{new_filename}", "w")
                  destFile.print data
                  destFile.close
                rescue => e
                  $app.para "from client #{e}:"
                end
              end
            end
          end
        end
      end
    end
  end

  def append_browsing_list(result, id, identity )
    stk4 = @browse_flw_hash["#{id}"].stack {}
    @browse_stk_hash.merge!("#{id}" => stk4)
    files = result.split("|||")
    @browse_stk_hash["#{id}"].append do
      files.each do |f|
        tokens = f.split(">>>")
        flw3 = @browse_stk_hash["#{id}"].flow {}
        @browse_flw_hash.merge!("#{tokens[2]}" => flw3)
        @browse_flw_hash["#{tokens[2]}"].append do
          @browse_flw_hash["#{tokens[2]}"].para "#{tokens[0]}"
          if tokens[1]=="true"
            @browse_flw_hash["#{tokens[2]}"].button "open" do
              Thread.new do
                @peer_servers["#{identity}"].socket.puts "browse>>>#{tokens[0]}"
                lss = @peer_servers["#{identity}"].socket.gets.chomp
                append_browsing_list(lss, tokens[2], identity)
              end
            end
            @browse_flw_hash["#{tokens[2]}"].button "close" do
              @browse_stk_hash["#{tokens[2]}"].clear()
            end
          end
          @browse_flw_hash["#{tokens[2]}"].button "download" do
            sleep(1)
            $app.timer(1) do
              Thread.new do
                begin
                  sock = TCPSocket.open(@peer_servers["#{identity}"].ip, 6000)
                  sock.puts "#{tokens[0]}"
                  data = sock.read
                  new_filename = tokens[0].split("/").last
                  destFile = File.open("#{new_filename}", "w")
                  destFile.print data
                  destFile.close
                rescue => e
                  $app.para "from client #{e}:"
                end
              end
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

  def connect_to_peer_servers
    @access_files_window = {}
    peers = get_peers
    ips = peers.map {|p| p[:ip]}
    for ip in ips
      begin
        t = Thread.new(ip) do |local_ip|
          socket = TCPSocket.open(local_ip, 5000)
          req = socket.gets.chomp
          socket.puts client_execute_code(req.split("|")[1])
          req = socket.gets.chomp
          socket.puts client_execute_code(req.split("|")[1])
          server_identity = socket.gets.chomp
          ps = PeerServer.new(server_identity, socket, local_ip)
          @peer_servers.merge!("#{server_identity}" => ps) 
          but = $app.button "#{ps.identity}" do
            # Thread.current[:win] = $app.window {}
            # @access_windows.merge!("#{ps.identity}" => Thread.current[:win])
              ps.socket.puts "start_browsing"
              lss = ps.socket.gets.chomp
              build_files(lss, server_identity)
              # ps.socket.puts "confirm_listening"
              # while ps.socket.gets.chomp == "true"
          end
        end
      rescue Exception => e
        debug "connection refused by: " + local_ip
      end
    end
  end

  def client_getethaddr
    value = execute_command("ifconfig")
    line = value.split("\n")[0]
    eadr = line.slice(line.length-19..line.length)
    @ethaddr = eadr
  end

  def client_reveal_identity
    username = execute_command("whoami")
    hostname = execute_command("hostname")
    return username.chomp + "@" + hostname.chomp
  end

  def client_execute_code(code)
    if code=="getethaddr"
      ans = client_getethaddr
      return ans
    elsif code=="whoareyou"
      identity = client_reveal_identity
      return identity
    end
  end

  def get_peers
    command = "nmap -sP 10.100.98.*"
    value = %x[#{command}]
    peers = []
    lines = value.split("\n")
    lines.delete(lines.first)
    lines.delete(lines.first)
    for line in lines
      # tokens = line.split(/[\s()]/)
      ip = line.split(" ")[4]
      lines.delete(lines[lines.index(line)])
      peer = {:ip => ip, :ethadr => "no-ethr"}
      # peer = {:ip => tokens[2], :ethadr => tokens[5]}
      peers << peer
    end
    #for now include self as other client
    # peers << {:ip => "localhost", :ethadr => "00:26:6c:e2:56:d8"}
    return peers
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

  def write_default_permissions
    df = File.open("permission_file.txt", "w")
    @permission.each do |id, value|
      df.puts "#{id}\t#{value}\n"
    end
    df.close
  end

  def write_permissions_for(user)
    df = File.open("#{user.username}_permission_file.txt", "w")
    @permission.each do |id, value|
      df.puts "#{id}\t#{value}\n"
    end
    df.close
    @global_permissions.merge!("#{user.username}" => get_individual_permissions(user))
  end

  def execute_code(socket, code)
    code = sock.gets
    case code
    when "getethaddr"
      getethaddr
      socket.puts @ethraddr
    when "whoareyou"
      identity = reveal_identity
      socket.puts identity
    end
  end
end

$app = Shoes.app(:width => 256) do
  Thread.new do
    begin
      server = Server.new("file_list.txt", "ignore_list.txt", "permission_file.txt")
      server.accepting
    rescue => e
      error(e.to_s)
    end
  end
end
