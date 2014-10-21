class User
	@@filepath = nil

	attr_accessor :username

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
		debug "sdadsdadd"
		debug "#{@@filepath}"
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

  def initialize(args={})
  	@username = args[:username] || ""
  end

  def save
  	return false unless User.file_usable?
		File.open(@@filepath, "a") do |file|
			file.puts "#{@username}\n"
		end
  end
end