require 'logger'
require 'minitest/autorun'
require 'net/http'

class Permuter
  def initialize(first_dna, second_dna, points)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::WARN
    @true_score = points
    @first_dna = "#{first_dna.upcase}"
    @second_dna = "#{second_dna.upcase}"
  end
  
  def permute(n)
    counter = n
    k = 0
    while (counter > 0)
      permuted_dna = @first_dna
      (0...permuted_dna.length).each do |i|
        j = rand(i)
        tmp = permuted_dna[i]
        permuted_dna[i] = permuted_dna[j]
        permuted_dna[j] = tmp
      end
      sw = SmithWatermann.new(permuted_dna, @second_dna)
      counter -= 1
      if (sw.score.max > @true_score)
        k+=1
      end
    end
    pval = (Float(k+1) / Float(n+1))
    @logger.debug('pVal ' + pval.to_s + ' over ' + n.to_s + ' permutations')
    return pval
  end
end

class SmithWatermann
  class Score
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
      @x = x.downcase
      @y = y.downcase
      @score = Array.new(@x.length) { Array.new(@y.length, 0) }
      (1...@x.length).each do |i|
        (1...@y.length).each do |j|
          @score[i][j] = [0, match(i,j), delete(i,j), insert(i,j)].max
        end
      end
    end

    def [](i, j)
      @score[i][j]
    end

    def []=(i, j, val)
      @score[i][j] = val
    end

    def max
      @score.flatten.max
    end

    def index(value)
      @score.flatten.index(value).divmod(@y.length)
    end

    def to_s
      out = "  #{@y.split(//).join('  ')}\n"
      @score.each_with_index do |row,i|
        out << @x[i] << ' ' << row.join('  ') << "\n"
      end
      out
    end

    def inspect
      @score.inspect
    end

    def match(i, j)
      @score[i-1][j-1] + blosum_score(i, j)
    end

    def delete(i, j)
      @score[i-1][j] - GAP_PENALTY
    end

    def insert(i, j)
      @score[i][j-1] - GAP_PENALTY
    end

    def blosum_score(i, j)
      BLOSUM62[INDEX.index(@x[i].chr)][INDEX.index(@y[j].chr)]
    end
  end

  attr_reader :score

  def initialize(first_dna, second_dna)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::WARN
    
    @first_dna = " #{first_dna.upcase}"
    @second_dna = " #{second_dna.upcase}"
    
    @score = Score.new(@first_dna, @second_dna)
  end

  def print(first_prefix, second_prefix)
    max = @score.max
    i, j = @score.index(max)
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

        mid_string << if @first_dna[i] == @second_dna[j]
                        @first_dna[i].chr
                      elsif @score.blosum_score(i, j) > 0
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
    
    first_prefix = "#{first_prefix} #{i} "
    second_prefix = "#{second_prefix} #{j} "
    
    prefixBuffer = [first_prefix.length, second_prefix.length].max
    top_prefix = second_prefix.center(prefixBuffer)
    bot_prefix = first_prefix.center(prefixBuffer)

    mid_skip_char = " ".center([top_prefix.length, bot_prefix.length].max - 1)
    
    strTop = "#{bot_string}"
    strBot = "#{top_string}"
    strMid = " #{mid_string}"
  
    lines = [strTop.length, strMid.length, strBot.length].max / 60
    i = 0
    while i <= lines
      pos = i*60
      p "#{bot_prefix}" + strTop[pos, pos+60]
      p "#{mid_skip_char}" + strMid[pos, pos+60]
      p "#{top_prefix}" + strBot[pos, pos+60]
      i+=1
    end
    
    @logger.debug(@score)
  end
end

def get_fasta(code)
  html = Net::HTTP.get URI.parse("http://www.uniprot.org/uniprot/#{code}.fasta")
  html = html.split(%r{\n})
  dna = ""
  html.each_index do |i|
    unless i == 0
      dna = dna + html[i]
    end
  end
  return dna
end

# class TestSmithWatermann < MiniTest::Unit::TestCase
#   TEST_SET = [
#     %w[ TEST1 ddgearlyk ],
#     %w[ TEST2 deadly ]
#   ]
# 
#   REALDATA = %w[P15172 P17542 P10085 P16075 P13904 Q90477 Q8IU24 P22816 Q10574 O95363]
# 
#   def test_sw
#     score = SmithWatermann::Score.new('ddgearlyk', 'deadly')
#     sw = SmithWatermann.new('ddgearlyk', 'deadly')
#     perm = Permuter.new('ddgearlyk', 'deadly', score.max[0])
#     perm.permute(1)
#     sw.print('TEST1', 'TEST2')
#     assert_equal(1, 2)
#   end
# end

TESTSET = [['TEST1','ddgearlyk'],['TEST2','deadly']]

REALDATA = %w[P15172 P17542 P10085 P16075 P13904 Q90477 Q8IU24 P22816 Q10574 O95363]

DO_ALIGN = 0
DO_PVAL = 0

#DNASET = [['P15172','MELLSPPLRDVDLTAPDGSLCSFATTDDFYDDPCFDSPDLRFFEDLDPRLMHVGALLKPEEHSHFPAAVHPAPGAREDEHVRAPSGHHQAGRCLLWACKACKRKTTNADRRKAATMRERRRLSKVNEAFETLKRCTSSNPNQRLPKVEILRNAIRYIEGLQALLRDQDAAPPGAAAAFYAPGPLPPGRGGEHYSGDSDASSPRSNCSDGMMDYSGPPSGARRRNCYEGAYYNEAPSEPRPGKSAAVSSLDCLSSIVERISTESPAAPALLLADVPSESPPRRQEAAAPSEGESSGDPTQSPDAAPQCPAGANPNPIYQVL'],
#          ['P17542','MTERPPSEAARSDPQLEGRDAAEASMAPPHLVLLNGVAKETSRAAAAEPPVIELGARGGPGGGPAGGGGAARDLKGRDAATAEARHRVPTTELCRPPGPAPAPAPASVTAELPGDGRMVQLSPPALAAPAAPGRALLYSLSQPLASLGSGFFGEPDAFPMFTTNNRVKRRPSPYEMEITDGPHTKVVRRIFTNSRERWRQQNVNGAFAELRKLIPTHPPDKKLSKNEILRLAMKYINFLAKLLNDQEEEGTQRAKTGKDPVVGAGGGGGGGGGGAPPDDLLQDVLSPNSSCGSSLDGAASPDSYTEEPAPKHTARSLHPAMLPAADGAGPR'],          [],
#          [],
#          [],
if __FILE__ == $0
  (0...TESTSET.length).each do |i|
    (i+1...TESTSET.length).each do |j|
      score = SmithWatermann::Score.new(TESTSET[i][1], TESTSET[j][1])
      perm = Permuter.new(TESTSET[i][1], TESTSET[j][1], score.max)
      perm.permute(1)

      sw = SmithWatermann.new(TESTSET[i][1], TESTSET[j][1])
      sw.print(TESTSET[i][0], TESTSET[j][0])
      puts sw.score
    end
  end
  
  if DO_ALIGN == 1
    (0...REALDATA.length).each do |i|
      (i+1...REALDATA.length).each do |j|
        dna1 = get_fasta(REALDATA[i])
        dna2 = get_fasta(REALDATA[j])
        sw = SmithWatermann.new(dna1, dna2)
        perm = Permuter.new(dna1, dna2, sw.run)
        #perm.permute(1)
      
        p "Matching DNA #{REALDATA[i]} #{REALDATA[j]}"
        sw.print(REALDATA[i], REALDATA[j])
      end
    end
  end
  
  if DO_PVAL == 1
    sw = SmithWatermann.new(get_fasta('Q10574'),get_fasta('P15172'))
    perm = Permuter.new(get_fasta('Q10574'),get_fasta('P15172'), sw.run)
    p "Pval of P15172 : Q10574 on 1000 permutations is: #{perm.permute(1000)}"
    
    sw = SmithWatermann.new(get_fasta('O95363'),get_fasta('P15172'))
    perm = Permuter.new(get_fasta('O95363'),get_fasta('P15172'), sw.run)
    p "Pval of P15172 : O95363 on 1000 permutations is: #{perm.permute(1000)}"
  end
  
end
