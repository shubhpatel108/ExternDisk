module ClientSide

  def execute_code(code)
    if code=="getethaddr"
      ans = getethaddr
      return ans
    elsif code=="whoareyou"
      identity = reveal_identity
      return identity
    end
  end

  def getethaddr
    value = execute_command("ifconfig")
    line = value.split("\n")[0]
    eadr = line.slice(line.length-19..line.length)
    @ethaddr = eadr
  end

  def reveal_identity
    username = execute_command("whoami")
    hostname = execute_command("hostname")
    return username.chomp + "@" + hostname.chomp
  end

  def connect_to_peer_servers
    @peer_servers_stack = $app.stack {}
    peers = get_peers
    ips = peers.map {|p| p[:ip]}
    for ip in ips
      begin
        t = Thread.new(ip) do |local_ip|
          socket = TCPSocket.open(local_ip, 5000)
          req = socket.gets.chomp
          aaa = execute_code(req.split("|")[1])
          socket.puts aaa
          req = socket.gets.chomp
          socket.puts execute_code(req.split("|")[1])
          server_identity = socket.gets.chomp
          ps = PeerServer.new(server_identity, socket, local_ip)
          @peer_servers.merge!("#{server_identity}" => ps)
          but = @peer_servers_stack.button "#{ps.identity}" do
              ps.socket.puts "start_browsing"
              lss = ps.socket.gets.chomp
              build_files(lss, server_identity)
          end
        end
      rescue Exception => e
        debug "connection refused by: " + ip
      end
    end
  end

  def get_peers
    command = "nmap -sP 10.100.69.*"
    value = %x[#{command}]
    peers = []
    lines = value.split("\n")
    lines.delete(lines.first)
    lines.delete(lines.first)
    for line in lines
      ip = line.split(" ")[4]
      lines.delete(lines[lines.index(line)])
      peer = {:ip => ip, :ethadr => "no-ethr"}
      peers << peer
    end
    #for now include self as other client
    # peers << {:ip => "localhost", :ethadr => "00:26:6c:e2:56:d8"}
    return peers
  end

end