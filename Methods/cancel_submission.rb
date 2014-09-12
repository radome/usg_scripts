def cancel_submission(submission_ids,mode)
  ActiveRecord::Base.transaction do
    submission_ids.each do |submission_id|
      sub = Submission.find submission_id
      sub.requests.each do |r| 
        status = r.state
        if r.state == "passed"
          # r.cancel_completed!
          r.return!
          puts "#{sub.id} request #{r.id} #{r.sti_type} was #{status} now => #{r.state}"
        elsif r.state == "pending"
          r.cancel_before_started!
          puts "#{sub.id} request #{r.id} #{r.sti_type} was #{status} now => #{r.state}"
        else
          puts "#{sub.id} request #{r.id} #{r.sti_type} was #{status} now => #{r.state}"
        end
        r.update_attributes!(:asset => nil)
      end
    end
    raise "Hell!!" unless mode == "run"
  end; nil
end
