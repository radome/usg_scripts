def transfer_well_aliquots(stp_barcode,wdp_barcode)
  ActiveRecord::Base.transaction do
    stp = Plate.find_by_barcode(stp_barcode)
    wdp = Plate.find_by_barcode(wdp_barcode)
    locs = stp.conatined_aliquots.map(&:receptacle).map(&:map_description)
    locs.each do |loc|
      wdp.wells.located_at(loc).first.aliquots << stp.wells.located_at(loc).first.aliquots.map(&:dup)
    end
  end
end
