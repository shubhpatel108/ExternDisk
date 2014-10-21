class User
	@@filepath = nil

	attr_accessor :username, :socket

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
  end

  def save
  	return false unless User.file_usable?
		return User.exists?
		File.open(@@filepath, "a") do |file|
			file.puts "#{@username}\n"
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
end
