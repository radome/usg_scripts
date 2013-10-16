def walk_down_plates_and_update_aliquots(plate,study_id,project_id)
  until plate.class == Well
    puts "#{plate.purpose.name} - #{plate.ean13_barcode} - #{plate.uuid}"
    plate.wells.map(&:aliquots).flatten.each {|a| a.update_attributes!(:study_id => study_id, :project_id => project_id)}
    puts "study id => #{plate.wells.map(&:aliquots).flatten.map(&:study_id).inspect}"
    plate = plate.child
  end
end

def change_study_and_project_on_submission(study_id,project_id,submission_ids,mode)
  ActiveRecord::Base.transaction do
    study = Study.find(study_id)
    types = ["Pulldown::Requests::WgsLibraryRequest", "HiSeqSequencingRequest"]
    submission_ids.each do |submission_id|
      puts "Finding submission #{submission_id} and updating orders"
      submission = Submission.find(submission_id)
      submission.orders.each {|o| o.study_id = study_id; o.project_id = project_id; o.save(false)}
    
      puts "Finding HiSeq requests and updating"
      seq_requests = submission.requests.select {|r| r.sti_type == types[1]}
      seq_requests.each {|s| s.write_attribute(:study_id, study_id)}
    
      puts "Finding WGS-lib requests and updating mx and lane aliquots"
      lib_requests = submission.requests.select {|r| r.sti_type == types[0]}
      mx_tube = lib_requests.map(&:target_asset).first
      mx_tube.aliquots.each {|a| a.update_attributes!(:study_id => study_id, :project_id => project_id)}
      lane = mx_tube.child
    
      puts "MX #{mx_tube.ean13_barcode} => Lane #{lane.id}"
      lane.aliquots.clear; lane.aliquots = mx_tube.aliquots.map(&:clone); lane.save!
    
      puts ".... and the requests ..."
      lib_requests.each do |request|
        request.write_attribute(:initial_study_id, study_id)
        request.initial_project_id = project_id
        request.save!
      end
    
      puts "Finding associated plates and updating aliquots.."
      walk_down_plates_and_update_aliquots(lib_requests.first.asset.plate,study_id,project_id)
    end
  
    puts "Broadcasting study and project updates to the warehouse.."
    AmqpObserver.instance << study
    puts "..Done"
    raise "Running in test mode" unless mode == 'run'
  end
end
