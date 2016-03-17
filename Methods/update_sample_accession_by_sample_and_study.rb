class ::Sample
  def accession_service=(as); @acession_service = as; end
  def accession_service; @acession_service; end
end

class Accessionable::Submission
 def alias
   "#{@accessionables.map(&:alias).join(" - ")}-#{DateTime.now}"
 end
end

def update_sample_accession_by_study(sample_names,study_id,login)

  user = User.find_by_login(login)
  study = Study.find(study_id)
  puts "#{study.name}"
  sample_errors = []
  c = sample_names.size
  sample_names.each do |name|
    ActiveRecord::Base.transaction do
      sample = Sample.find_by_name(name)
      sample = Sample.find_by_id(name) if sample == nil
      x = nil
      a = []
      begin
        sample.validate_ena_required_fields!
      rescue ActiveRecord::RecordInvalid => invalid
        x = invalid.record.errors
        a << "#{sample.id}, #{sample.name}, #{sample.sample_metadata.sample_ebi_accession_number}, #{invalid.record.errors[:base].uniq.join(', ')}"
        puts "#{a}"
      end
      sample_errors << a
      if x.nil?
        puts "#{c} *** #{sample.name} ***"
        begin
          sample.accession_service = study.accession_service
          study.accession_service.submit(
          user,
          Accessionable::Sample.new(sample)
          )
        rescue AccessionService::AccessionServiceError => invalid
          puts invalid.message
        end
      else
        puts "#{c} Ignoring #{sample.name} <<<<<<<<<<<<<<<<<<"
      end
    end
    c -=1
  end; nil
  sample_errors = sample_errors.flatten; nil
  puts "#{study.name}"
  puts "Sample errors #{sample_errors.size}"

  sample_errors.each do |sample_error|
    puts "#{sample_error.inspect}\n"
  end; nil
end
