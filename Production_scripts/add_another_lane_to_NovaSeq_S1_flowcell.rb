def add_another_lane_to_NovaSeq_S1_flowcell(submission_id)
  sub = Submission.find submission_id
  new_seq_request = subatch.requests.first.dup # dup the sequencing request
  new_seq_request.request_metadata = subatch.requests.first.request_metadata.dup
  new_seq_request.save!
  lane = subatch.requests.first.target_asset
  new_lane = l.dup
  new_lane.aliquots << lane.aliquots.map(&:dup); nil
  new_lane.save!
  new_seq_request.target_asset = new_lane
  new_seq_request.save!
  mx = lane.parents.first
  sb = lane.parents.last
  AssetLink.create!(:ancestor => mx, :descendant => new_lane)
  AssetLink.create!(:ancestor => sb, :descendant => new_lane)
  AliquotIndexer.index(new_lane); new_lane.save!
  batch = Batch.find 67976
  BatchRequest.create!(batch_id: batch.id, request_id: new_seq_request.id, position: 2)
  LabEvent.where(eventful_id: batch.requests.first.id).each do |event|
    new_event = event.dup
    new_event.eventful_id= new_seq_request.id
    new_event.save!
  end
  batch.reload
  batch.touch
end





