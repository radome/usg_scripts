def update_event(batch_id,descriptions,descriptor,value)
  LabEvent.where(batch_id: batch_id).where(description: descriptions).each do |lab|
    if lab[:descriptor_fields].include?(descriptor)
      lab[:descriptors][descriptor] = value
      lab.save!
    else
      raise "Unable to find #{descriptor} in descriptor_fields"
    end
  end; nil
  # rebroadcast
  batch = Batch.find batch_id
  batch.touch
end
# update_event(b.id,'Cluster Generation','Chip Barcode','HTNKVCCXY')
# update_event(xxxxx,'Cluster Generation','Cartridge barcode','XXXXXXX-050V2')
# LabEvent.where(batch_id: batch_id).where(description: descriptions).map {|e| e[:descriptors].delete("Chip barcode"); e.save!}
# descriptions = ['Loading','Read 1 & 2']; descriptors = 'Chip barcode'; value = 'HGSXXXSXX'
# descriptions.each {|description| puts description; update_event(batch_id,description,descriptors,value)}
