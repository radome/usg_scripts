def remove_duplicated_wells(plate_barcode)
  ActiveRecoed::Base.transaction do
    stp = Plate.find_by_barcode(barcode)
    locs = stp.wells.select {|w| w.aliquots.size == 0}.flatten.map(&:map_description) 
    wells =stp.wells.located_at(locs).select {|w| w.aliquots.size == 1}; nil
    wells.map(&:requests_as_target).flatten.map(&:retrospective_fail!); nil
    wells.map(&:transfer_requests_as_target).flatten.map(&:cancel!); nil
    wells.map(&:aliquots).flatten.map(&:destroy); nil
    wells.map(&:destroy); nil
  end
end


p.wells.each do |w|
  wells=p.wells.located_at(w.map_description)
  if wells.size > 1
    wells.select {|r| r.aliquots.size == 0}.first.destroy
  end
end