def change_chip_barcode(batch_id,description,descriptors,value)
  ActiveRecord::Base.transaction do
    LabEvent.where(batch_id: batch_id).select {|e| e.description == description}.each {|lab| lab[:descriptors][descriptors] = value ; lab.save!}
    # rebroadcast
    batch = Batch.find batch_id
    batch.rebroadcast
  end
end
# change_chip_barcode(b.id,'Cluster generation','Chip Barcode',v)
