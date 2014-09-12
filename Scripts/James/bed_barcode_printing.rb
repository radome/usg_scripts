
class BedBarcodePrinter

  attr_reader :width, :height, :prefix, :labels, :custom_labels

  def initialize(beds,printer_name)
    @beds = beds
    @printer = BarcodePrinter.find_by_name(printer_name)
    @service = @printer.service
    create_labels
  end

  def create_labels
    @labels = @beds.map do |bed|
      PrintBarcode::Label.new(:prefix=>'BD',:number=>bed[:number],:study=>bed[:name])
    end
  end
  private :create_labels

  def print(copies=1)
    @service.print_labels(Array(labels)*copies, @printer.name, @printer.barcode_printer_type.printer_type_id)
  end

end

beds = [
  {:name=>'Bed 1',:number=>1},
  {:name=>'Bed 2',:number=>2},
  {:name=>'Bed 3',:number=>3},
  {:name=>'Bed 4',:number=>4},
  {:name=>'Bed 5',:number=>5},
  {:name=>'Bed 6',:number=>6},
  {:name=>'Bed 7',:number=>7},
  {:name=>'Bed 8',:number=>8},
  {:name=>'Bed 9',:number=>9},
  {:name=>'Bed 10',:number=>10},
  {:name=>'Bed 11',:number=>11},
  {:name=>'Bed 12',:number=>12},
  {:name=>'Car. 1,3',:number=>13},
  {:name=>'Car. 2,3',:number=>23},
  {:name=>'Car. 4,3',:number=>43}
]
printer = 'd304bc'

nxb = BedBarcodePrinter.new(beds,printer)
nxb.print(1)
