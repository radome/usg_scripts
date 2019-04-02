def change_sample_consent(sample_names)
  ActiveRecord::Base.transaction do
    sample_names.each do |sample_name|
      sample = Sample.find_by(name: sample_name)
      puts "Unable to find sample with name #{sample_name}" if sample.nil?
      sample.update_attributes!(:consent_withdrawn => true)
      puts "#{sample_name} => #{sample.consent_withdrawn}"
    end
  end
end
