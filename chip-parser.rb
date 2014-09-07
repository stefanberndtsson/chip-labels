require 'pp'

class ChipParser
  attr_reader :structure

  def initialize(datafile)
    @raw = File.read(datafile)
  end

  def structure
    return @structure if @structure
    parse_raw
    @structure
  end

  def pincount
    structure[:pincount]
  end

  def pinpitch
    structure[:pinpitch]
  end

  def chipwidth
    structure[:chipwidth]*0.8
  end

  def chipheight
    0.5*structure[:pincount]*structure[:pinpitch]
  end

  def pins_left
    structure[:left]
  end

  def pins_right
    structure[:right]
  end

  def parse_raw
    @structure = {}
    @raw.split(/\n/).each do |row|
      if row[/^(\d+) (.*)$/]
        @structure[:pins] ||= {}
        @structure[:pins][$1.to_i] = $2
      elsif row[/^PINCOUNT (\d+)$/]
        @structure[:pincount] = $1.to_i
      elsif row[/^PINPITCH ([\d\.]+)(.*)$/]
        value = $1.to_f
        unit = $2
        @structure[:pinpitch] = to_mil(unit, value)
      elsif row[/^CHIPWIDTH ([\d\.]+)(.*)$/]
        value = $1.to_f
        unit = $2
        @structure[:chipwidth] = to_mil(unit, value)
      elsif row[/^\s*#/]
        next
      else
        raise UnknownData
      end
    end
    validate_structure
    position_pins
  end

  def position_pins
    @structure[:left] ||= []
    @structure[:right] ||= []
    (pincount/2).times do |pinnum|
      @structure[:left] << @structure[:pins][pinnum+1]
    end
    (pincount/2).times do |pinnum|
      @structure[:right] << @structure[:pins][pincount-pinnum]
    end
    
  end

  def to_mil(unit, value)
    return value.to_i if unit == "mil"
    raise UnknownUnit
  end

  def validate_structure
    raise StructureMissingPinCount if !@structure[:pincount]
    raise StructureMissingPinPitch if !@structure[:pinpitch]
    raise StructureMissingChipWidth if !@structure[:chipwidth]
    raise StructurePinCountWrong if @structure[:pins].count != @structure[:pincount]
    true
  end
end

if __FILE__ == $0
  cp = ChipParser.new("mcp23s17-data.txt")
  pp cp.structure
end
