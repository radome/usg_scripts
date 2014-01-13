def change_well_concentration(barcode,locations,conc,mode)
  ActiveRecord::Base.transaction do
    plate = PlatePurpose.find_by_name("Stock Plate").plates.find_by_barcode(barcode.to_s) or raise "Cannot find stock plate"
    plate.wells.located_at(locations).each do |well|
      puts "well: #{well.map_description} conc #{well.well_attribute.concentration} => #{conc}"
      well.well_attribute.update_attributes!(:concentration => conc)
    end
    raise "Test mode" unless mode == "run"
  end
end