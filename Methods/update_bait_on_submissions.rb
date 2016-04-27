def update_bait_on_submissions(sub_ids,old_bait_name,new_bait_name,mode)
  ActiveRecord::Base.transaction do
    new_bait = BaitLibrary.find_by_name(new_bait_name)
    old_bait = BaitLibrary.find_by_name(old_bait_name)
    sub_ids.each do |sub_id|
      puts "Processing #{sub_id}"
      sub = Submission.find_by_id(sub_id)
      sub.orders.map {|o| o.request_options[:bait_library_name] = new_bait.name; o.save!}
      reqs = sub.requests.select {|r| r.request_metadata.bait_library_id == old_bait.id}; nil
      reqs.map {|r| r.request_metadata.update_attributes!(:bait_library_id => new_bait.id)}
    end
    raise "Hell!!!!" unless mode == 'run'
  end
end
