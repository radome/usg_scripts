def update_bait_name_and_rebuild_failed_submissions(sub_ids,bait_name,mode)
  ActiveRecord::Base.transaction do
    sub_ids.each do |sub_id|
      puts "Processing #{sub_id}"
      sub = Submission.find(sub_id)
      sub.message = nil
      sub.state = 'ready'
      sub.save!
      sub.orders.map {|o| o.request_options[:bait_library_name] = bait_name; o.save!}
      sub.process_submission!
    end
    raise "Hell!!!!" unless mode == 'run'
  end
end
