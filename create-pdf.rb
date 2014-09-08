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
    fontsz = font_size(chip)
    chipwidth = from_mil(chip.chipwidth)
    chipheight = from_mil(chip.chipheight)
    pinpitch = from_mil(chip.pinpitch)
    if chip.name
      @pdf.bounding_box([col*@max_width+(@max_width+chipwidth)/2,@page_root-(row*@max_height)],
                        width: @max_width,
                        height: 12) do
        @pdf.text_box(chip.name, at: [4,6], size: 6, align: :center)
        @pdf.text_box(chip.ref, at: [4,12], size: 6, align: :center) if chip.ref
      end
    end
    @pdf.bounding_box([col*@max_width+@max_width, @page_root-(row*@max_height)-12],
                      width: 4+chipwidth,
                      height: chipheight+1) do
      (chip.pincount/2).times do |pin_row|
        left = chip.pins_left[pin_row]
        if left[0..0] == "/"
          left = left[1..-1]
          left_width = @pdf.width_of(left, size: fontsz, kerning: true)
          @pdf.line([2,@pdf.cursor-(pin_row*pinpitch+2)], [left_width+2,@pdf.cursor-(pin_row*pinpitch+2)])
        end
        @pdf.text_box(left,
                      at: [2,@pdf.cursor-(pin_row*pinpitch+3)],
                      size: fontsz)


        right = chip.pins_right[pin_row]
        if right[0..0] == "/"
          right = right[1..-1]
          right_width = @pdf.width_of(right, size: fontsz, kerning: true)
          @pdf.line([2+chipwidth-right_width,@pdf.cursor-(pin_row*pinpitch+2)], [2+chipwidth,@pdf.cursor-(pin_row*pinpitch+2)])
        end
        @pdf.text_box(right,
                      at: [2,@pdf.cursor-(pin_row*pinpitch+3)],
                      align: :right,
                      width: chipwidth,
                      size: fontsz)
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
