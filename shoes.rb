$app = Shoes.app(:width => 256) do
  background(gradient('#CFF', '#FFF'))
  @output = stack(:margin => 10)

  def display text
    @output.append do
      if text =~ /^([^:]+): (.*)$/
        para nick("#{$1}: "), $2
      else
        para text
      end
    end
  end

  def error text
    para "EROEOEOEOEOOE!!"
    para text
  end

  def simple_para text
    para text
  end
end
