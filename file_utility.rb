module FileUtility

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

  def self.create_file(path)
    # create the restaurant file
    File.open(path, 'w') unless file_exists?(path)
    return file_usable?(path)
  end

end