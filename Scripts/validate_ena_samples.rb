sample_ids =[]
samples.each do |sample_name|
  sample = Sample.find_by_name(sample_name)
  begin
    sample.validate_ena_required_fields!
    puts "#{sample.id},#{sample.name}"
  rescue ActiveRecord::RecordInvalid => invalid
    puts "#{sample.id},#{sample.name},#{invalid}"
    sample_ids << sample.id
  end
end; nil
