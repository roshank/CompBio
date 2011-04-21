require 'logger'
require 'minitest/autorun'
require 'net/http'
require 'open-uri'

class Permuter
  def initialize(first_dna, second_dna, points)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::WARN
    @true_matrix = points
    @first_dna = "#{first_dna.upcase}"
    @second_dna = "#{second_dna.upcase}"
  end
  
  def permute(n)
    k = 0

    n.downto(1) do |counter|
      permuted_dna = @first_dna.dup
      (0...permuted_dna.length).each do |i|
        j = rand(i)
        tmp = permuted_dna[i]
        permuted_dna[i] = permuted_dna[j]
        permuted_dna[j] = tmp
      end
      sw = SmithWaterman.new(permuted_dna, @second_dna)
      if (sw.matrix.max > @true_matrix)
        k+=1
      end
    end

    pval = (Float(k+1) / Float(n+1))
    @logger.debug('pVal ' + pval.to_s + ' over ' + n.to_s + ' permutations')
    return pval
  end
end

module SmithWaterman
  class Matrix
    GAP_PENALTY = 4
    INDEX = %w[ a r n d c q e g h i l k m f p s t w y v b z x ]
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

    def initialize(x, y)
      @x = " #{x.downcase}"
      @y = " #{y.downcase}"
      @matrix = Array.new(@x.length) { Array.new(@y.length, 0) }

      # Build the matrix
      (1...@x.length).each do |i|
        (1...@y.length).each do |j|
          @matrix[i][j] = [0, match(i,j), delete(i,j), insert(i,j)].max
        end
      end
    end

    def backtrack
      i, j = index(max)

      top = @x[i].chr
      bottom = @y[j].chr
      middle = (top == bottom) ? top.dup : '+'

      while @matrix[i][j] != 0
        dir, _ = [[:diag, @matrix[i-1][j-1]],
                  [:up, @matrix[i-1][j]],
                  [:left, @matrix[i][j-1]]].max {|(_,a),(_,b)| a <=> b }

        i -= 1 if [:diag, :up].include?(dir)
        j -= 1 if [:diag, :left].include?(dir)

        top << ((dir != :left) ? @x[i].chr : '-')
        bottom << ((dir != :up) ? @y[j].chr : '-')

        middle << ((dir == :diag) ? ((@x[i] == @y[j]) ? @x[i].chr : '.') : ' ')
      end

      top.reverse!
      middle.reverse!
      bottom.reverse!

      [top, middle, bottom]
    end

    # Matrix operations
    def [](i, j); @matrix[i][j]; end
    def []=(i, j, val); @matrix[i][j] = val; end
    def max; @matrix.flatten.max; end
    def index(value); @matrix.flatten.index(value).divmod(@y.length); end

    # Output
    def print(first_prefix, second_prefix)
      top_string, mid_string, bot_string = backtrack

      first_prefix = "#{first_prefix} #{i} "
      second_prefix = "#{second_prefix} #{j} "

      prefixBuffer = [first_prefix.length, second_prefix.length].max
      top_prefix = second_prefix.center(prefixBuffer)
      bot_prefix = first_prefix.center(prefixBuffer)

      mid_skip_char = " ".center([top_prefix.length, bot_prefix.length].max)

      strTop = "#{bot_string}"
      strBot = "#{top_string}"
      strMid = " #{mid_string}"

      lines = [strTop.length, strMid.length, strBot.length].max / 60
      i = 0
      while i <= lines
        pos = i*60
        p "#{bot_prefix}" + strTop[pos, pos+60]
        p "#{mid_skip_char}" + strMid[pos+1, pos+60]
        p "#{top_prefix}" + strBot[pos, pos+60]
        i+=1
      end
    end

    def inspect; @matrix.inspect; end
    def to_s
      out = "  #{@y.split(//).join('  ')}\n"
      @matrix.each_with_index do |row,i|
        out << @x[i] << ' ' << row.join('  ') << "\n"
      end
      out
    end

    # For building the matrix
    def match(i, j); @matrix[i-1][j-1] + blosum(i, j); end
    def delete(i, j); @matrix[i-1][j] - GAP_PENALTY; end
    def insert(i, j); @matrix[i][j-1] - GAP_PENALTY; end
    def blosum(i, j)
      BLOSUM62[INDEX.index(@x[i].chr)][INDEX.index(@y[j].chr)]
    end
  end

  attr_reader :matrix

  # def initialize(first_dna, second_dna)
  #   @logger = Logger.new(STDOUT)
  #   @logger.level = Logger::WARN
  #   
  #   @first_dna = first_dna.upcase
  #   @second_dna = second_dna.upcase
  #   
  #   @matrix = Matrix.new(@first_dna, @second_dna)
  # end
  
  def print(first_prefix, second_prefix)
    max = @matrix.max
    i, j = @matrix.index(max)
    @logger.debug("Highest value is #{max} at #{i} #{j}")
    top_string = @first_dna[i].chr
    bot_string = @second_dna[j].chr
    mid_string = (top_string == bot_string) ? @first_dna[i].chr : '+'

    while (true)
      up = @matrix[i-1, j]
      left = @matrix[i, j-1]
      up_left = @matrix[i-1, j-1]

      @logger.debug("upmatrix is #{up}")
      @logger.debug("leftmatrix is #{left}")

      if up_left >= [up, left].max
        @logger.debug('Match or Positive Mismatch')

        i -= 1
        j -= 1
        break if (up_left <= 0)

        top_string << @first_dna[i].chr
        bot_string << @second_dna[j].chr

        mid_string << if @first_dna[i] == @second_dna[j]
                        @first_dna[i].chr
                      elsif @matrix.blosum(i, j) > 0
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
      break if (@matrix[i, j] == 0)
    end

    top_string.reverse!
    mid_string.reverse!
    bot_string.reverse!
    
    first_prefix = "#{first_prefix} #{i} "
    second_prefix = "#{second_prefix} #{j} "
    
    prefixBuffer = [first_prefix.length, second_prefix.length].max
    top_prefix = second_prefix.center(prefixBuffer)
    bot_prefix = first_prefix.center(prefixBuffer)

    mid_skip_char = " ".center([top_prefix.length, bot_prefix.length].max)
    
    strTop = "#{bot_string}"
    strBot = "#{top_string}"
    strMid = " #{mid_string}"
  
    lines = [strTop.length, strMid.length, strBot.length].max / 60
    i = 0
    while i <= lines
      pos = i*60
      p "#{bot_prefix}" + strTop[pos, pos+60]
      p "#{mid_skip_char}" + strMid[pos+1, pos+60]
      p "#{top_prefix}" + strBot[pos, pos+60]
      i+=1
    end
    
    @logger.debug(@matrix)
  end

  class FastA
    attr_accessor :dna, :html

    def initialize(code)
      @html = open("http://www.uniprot.org/uniprot/#{code}.fasta").read
      @dna = html.split(/\n/)[1..-1].join
    end
  end
end

def get_fasta(code)
  html = open("http://www.uniprot.org/uniprot/#{code}.fasta").read
  html.split(/\n/)[1..-1].join
end

class TestSmithWaterman < MiniTest::Unit::TestCase
  include SmithWaterman

  def test_matrix
    matrix = Matrix.new('ddgearlyk', 'deadly')
    max = matrix.max
    assert_equal(20, max)
    assert_equal([8, 6], matrix.index(max))
    
    top, middle, bottom = matrix.backtrack
    assert_equal(' ddgearly', top)
    assert_equal(' d  ea.ly', middle)
    assert_equal(' d--eadly', bottom)
  end

  def test_fasta
    fasta = FastA.new('P15172')
    dna = <<-DNA
      MELLSPPLRDVDLTAPDGSLCSFATTDDFYDDPCFDSPDLRFFEDLDPRLMHVGALLKPE
      EHSHFPAAVHPAPGAREDEHVRAPSGHHQAGRCLLWACKACKRKTTNADRRKAATMRERR
      RLSKVNEAFETLKRCTSSNPNQRLPKVEILRNAIRYIEGLQALLRDQDAAPPGAAAAFYA
      PGPLPPGRGGEHYSGDSDASSPRSNCSDGMMDYSGPPSGARRRNCYEGAYYNEAPSEPRP
      GKSAAVSSLDCLSSIVERISTESPAAPALLLADVPSESPPRRQEAAAPSEGESSGDPTQS
      PDAAPQCPAGANPNPIYQVL
    DNA
    assert_equal(dna.gsub(/\s/, ''), fasta.dna)
  end
end

__END__

TESTDATA = [['TEST1','ddgearlyk'],['TEST2','deadly']]

REALDATA = %w[P15172 P17542 P10085 P16075 P13904 Q90477 Q8IU24 P22816 Q10574 O95363]

# FLAGS for assignment. DO_TEST works on 'deadly v ddgearlyk'
# DO_ALIGN works on aligning all proteins in REALDATA
# DO_PVAL calculates the pval for a couple proteins on 1000 permutations
DO_TEST = 1
DO_ALIGN = 1
DO_PVAL = 0

if __FILE__ == $0
  (0...TESTDATA.length).each do |i|
    (i+1...TESTDATA.length).each do |j|
      matrix = SmithWaterman::Matrix.new(TESTDATA[i][1], TESTDATA[j][1])
      perm = Permuter.new(TESTDATA[i][1], TESTDATA[j][1], matrix.max)
      perm.permute(1)

      sw = SmithWaterman.new(TESTDATA[i][1], TESTDATA[j][1])
      sw.print(TESTDATA[i][0], TESTDATA[j][0])
      puts sw.matrix
    end
  end
  
  if DO_ALIGN == 1
    (0...REALDATA.length).each do |i|
      (i+1...REALDATA.length).each do |j|
        dna1 = get_fasta(REALDATA[i])
        dna2 = get_fasta(REALDATA[j])
        sw = SmithWaterman.new(dna1, dna2)
      
        p "Matching DNA #{REALDATA[i]} #{REALDATA[j]}"
        sw.print(REALDATA[i], REALDATA[j])
      end
    end
  end
  
  if DO_PVAL == 1
    sw = SmithWaterman.new(get_fasta('Q10574'),get_fasta('P15172'))
    perm = Permuter.new(get_fasta('Q10574'),get_fasta('P15172'), sw.get_max)
    p "Pval of P15172 : Q10574 on 1000 permutations is: #{perm.permute(1000)}"
    
    sw = SmithWaterman.new(get_fasta('O95363'),get_fasta('P15172'))
    perm = Permuter.new(get_fasta('O95363'),get_fasta('P15172'), sw.get_max)
    p "Pval of P15172 : O95363 on 1000 permutations is: #{perm.permute(1000)}"
  end
end
