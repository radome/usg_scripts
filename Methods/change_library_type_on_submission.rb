def change_library_type_on_submission_and_assets(submission_ids,library_type,mode)
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
      mx_tubes = submission.requests.select {|r| r.request_type_id == submission.orders.first.request_types[1]}.map(&:asset).uniq
      submission.requests.each do |request|
        puts "#{request.id}: #{request.request_metadata.library_type} => #{library_type}" unless request.request_metadata.library_type.nil?
        request.request_metadata.update_attributes!(:library_type => library_type) unless request.request_metadata.library_type.nil?
      end
      receptacles = []
      mx_tubes.each do |mx|
        puts "mx => #{mx.name}"
        ltreqs = mx.ancestors.select {|lt| lt.class == LibraryTube}
        ltreqs.map(&:requests_as_target).flatten.map(&:request_metadata).map {|rm| rm.update_attributes!(:library_type => library_type)}
        mx.aliquots.each do |aliquot|
          puts "aliquot #{aliquot.id}"
          aliquots = Aliquot.find_all_by_library_id(aliquot.library_id)
          receptacles << aliquots.map(&:receptacle).uniq
          aliquots.each  do |a|
            puts "updating #{a.id}"
            a.update_attributes!(:library_type => library_type)
          end
        end
      end
      receptacles.flatten.uniq.each {|r| r.touch }
    end
    raise "Hell!" unless mode == 'run'
  end
end

change_library_type_on_submission_and_assets(submission_ids,library_type,mode)
