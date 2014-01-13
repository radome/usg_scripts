def change_bait_library(submissions,bait_id,mode)
  ActiveRecord::Base.transaction do
    submissions.each do |sub|
      submission  = Submission.find(sub)
      # order.request_options.hash <= look!
      bait_lib    = BaitLibrary.find(bait_id)
      request_ids = submission.requests.map(&:id)
      request_ids.each do |r|
        request = Request.find(r)
        request.request_metadata.bait_library = bait_lib unless request.request_type_id != submission.order
        request.request_metadata.save!
      end
    end
    raise "Testing" unless mode == "run"
  end
end
