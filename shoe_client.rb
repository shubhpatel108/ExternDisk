require 'socket'               # Get sockets from stdlib

$app = Shoes.app(:width => 256) do
  background(gradient('#CFF', '#FFF'))
  @output = stack(:margin => 10)

  def display text
    @output.append do
      if text =~ /^([^:]+): (.*)$/
        para nick("#{$1}: "), $2
      else
        para text
      end
    end
  end

  def error text
    para "EROEOEOEOEOOE!!"
    para text
  end

  def simple_para text
    para text
  end
end


Thread.new do
  begin
    hostname = 'localhost'
    port = 2000

    c1 = TCPSocket.open(hostname, port)
    $app.simple_para("shubham")      # And print with platform line terminator

    while line = c1.recv(1024)   # Read lines from the socket
      $app.simple_para(line.chop)      # And print with platform line terminator
      # cmd = "ls"    #type a command to execute on other client
      # c1.write cmd
    end
    c1.close               # Close the socket when done

  rescue => e
    $app.error(e.to_s)
  end
end
