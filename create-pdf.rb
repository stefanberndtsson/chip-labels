require 'prawn'
require 'prawn/measurement_extensions'
require_relative 'chip-parser'

class CreatePDF
  def initialize(filenames)
    @pdf = Prawn::Document.new(page_size: "A4")
    @page_root = @pdf.cursor
    @data = filenames.map do |file|
      ChipParser.new(file)
    end.sort_by { |x| [(x.ref || '').gsub(/[^\d]/,'').to_i, x.ref] }
    @max_pins = @data.map(&:pincount).max
    @max_height = from_mil(@data.map {|x| x.pincount * x.pinpitch }.max)*0.625
    @max_width = from_mil(@data.map(&:chipwidth).max)*2

    @data = @data.each_slice(6).to_a
    render
  end

  def render
    @data.each.with_index do |chip_row,row|
      chip_row.each.with_index do |chip,col|
        render_chip(chip, row, col)
      end
    end
  end

  def render_chip(chip, row, col)
    if chip.name
      @pdf.bounding_box([col*@max_width+(@max_width+from_mil(chip.chipwidth))/2,@page_root-(row*@max_height)],
                        width: @max_width,
                        height: 12) do
        @pdf.text_box(chip.name, at: [4,6], size: 6, align: :center)
        @pdf.text_box(chip.ref, at: [4,12], size: 6, align: :center) if chip.ref
      end
    end
    @pdf.bounding_box([col*@max_width+@max_width, @page_root-(row*@max_height)-12],
                      width: 4+from_mil(chip.chipwidth),
                      height: from_mil(chip.chipheight)+1) do
      (chip.pincount/2).times do |pin_row|
        @pdf.text_box(chip.pins_left[pin_row],
                      at: [2,@pdf.cursor-(pin_row*from_mil(chip.pinpitch)+3)],
                      size: font_size(chip))
        @pdf.text_box(chip.pins_right[pin_row],
                      at: [2,@pdf.cursor-(pin_row*from_mil(chip.pinpitch)+3)],
                      align: :right,
                      width: from_mil(chip.chipwidth),
                      size: font_size(chip))
      end
      @pdf.line_width = 0.1
      @pdf.stroke_bounds
    end
  end

  def font_size(chip)
    longest_pair = chip.pins_left.zip(chip.pins_right).sort_by {|x| -(x[0].size+x[1].size) }.first.map(&:size).inject(&:+)
    return 3 if chip.chipwidth <= 300 && longest_pair >= 7
    return 3 if chip.chipwidth > 300 && longest_pair >= 10
    4
  end

  def from_mil(value)
    (value.to_f/1000.0).in
  end

  def save(filename)
    @pdf.render_file(filename)
  end
end
