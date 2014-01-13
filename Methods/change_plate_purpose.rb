# list purpose id, name -- don't rely on user providing correct syntax
pp Purpose.all.map {|p| [p.id, p.name]}

# One
def change_plate_purpose(barcode,purpose_name,mode)
  ActiveRecord::Base.transaction do
    plate = Plate.find_by_barcode(barcode.to_s)
    puts "Changing plate #{barcode} purpose from #{plate.plate_purpose.name} to #{purpose_name}"
    plate.plate_purpose = PlatePurpose.find_by_name(purpose_name)
    plate.save!
    raise "Hell!" unless mode == "run"
  end
end

# Many
def change_plate_purposes(barcodes,purpose_name,mode)
  ActiveRecord::Base.transaction do
    barcodes.each do |barcode|
      plate = Plate.find_by_barcode(barcode.to_s)
      puts "Changing plate #{barcode} purpose from #{plate.plate_purpose.name} to #{purpose_name}"
      plate.plate_purpose = PlatePurpose.find_by_name(purpose_name)
      plate.save!
    end
    raise "Hell!" unless mode == "run"
  end
end

