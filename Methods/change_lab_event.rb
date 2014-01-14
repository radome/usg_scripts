def change_chip_barcode(batch_id,description,new_chip_name,label)
  ActiveRecord::Base.transaction do
    LabEvent.find_all_by_batch_id(batch_id).select {|e| e.description == description}.each {|lab| lab[:descriptors][label] = new_chip_name ; lab.save!}
  end
end
