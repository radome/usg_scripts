class ::Sample
  def accession_service=(as); @acession_service = as; end
  def accession_service; @acession_service; end
end

def update_sample(name)
  ActiveRecord::Base.transaction do
    sample = Sample.find_by_name(name)
    sample = Sample.find_by_id(name) if sample == nil
    # sample.sample_metadata.update_attributes!(:sample_taxon_id => 9606, :sample_common_name => 'Homo Sapien')
    # sample.sample_metadata.update_attributes!(:phenotype => 'Not applicable')
    return sample
  end
end

def update_sample_accession_by_study(sample_names,study_id,login)
  user = User.find_by_login(login)
  study = Study.find(study_id)
  puts "#{study.name}"
  if study.study_metadata.study_ebi_accession_number.match(/EGA/).nil? == false && study.study_metadata.data_release_strategy == 'open'
    puts "Stopping!\nStudy is set to open yet has an EGA accession #{study.study_metadata.study_ebi_accession_number}: This will result in samples being given ENA accessions"
  else
    sample_errors = []
    duds = []
    c = sample_names.size
    # taxon_id = 1070528
    sample_names.each do |name|
      sample = update_sample(name)
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
      
      if x.nil? # and sample.sample_metadata.sample_ebi_accession_number.nil?
        puts "#{c} *** #{sample.name} ***"
        begin
          sample.accession_service = study.accession_service
          study.accession_service.submit(
          user,
          Accessionable::Sample.new(sample)
          )
        rescue AccessionService::AccessionServiceError => invalid
          duds << invalid.message
          puts invalid.message        
        end
      else
        puts "#{c} Ignoring #{sample.name} <<<<<<<<<<<<<<<<<<"
      end
      c -=1
    end; nil
    sample_errors = sample_errors.flatten; nil
    puts "#{study.name}"

    unless sample_errors.nil?
      puts "Sample validation errors #{sample_errors.size}"
      sample_errors.each do |sample_error|
        puts "#{sample_error.inspect}"
      end; nil
    end
    
    unless duds.nil?
      puts "Errors from EBI: #{duds.size}"
      duds.each {|d| puts "#{d.inspect}\n"}
    end; nil
    
  end
end

# update_sample_accession_by_study(sample_names,study_id,login)
