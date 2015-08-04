# Create a Multiplexed Library Tube from a stock mx tube
# where a Library has already been created

class StockRepooler

  VERSION = 'v1.1.0'
  
  # VERSION 1.0.0: Initial release
  # VERSION 1.1.0: Add support for multiple parent stock tubes

  class PooledWellsError < StandardError; end
  class WellCountError   < StandardError; end

  attr_reader :stock_tubes, :user

  def initialize(stock_tubes,user_login)
    @stock_tubes = stock_tubes
    @user = User.find_by_login!(user_login)
  end

  def target_purpose
    @target_purpose ||= @stock_tubes.first.purpose.child_purposes.first
  end
  
  def stock_wells
    @sw ||= stock_tubes.map(&:stock_wells).flatten.sort_by {|well| well.map.column_order }
  end
  
  def stock_plate_barcode
    stock_wells.first.plate.sanger_human_barcode
  end
  
  def stock_tube_parents
    stock_tubes.map(&:parents).flatten.uniq
  end

  def target_name
    @target_name ||= "#{stock_plate_barcode} #{stock_wells.first.map_description}:#{stock_wells.last.map_description}R"
  end

  def repool!
    ActiveRecord::Base.transaction do
      target = target_purpose.create!(:name=>target_name, :qc_state=>"pending")
      stock_tubes.each do |stock_tube|
        Transfer::BetweenSpecificTubes.create!(:source=>stock_tube,:destination=>target,:user=>user)
      end
      target.parents << stock_tube_parents
      puts "Created! #{target.name}, #{target.id}, #{target.ean13_barcode}, #{target.sanger_human_barcode}"
      target.comments.create!(:title=>'Partial Re-request',:description=>"Created by stock_mx_requests.rb #{VERSION}",:user=>user)
    end
  end
end

#eg.
#StockRepooler.new([Asset.find_by_barcode(barcode)],'login').repool!

