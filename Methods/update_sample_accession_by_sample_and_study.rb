def update_sample_accession_by_sample_and_study(sample_names,study_id,login)
  study = Study.find_by_id study_id
  user = User.find_by_login(login)
  duds = []
  sample_errors = []
  c = sample_names.size
  sample_names.each do |name|
    sample = Sample.find_by_name(name)
    # Add missing metadata here
    # sample.sample_metadata.update_attributes!(:gender => 'Not applicable', :genotype => nil, :donor_id => sample.name)
    x = nil
    a = []
    begin
      sample.validate_ena_required_fields!
    rescue ActiveRecord::RecordInvalid => invalid
      x = invalid.record.errors
      a << "#{sample.id}, #{sample.name}, #{sample.sample_metadata.sample_ebi_accession_number}, #{invalid.record.errors[:base].uniq.join(', ')}"
      puts "XXX #{a}"
    end
    sample_errors << a
    if sample.nil?
      puts "unable to find sample #{name}"
      duds << name
    elsif x.nil? # and sample.sample_metadata.sample_ebi_accession_number.nil?
      puts "#{c} *** #{sample.name} ***"
      study.accession_service.submit(
      user,
      Accessionable::Sample.new(sample)
      )
    else
      puts "#{c} Ignoring #{name} <<<<<<<<<<<<<<<<<<"
    end
    c -=1
  end; nil
  sample_errors = sample_errors.flatten; nil
  puts "Sample errors #{sample_errors.size}"
  
  sample_errors.each do |sample_error|
    puts "#{sample_error.inspect}"
  end
  puts "Duds>>>\n #{duds.inspect}"
end

update_sample_accession_by_sample_and_study(sample_names,study_id,login)
