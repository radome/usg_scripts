def update_infinium_barcode(barcodes,mode)
  ActiveRecord::Base.transaction do
    barcodes.each do |new_barcode,barcode|
      pm = Plate::Metadata.find(:first, :conditions => {:infinium_barcode => barcode})
      pm.update_attributes!(:infinium_barcode => new_barcode)
    end
  raise "Hell!!!" unless mode == 'run'
  end
end
# barcodes = {new => old}
