require "chesscontroller.rb"

class PMGame < ChessController

  attr_reader :recipients

  def initialize(recipients)
    init
    @recipients = recipients
  end

  def init
    super
  end

  def send(response)
    @@client.send_private_message(response, *recipients)
  end

end
