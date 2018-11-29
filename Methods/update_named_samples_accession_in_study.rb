require 'builder'

class ::Sample
  def accession_service=(as); @acession_service = as; end
  def accession_service; @acession_service; end
end

def update_sample(sample_name)
  if sample_name.class == String
    sample = Sample.find_by(name: sample_name)
  else
    sample = Sample.find_by(id: sample_name)
  end
  # sample.sample_metadata.sample_taxon_id = 1313 #if sample.sample_metadata.sample_taxon_id.nil?
  # sample.sample_metadata.sample_common_name =  'Streptococcus pneumonia' #if sample.sample_metadata.sample_common_name.nil?
  sample.sample_metadata.gender = 'unknown' if sample.sample_metadata.gender.nil?
  # sample.sample_metadata.donor_id = sample.name
  sample.sample_metadata.phenotype = 'Not provided' if sample.sample_metadata.phenotype.nil?
  # if sample.sample_metadata.sample_ebi_accession_number != nil && sample.sample_metadata.sample_ebi_accession_number.match(/EGA/)
  #   sample.sample_metadata.sample_ebi_accession_number = nil
  # end
  return sample
end

def update_sample_accession_by_sample(sample_names,study_id,login)
  user = User.find_by_login(login)
  study = Study.find(study_id)
  puts "#{study.id}"
  if study.study_metadata.study_ebi_accession_number.nil?
    raise "study #{study.id} requires accessioning"
  elsif study.study_metadata.study_ebi_accession_number.match(/EGA/).nil? == false && study.study_metadata.data_release_strategy == 'open'
    puts "Stopping!\nStudy is set to open yet has an EGA accession #{study.study_metadata.study_ebi_accession_number}: This will result in samples being given ENA accessions"
  else
    sample_errors = []
    duds = []
    c = sample_names.size
    sample_names.each do |sample_name|     
      sample = update_sample(sample_name)
      x = nil
      a = []
      begin
        sample.validate_ena_required_fields!
      rescue ActiveRecord::RecordInvalid => invalid
        x = invalid.record.errors
        # puts "#{x.inspect}"
        if invalid.record.errors[:base].uniq.first == "Study metadata study study title can't be blank on study"
          x = nil
        elsif invalid.record.errors[:base].uniq.first == "Study metadata data access group can't be blank on study"
          x = nil
        else
          a << "#{sample.id}, #{sample.name}, #{sample.sample_metadata.sample_ebi_accession_number}, #{invalid.record.errors[:base].uniq.join(', ')}"
          puts "#{a}"
          sample_errors << a
        end
      end


      if x.nil?
        puts "#{c} *** #{sample.name} ***"
        begin
          sample.accession_service = study.accession_service
          study.accession_service.submit(
          user,
          Accessionable::Sample.new(sample)
          )
        rescue AccessionService::AccessionServiceError => invalid
          message = "#{sample.id}, #{sample.name}, #{sample.sample_metadata.sample_common_name} "+ invalid.message
          duds << message
          puts message
        end
        sample.save!
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


# update_sample_accession_by_sample(sample_names,study_id,login)
