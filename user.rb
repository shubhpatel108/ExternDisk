class User
	@@filepath = nil

	attr_accessor :username, :socket, :files, :last_id, :ethaddr

	def self.filepath=(path=nil)
		@@filepath = File.join(APP_ROOT, path)
	end

	def self.file_exists?
		if @@filepath and File.exists?(@@filepath)
			return true
		else
			return false
		end
	end

	def self.file_usable?
		return false unless @@filepath
		return false unless File.exists?(@@filepath)
		return false unless File.readable?(@@filepath)
		return false unless File.writable?(@@filepath)
		return true
	end

	def self.create_file
    # create the restaurant file
    File.open(@@filepath, 'w') unless file_exists?
    return file_usable?
  end

  def initialize(un, sock)
		@username = un || ""
		@socket = sock || nil
		@files = []
  end

  def save
  	return false unless User.file_usable?
		return User.exists?
		File.open(@@filepath, "a") do |file|
			file.puts "#{@username}\t#{@ethaddr}\t#{files.to_s}\t#{last_id}"
		end
  end

  def self.users_list
		users = []
    if file_usable?
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

	def self.exists?
		file = File.new(@@filepath, 'r')
		file.each_line do |line|
			if @username == line.chomp.split("\t")[0]
				return true
			end
		end
		return false
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
  	hash = {:id => last_id + 1, :name => name, :is_dir => true :list => false}
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
		cmd = "ifconfig"
		value = %x[#{cmd}]
		line = value.split("\n")[0]
		eadr = line.slice(line.length-19..line.length)
		@ethraddr = eadr
		self.save
	end
end
