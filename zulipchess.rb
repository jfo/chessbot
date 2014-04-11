require_relative 'chesscontroller.rb'
require_relative 'pmgame.rb'
require_relative 'streamgame.rb'

require 'zulip'

# module ZulipChess

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

        active_game = @games[game_key] ||= StreamGame.new(stream, topic)

      elsif message.type == "private"

        recipients = []

        message.display_recipient.each do |e|
          recipients << e["email"] if e["email"] != @client.email_address
          p recipients
        end
        recipients.sort!


        game_key = recipients.each {|e| e.slice(0..6) }.join("::")
        @games[game_key] ||= PMGame.new(recipients)
        active_game = @games[game_key]
      end

      if !message.content.scan(/`[a-zA-Z0-9\-]+`/).empty?
        command = message.content.scan(/`[a-zA-Z0-9\-]+`/).join.slice(1..-2).strip
      end

      if command != nil

        case command
        when "start"
          active_game.set_up
          response = active_game.print_board
        when "peek"
          response ||= active_game.print_board
        when "gg", "resign"
          response = "Good game!"
          active_game.set_up
        when "halp"
          response = "hallllp meeee!!!"
        when "help"
          response = "pending"
        when "undo"
          active_game.game.rollback!
          response = active_game.print_board
        else
          begin
            active_game.game.move(command)
          rescue Chess::IllegalMoveError
            response = 'That is not a legal move!'
          rescue Chess::BadNotationError
            response = 'Malformed notation.'
          else
            active_game.flip = !active_game.flip
            response = "Checkmate!\n" + active_game.game.print_board if active_game.game.board.checkmate?
            response = "Check!\n" + active_game.game.print_board if active_game.game.board.check?
          end

        response ||= active_game.print_board
        end

        active_game.send(response) if response != nil

      end
    end
  end
# end

main

