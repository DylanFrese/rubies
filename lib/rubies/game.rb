module Rubies
  class Game
    def initialize(opts={})
      @num_right = 0
      @num_wrong = 0
      @playing = true
      @in = opts.fetch(:in, $stdin)
      @out = opts.fetch(:out, $stdout)
    end

    def puts(message='')
      @out.puts message
    end

    def gets
      @in.gets
    end

    def display_splash
      begin
        puts "\e[H\e[2J"
        puts "
      .______       __    __  .______    __   _______     _______.
      |   _  \\     |  |  |  | |   _  \\  |  | |   ____|   /       |
      |  |_)  |    |  |  |  | |  |_)  | |  | |  |__     |   (----`
      |      /     |  |  |  | |   _  <  |  | |   __|     \\   \\
      |  |\\  \\----.|  `--'  | |  |_)  | |  | |  |____.----)   |
      | _| `._____| \\______/  |______/  |__| |_______|_______/

      ".colorize(:light_magenta)
        puts "
      ================================================================
                                 LEGEND
                     NEW : get a new data structure
                     EXIT: exit program
      ================================================================
      ".colorize(:light_magenta)
        puts "Press enter to continue . . . "

        gets.chomp
        puts "\e[H\e[2J"
      rescue Interrupt => e
        @playing = false
        byebye
        exit
      end
    end

    def continuer
      begin
        puts "Press enter to continue . . . "
        gets.chomp
        puts "\e[H\e[2J"
      rescue Interrupt => e
        @playing = false
        byebye
        exit
      end
    end

    def scoreboard(num_right, num_wrong)
      puts
      puts "==============================".colorize(:light_yellow)
      puts "Number correct this session: ".colorize(:green) + num_right.to_s
      puts "Number wrong this session  : ".colorize(:light_red) + num_wrong.to_s
      puts "==============================".colorize(:light_yellow)
    end

    def questioner(current)
      puts
      puts "We have some questions for you about this #{current.class.to_s.downcase}:".colorize(:light_blue)
      puts "current = "
      if current.is_a? Hash
        ap current, index: false
      elsif current.first.is_a? Array
        PP.pp current
      elsif current.first.is_a? Fixnum
        PP.pp current
      else
        ap current, index: false
      end
      puts
    end

    def eprinter(error)
      encoding_options = {
      :invalid           => :replace,  # Replace invalid byte sequences
      :undef             => :replace,  # Replace anything not defined in ASCII
      :replace           => '',        # Use a blank for those replacements
      }
      puts
      puts "Sorry, that code resulted in an error:".colorize(:light_red)
      puts "#{error}".encode(Encoding.find('ASCII'), encoding_options).colorize(:red)
    end

    def itswrong(answer)
      @num_wrong += 1
      puts "Sorry, that code is incorrect. ".colorize(:light_red)
      puts
      puts "The right answer is . . . ".colorize(:light_red)
      puts answer.to_s
      puts "Try again!".colorize(:light_red)
    end

    def itsright
      @num_right += 1
      puts "Correct!".colorize(:green)
    end

    def cheater
      @num_wrong += 1
      puts "Please provide an answer "\
            "that operates on the given values. ".colorize(:light_red)
      puts
      puts "Try not to directly reference the value directly, ".colorize(:light_red)
      puts
      puts "Instead, try accessing the value by its index or key!".colorize(:light_red)
    end

    def prompter(answer)
      print "Write ruby code to find the following value".colorize(:light_blue)
      print " (or enter ".colorize(:light_blue) + 'NEW'.colorize(:green)
      puts " for a new challenge): ".colorize(:light_blue)
      puts answer.to_s
      puts
      print "[1] rubies(main)> "
    end

    def byebye
      puts
      puts "Thanks for using ".colorize(:green) + "rubies!".colorize(:light_red)
      display_score
    end

    def display_score
      scoreboard(@num_right, @num_wrong)
    end

    def clear_screen
      puts "\e[H\e[2J"
    end

    def prompt(data_structure, target)
      begin
        questioner(data_structure)
        prompter(target)
        gets.chomp.gsub("\"", "\'")
      rescue Interrupt => e
        @playing = false
        byebye
        exit
      end
    end

    def check_answer(current, input, target)
      begin
        routine = lambda { eval(input) }
        output = routine.call
        puts "=> #{output}"
        puts
        output == target
      rescue Exception => e
        eprinter(e)
        false
      end
    end

    # deletes the target from the current data structure
    def deep_delete(current, target)
      return current unless current.is_a? Enumerable
      current.
          reject  {|value| value == target}.
          map     {|value| deep_delete(value, target)}
    end

    # creates an array of values for which any given answer should fail
    def tests(current, target)
      [ nil,
        Array.new,
        Hash.new,
        RandomDataStructure.new.generate,
        deep_delete(current, target)
      ]
    end

    # test user input against various tests, for each of which the
    # input should fail. Returns true only if the user input fails
    # each of the tests.
    def test_answer(current, input, target)
      tests(current, target).all? do |test|
        !run_test(test, input, target)
      end
    end

    # test whether the answer provided by the given 
    # routine matches the target answer
    def run_test(current, input, target)
      routine = lambda { eval(input) }
      begin
        output = routine.call
        output == target
      rescue Exception
        false
      end
    end

    def generate_data_structure
      rds = RandomDataStructure.new
      current = rds.generate
      target = rds.all_values.sample
      [current, target]
    end

    def play_round # new, exit or check if right/wrong
      clear_screen
      correct = false
      current, target = generate_data_structure
      until correct
        input = prompt(current, target).rstrip.lstrip
        if input == "NEW" || input == "new"
          return
        elsif input == "EXIT" || input == "exit"
          @playing = false
          return
        else
          if check_answer(current, input, target)
            if !test_answer(current, input, target)
              cheater
            else
              itsright
              correct = true
            end
          else
            itswrong(target)
          end
        end
        scoreboard(@num_right, @num_wrong)
        continuer
      end
    end

    def gameover?
      !@playing
    end

    #should rename to 'run'
    def game
      display_splash
      until gameover?
        play_round
      end
      byebye
    end
  end

end
