def add_hyb_buffer_to_batch_lanes(batch_id,buffer_id,mode)
  ActiveRecord::Base.transaction do
    Batch.find(batch_id).requests.each do |request|
      request.target_asset.spiked_in_buffer = SpikedBuffer.find(buffer_id)
      request.save!
    end
    raise "running in test mode" unless mode == "run"
  end
end