# NO TEST MODE AVAILABLE!!
def update_sample_accession_by_study(samples,study,login)
  ActiveRecord::Base.transaction do
    samples.each do |sample|
      puts "*** #{sample} ***"
      Study.find_by_name(study).accession_service.submit(
      User.find_by_login(login),
      Accessionable::Sample.new(Sample.find_by_name(sample))
      )
    end
  end
end
