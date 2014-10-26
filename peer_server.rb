class PeerServer
  attr_accessor :identity, :socket, :ip

  def initialize(identity, sock, ip)
  	@identity = identity || ""
  	@socket = sock || nil
  	@ip = ip || ""
  end
end