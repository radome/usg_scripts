require 'builder'

class ::Sample
  def accession_service=(as); @acession_service = as; end
  def accession_service; @acession_service; end
end

# make any sample metadata changes here
def update_sample(sample)
  # sample.sample_metadata.sample_taxon_id = 9606 if sample.sample_metadata.sample_taxon_id.nil?
#   sample.sample_metadata.sample_common_name = 'Homo sapien' if sample.sample_metadata.sample_common_name.nil?
  # sample.sample_metadata.gender = 'unknown' if sample.sample_metadata.gender.nil?
  # sample.sample_metadata.gender = 'unknown' if sample.sample_metadata.gender == 'Not Applicable'
#   sample.sample_metadata.donor_id = sample.name if sample.sample_metadata.donor_id.nil?
  # if sample.sample_metadata.phenotype.nil? #|| sample.sample_metadata.phenotype == 'N/A'
    # sample.sample_metadata.phenotype = 'Not provided'
  # end
  # sample.sample_metadata.sample_ebi_accession_number = nil
  # if sample.ebi_accession_number != nil && sample.ebi_accession_number.match(/ERS/)
  #   sample.sample_metadata.sample_ebi_accession_number = nil
  # end
  return sample
end

def update_sample_accession_by_study(study_ids,login)
  user = User.find_by_login(login)
  Study.find(study_ids).each do |study|
    puts "#{study.id}"
    if study.study_metadata.study_ebi_accession_number.match(/EGA/).nil? == false && study.study_metadata.data_release_strategy == 'open'
      puts "Stopping!\nStudy is set to open yet has an EGA accession #{study.study_metadata.study_ebi_accession_number}: This will result in samples being given ENA accessions"
    else
      duds = []
      sample_errors = []
      c = study.samples.size
      study.samples.find_each do |sample|
        sample = update_sample(sample)
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
      
        if x.nil? # and sample.sample_metadata.sample_ebi_accession_number.nil?
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
      end
    end; nil
  
    sample_errors = sample_errors.flatten; nil
    puts "#{study.name}"
  
    unless sample_errors.empty?
      puts "Sample validation errors #{sample_errors.size}"
      sample_errors.each do |sample_error|
        puts "#{sample_error.inspect}"
      end; nil
    end
  
    unless duds.empty?
      puts "Errors from EBI: #{duds.size}"
      duds.each {|d| puts "#{d.inspect}\n"}
    end; nil    
  end; nil
end

# ActiveRecord::Base.logger.level = 3
# update_sample_accession_by_study(study_ids,login)
 