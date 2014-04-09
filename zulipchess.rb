require_relative 'chessbot.rb'
require 'zulip'

module ZulipChessBot

  @client = Zulip::Client.new do |config|
    config.email_address = ENV['chessbot_email']
    config.api_key = ENV["chessbot_api_key"]
  end

  @games = {}

  def main
    puts "Chessbot is listening"

    @client.stream_messages do |message|

      p message
      puts

      if message.type == "stream"

        stream = message.display_recipient
        topic = message.subject
        game_key = stream + '::' + topic

        @active_game = @games[game_key] ||= StreamGame.new(stream, topic)

      elsif message.type == "private"

        recipients = []

        message.display_recipient.each do |e|
          recipients << e["email"] if e["email"] != @client.email_address
        end.sort!

        game_key = recipients.each {|e| e.slice(0..6) }.join("::")
        @active_game = @games[game_key] ||= PMGame.new(recipients)
      end

      if !message.content.scan(/`[a-zA-Z0-9\-]+`/).empty?
        command = message.content.scan(/`[a-zA-Z0-9\-]+`/).join.slice(1..-2).strip
      end

      case command
      when "start"
        @active_game.set_up
      when "peek"
      when "gg", "resign"
      when "halp"
      when "help"
      else
        begin
          @active_game.move(command)
        rescue Chess::IllegalMoveError
          response = 'That is not a legal move!'
        rescue Chess::BadNotationError
          response = 'Malformed notation.'
        else
          @active_game.flip = !@active_game.flip
          response = "Checkmate!\n" + @active_game.print_board if @active_game.board.checkmate?
          response = "Check!\n" + @active_game.print_board if @active_game.board.check?
        end

      response ||= @active_game.print_board

      @active_game.send(response)

      end
    end
  end
end



