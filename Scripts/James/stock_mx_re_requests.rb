# Create a Multiplexed Library Tube from a stock mx tube
# where a Library has already been created

class StockRepooler

  VERSION = 'v1.0.0'

  class PooledWellsError < StandardError; end
  class WellCountError   < StandardError; end

  attr_reader :stock_tube, :user

  def initialize(stock_tube,user_login)
    @stock_tube = stock_tube
    @user = User.find_by_login!(user_login)
  end

  def target_purpose
    @target_purpose ||= @stock_tube.purpose.child_purposes.first
  end

  def target_name
    @target_name ||= "#{stock_tube.name} repeat"
  end

  def repool!
    ActiveRecord::Base.transaction do
      target = target_purpose.create!(:name=>target_name, :qc_state=>"pending")
      transfer = Transfer::BetweenSpecificTubes.create!(:source=>stock_tube,:destination=>target,:user=>user)
      target.parents << stock_tube.parents
      puts "Created! #{target.name}, #{target.id}, #{target.ean13_barcode}, #{target.sanger_human_barcode}"
      target.comments.create!(:title=>'Partial Re-request',:description=>"Created by stock_mx_requests.rb #{VERSION}",:user=>user)
    end
  end
end

#eg.
#StockRepooler.new(Asset.find_by_barcode(barcode),'login').repool!

