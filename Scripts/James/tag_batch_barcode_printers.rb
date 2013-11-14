
class TagBatchBarcodePrinter

  attr_reader :batch_size, :user, :idt, :labels

  def initialize(options)
    @batch_id   = options[:batch_id]
    @batch_size = options[:batch_size]
    @user       = options[:user]
    @idt        = options[:idt]
    create_labels
  end

  def prefix
    'UD'
  end

  def batch_id
    @batch_id * 1000
  end

  def create_labels
    @labels = (1..batch_size).map do |i|
      PrintBarcode::Label.new(:prefix=>prefix,:number=>batch_id+i,:study=>"IDT:#{idt} #{user}")
    end
  end
  private :create_labels

  def print(printer_name,copies=1)
    printer = BarcodePrinter.find_by_name(printer_name)
    service = printer.service
    service.print_labels(Array(labels)*copies, printer.name, printer.barcode_printer_type.printer_type_id)
  end

end

nxb = TagBatchBarcodePrinter.new(
  :batch_id => 1,
  :batch_size => 80,
  :user => 'user_id',
  :idt =>1234567
)
nxb.print('printer_name',1)
