# Create a Multiplexed Library Tube containing given samples
# Provide a template plate from which to source the aliquot info.

class PartialRepooler

  class PooledWellsError < StandardError; end
  class WellCountError   < StandardError; end

  attr_reader :plate, :samples

  def initialize(samples,plate)
    @samples = samples
    @plate = plate

    raise WellCountError, "#{source_wells.count} samples found, #{samples.count} expected" unless source_wells.count == samples.count

    puts "Selected:"
    source_wells.each do |well|
      a = well.aliquots.first
      puts "- Sample: #{a.sample.name}, Tag: #{a.tag_id}, Well: #{well.map_description}, Library: #{a.library_id}, Study: #{a.study_id}, Project: #{a.project_id}"
    end
    puts "Will create:"
    puts "-#{target_purpose.name}: #{target_name}"

  end

  def source_wells
    @source_wells ||= plate.wells.select do |well|
      raise PooledWellsError, "Wells have multiple aliquots" if well.aliquots.count > 1
      next if well.aliquots.empty?
      samples.include?(well.aliquots.first.sample.name)
    end
  end

  def target_purpose
    @target_purpose ||= @plate.stock_plate.wells.first.requests.first.target_asset.purpose
  end

  def target_name
    return @target_name unless @target_name.nil?
    wells = source_wells.count != 1 ? "#{source_wells.first.map_description}...#{source_wells.last.map_description}" : source_wells.first.map_description
    @target_name = "#{@plate.stock_plate.sanger_human_barcode} #{wells} rearray"
  end

  def repool!
    ActiveRecord::Base.transaction do
      target = target_purpose.create!(:name=>target_name, :qc_state=>"pending")
      target.aliquots = source_wells.map {|w| AssetLink.create!(:descendant=>target,:ancestor=>w,:direct=>true); w.aliquots.first.clone }
      puts "Created! #{target.name}, #{target.id}, #{target.ean13_barcode}, #{target.sanger_human_barcode}"
    end
  end
end
pr = PartialRepooler.new(['SC_MUSPA5478803'],Plate.find(7098730))
pr2 =  PartialRepooler.new(['SC_MUSPA5478815','SC_MUSPA5478802','SC_MUSPA5481780','SC_MUSPA5478813','SC_MUSPA5478809','SC_MUSPA5481783'],Plate.find(7098730))
