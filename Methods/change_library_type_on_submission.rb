def change_library_type_on_submission(submission_ids,library_type,mode)
  ActiveRecord::Base.transaction do
    submission_ids.each do |submission_id|
      submission = Submission.find submission_id
      submission.orders.each do |order|
        order.request_options.each do |key,value|
          if key == "library_type"
            puts "#{key} ===> #{value}\n"
            order.request_options[key] = library_type
            puts "#{order.request_options[key].inspect}"
            order.save!
          else
            puts "--"
          end
        end
      end
      submission.requests.each do |request|
        request.request_metadata.update_attributes!(:library_type => library_type) unless request.request_metadata.request_type.nil?
      end
    end
    raise "Hell!" unless mode == 'run'
  end
end
