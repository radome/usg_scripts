def update_phix_in_batch(batch_id,phix_tube)
  ActiveRecord::Base.transaction do
    batch = Batch.find_by_id batch_id
    batch.assets.each do |lane|
      AssetLink.create_edge(phix_tube,lane)
    end
    batch.touch # batch xml will not display without this
  end
end

# find the SpikedBuffer tube that was meant to be used
# this should have a volume ~4ul
# if it is ~200-400ul then this is the LibraryTube
# and you need one of it's children using

  sb = Asset.find_by_id tube_id # of b = Asset.find_by_barcode barcode
  sb.sti_type = 'SpikedBuffer'; sb.save!

# update the batches
batches = [12345,23456,34567,45678]
batches.each do |batch_id|
  update_phix_in_batch(batch_id,sb)
end

