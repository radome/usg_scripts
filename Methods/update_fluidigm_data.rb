def update_fluidigm_data(machine_barcode)
  plate = Plate.with_machine_barcode(machine_barcode).first
  data = IrodsReader::DataObj.find('seq','dcterms:audience'=>configatron.irods_audience, :fluidigm_plate=>plate.fluidigm_barcode)

  next if data.empty?
  raise StandardError, "Multiple files found" if data.size > 1

  file = FluidigmFile.new(data.first.retrieve)

  raise StandardError, "File does not match plate" unless file.for_plate?(plate.fluidigm_barcode)

  plate.wells.located_at(file.well_locations).include_stock_wells.each do |well|
    well.stock_wells.each do |sw|
      sw.update_gender_markers!( file.well_at(well.map_description).gender_markers,'FLUIDIGM' )
      sw.update_sequenom_count!( file.well_at(well.map_description).count,'FLUIDIGM' )
    end
  end
end
