def change_project_on_submission(project_id,submission_ids,rt_ticket,login,mode)
  ActiveRecord::Base.transaction do
    user = User.find_by_login(login) or raise StandardError, "Cannot find the user #{user_login.inspect}"
    # types = ["Pulldown::Requests::WgsLibraryRequest", "HiSeqSequencingRequest"]
    types = ["Pulldown::Requests::IscLibraryRequest", "HiSeqSequencingRequest"]
    submission_ids.each do |submission_id|
      comment_text = "Project changed for submission #{submission_id} via RT ticket #{rt_ticket}"
      comment_on = lambda { |x| x.comments.create!(:description => comment_text, :user_id => user.id, :title => "Project change #{rt_ticket}") }
      puts "Finding submission #{submission_id} and updating orders"
      submission = Submission.find(submission_id)
      submission.orders.each {|o| o.project_id = project_id; o.save(validate:false)}
      puts "Finding library and sequencing requests"
      lib_requests = submission.requests.select {|r| r.class.name == RequestType.find(submission.order.request_types[0]).request_class_name}
      seq_requests = submission.requests.select {|r| r.class.name == RequestType.find(submission.order.request_types[1]).request_class_name}      
      puts "Updating seq requests..." 
      seq_requests.each {|sr| sr.update_attributes!(:initial_project_id => project_id)}
      seq_requests.map(&comment_on)
      mx_tube = lib_requests.map(&:target_asset).first
      if mx_tube !=nil
        puts "Updating mx aliquots"
        mx_tube.aliquots.each {|a| a.update_attributes!(:project_id => project_id)}      
        mx_tube.requests_as_source.map(&:target_asset).each do |lane|
          if lane.nil?
            puts "No lanes found"
          else
            puts "... and lane aliquots"
            puts "MX #{mx_tube.ean13_barcode} => Lane #{lane.id}"
            lane.aliquots.clear; lane.aliquots = mx_tube.aliquots.map(&:dup); lane.save!
          end
        end
      end
    
      puts "Updating the lib requests"
      lib_requests.each do |request|
        request.initial_project_id = project_id
        request.save!
      end
      lib_requests.map(&comment_on)
      
      # if mode == 'run'
      #   puts "Broadcasting project updates to the warehouse.."
      #   AmqpObserver.instance << submission
      #   puts "..Done"
      # end
    end
    raise "Running in test mode" unless mode == 'run'
  end
end
