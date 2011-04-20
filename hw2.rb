require 'logger'

class SmithWatermann
  class Score
    def initialize(x, y)
      @y = y
      @score = Array.new(x*y, 0)
    end

    def [](i, j)
      @score[i*@y + j]
    end

    def []=(i, j, val)
      @score[i*@y + j] = val
    end

    def max
      max = @score.max
      i, j = @score.index(max).divmod(@y)
      [max, i, j]
    end

    def to_s
      @score.inspect
    end
  end

  GAP_PENALTY = 4
  INDEX = %w[ A R N D C Q E G H I L K M F P S T W Y V B Z X ]
  BLOSUM62 = [
    [  4, -1, -2, -2,  0, -1, -1,  0, -2, -1, -1, -1, -1, -2, -1,  1,  0, -3, -2,  0, -2, -1,  0 ],
    [ -1,  5,  0, -2, -3,  1,  0, -2,  0, -3, -2,  2, -1, -3, -2, -1, -1, -3, -2, -3, -1,  0, -1 ], 
    [ -2,  0,  6,  1, -3,  0,  0,  0,  1, -3, -3,  0, -2, -3, -2,  1,  0, -4, -2, -3,  3,  0, -1 ],
    [ -2, -2,  1,  6, -3,  0,  2, -1, -1, -3, -4, -1, -3, -3, -1,  0, -1, -4, -3, -3,  4,  1, -1 ],
    [  0, -3, -3, -3,  9, -3, -4, -3, -3, -1, -1, -3, -1, -2, -3, -1, -1, -2, -2, -1, -3, -3, -2 ],
    [ -1,  1,  0,  0, -3,  5,  2, -2,  0, -3, -2,  1,  0, -3, -1,  0, -1, -2, -1, -2,  0,  3, -1 ],
    [ -1,  0,  0,  2, -4,  2,  5, -2,  0, -3, -3,  1, -2, -3, -1,  0, -1, -3, -2, -2,  1,  4, -1 ],
    [  0, -2,  0, -1, -3, -2, -2,  6, -2, -4, -4, -2, -3, -3, -2,  0, -2, -2, -3, -3, -1, -2, -1 ],
    [ -2,  0,  1, -1, -3,  0,  0, -2,  8, -3, -3, -1, -2, -1, -2, -1, -2, -2,  2, -3,  0,  0, -1 ],
    [ -1, -3, -3, -3, -1, -3, -3, -4, -3,  4,  2, -3,  1,  0, -3, -2, -1, -3, -1,  3, -3, -3, -1 ],
    [ -1, -2, -3, -4, -1, -2, -3, -4, -3,  2,  4, -2,  2,  0, -3, -2, -1, -2, -1,  1, -4, -3, -1 ],
    [ -1,  2,  0, -1, -3,  1,  1, -2, -1, -3, -2,  5, -1, -3, -1,  0, -1, -3, -2, -2,  0,  1, -1 ],
    [ -1, -1, -2, -3, -1,  0, -2, -3, -2,  1,  2, -1,  5,  0, -2, -1, -1, -1, -1,  1, -3, -1, -1 ],
    [ -2, -3, -3, -3, -2, -3, -3, -3, -1,  0,  0, -3,  0,  6, -4, -2, -2,  1,  3, -1, -3, -3, -1 ],
    [ -1, -2, -2, -1, -3, -1, -1, -2, -2, -3, -3, -1, -2, -4,  7, -1, -1, -4, -3, -2, -2, -1, -2 ],
    [  1, -1,  1,  0, -1,  0,  0,  0, -1, -2, -2,  0, -1, -2, -1,  4,  1, -3, -2, -2,  0,  0,  0 ],
    [  0, -1,  0, -1, -1, -1, -1, -2, -2, -1, -1, -1, -1, -2, -1,  1,  5, -2, -2,  0, -1, -1,  0 ],
    [ -3, -3, -4, -4, -2, -2, -3, -2, -2, -3, -2, -3, -1,  1, -4, -3, -2, 11,  2, -3, -4, -3, -2 ],
    [ -2, -2, -2, -3, -2, -1, -2, -3,  2, -1, -1, -2, -1,  3, -3, -2, -2,  2,  7, -1, -3, -2, -1 ],
    [  0, -3, -3, -3, -1, -2, -2, -3, -3,  3,  1, -2,  1, -1, -2, -2,  0, -3, -1,  4, -3, -2, -1 ],
    [ -2, -1,  3,  4, -3,  0,  1, -1,  0, -3, -4,  0, -3, -3, -2,  0, -1, -4, -3, -3,  4,  1, -1 ],
    [ -1,  0,  0,  1, -3,  3,  4, -2,  0, -3, -3,  1, -1, -3, -1,  0, -1, -3, -2, -2,  1,  4, -1 ],
    [  0, -1, -1, -1, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -2,  0,  0, -2, -1, -1, -1, -1, -1 ]
  ] 

  def initialize(first_dna, second_dna)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::WARN

    @first_dna = " #{first_dna.upcase}"
    @second_dna = " #{second_dna.upcase}"

    @score = Score.new(@first_dna.length, @second_dna.length)
    (1...@first_dna.length).each do |i|
      (1...@second_dna.length).each do |j|
        @score[i,j] = [0, match(i,j), delete(i,j), insert(i,j)].max
      end
    end
  end

  def run
    @logger.debug(@score)

    max, i, j = @score.max
    @logger.debug("Highest value is #{max} at #{i} #{j}")

    top_string = @first_dna[i].chr
    bot_string = @second_dna[j].chr
    mid_string = (top_string == bot_string) ? @first_dna[i].chr : '+'

    while (true)
      up = @score[i-1, j]
      left = @score[i, j-1]
      up_left = @score[i-1, j-1]

      @logger.debug("upscore is #{up}")
      @logger.debug("leftscore is #{left}")

      if up_left >= [up, left].max
        @logger.debug('Match or Positive Mismatch')

        i -= 1
        j -= 1
        break if (up_left <= 0)

        top_string << @first_dna[i].chr
        bot_string << @second_dna[j].chr

        mid_string << if ismatch?(i, j)
                        @first_dna[i].chr
                      elsif blosum_score(i, j) > 0
                        '+'
                      else
                        ' '
                      end 
      elsif up > left
        @logger.debug('Chose up path')
        i -= 1
        top_string << @first_dna[i].chr
        bot_string << '-'
        mid_string << ' '
      else
        @logger.debug('Chose left path')
        j -= 1
        top_string << '-'
        bot_string << @second_dna[j].chr
        mid_string << ' '
      end

      break if (i == 0 && j == 0)
      break if (@score[i, j] == 0)
    end

    top_string.reverse!
    mid_string.reverse!
    bot_string.reverse!

    strTop = "#{j} #{bot_string}"
    strBot = "#{i} #{top_string}"

    p strTop
    p '  ' + mid_string
    p strBot

    p @second_dna
    @logger.debug(@score)
  end

  def ismatch?(i, j)
    @first_dna[i] == @second_dna[j]
  end
 
  def match(i, j)
    @score[i-1, j-1] + blosum_score(i, j)
  end

  def delete(i, j)
    @score[i-1, j] - GAP_PENALTY
  end

  def insert(i, j)
    @score[i, j-1] - GAP_PENALTY
  end

  def blosum_score(i, j)
    BLOSUM62[INDEX.index(@first_dna[i].chr)][INDEX.index(@second_dna[j].chr)]
  end
end

if __FILE__ == $0
  # Uh - right now first should be SECOND (aka bottom)
  # and second is first - aka TOP string. crazy, right?
  sw = SmithWatermann.new('deadly', 'ddgearlyk')
  sw.run
end
