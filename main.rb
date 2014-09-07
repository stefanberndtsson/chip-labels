require_relative 'create-pdf'

if ARGV.empty?
  puts "Usage: #{$0} output.pdf input1.txt [input2.txt ...]"
  exit
end

output_file = ARGV.shift
pdf = CreatePDF.new(ARGV)
pdf.save(output_file)

