# first find the SpikedBuffer tube that was meant to be used
def update_phix_in_batch(batch_id,phix_tube)
  batch = Batch.find_by_id batch_id
  batch.assets.each do |lane|
    AssetLink.connect(phix_tube,lane)
  end
  batch.touch # batch xml will not display without this
end
