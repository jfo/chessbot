require "chesscontroller.rb"

class PMGame < ChessController

  attr_reader :recipients

  def initialize(recipients)
    @recipients = recipients
    super
  end

  def send(response)
    @@client.send_private_message(response, *recipients)
  end

end
