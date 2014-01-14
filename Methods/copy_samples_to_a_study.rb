# Sample names
def add_to_study(samples,study_name,mode)
  ActiveRecord::Base.transaction do
    study = Study.find_by_name(study_name)
    already = []
    samples.each do |name|
      sample = Sample.find_by_name(name) or raise "Can't find sample #{name}"
      if sample.studies.include?(study)
        already << sample
        puts "#{name} already in study"
      else
        study.samples << sample
      end
    end
    puts "#{already.count} samples out of #{samples.count} already linked to #{study_name}"
    raise "Hell!!!" unless mode == "run"
  end; nil
end

# Sample ids
def add_to_study(sample_ids,study_name,mode)
  ActiveRecord::Base.transaction do
    study = Study.find_by_name(study_name)
    already = []
    sample_ids.each do |sample_id|
      sample = Sample.find_by_id(sample_id) or raise "Can't find sample #{sample_id}"
      if sample.studies.include?(study)
        already << sample
        puts "#{name} already in study"
      else
        study.samples << sample
      end
      study.samples << sample
    end
    raise "Hell!!!" unless mode == "run"
  end
end

# Sample ids and Study ids
def add_to_study(sample_ids,study_id,mode)
  ActiveRecord::Base.transaction do
    study = Study.find(study_id)
    already = []
    sample_ids.each do |sample_id|
      sample = Sample.find_by_id(sample_id) or raise "Can't find sample #{sample_id}"
      if sample.studies.include?(study)
        already << sample
        puts "#{name} already in study"
      else
        study.samples << sample
      end
      study.samples << sample
    end
    raise "Hell!!!" unless mode == "run"
  end
end